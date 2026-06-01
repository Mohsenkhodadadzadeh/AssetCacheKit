//
//  DiskCache.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/25/26.
//

import Foundation

/// A persistent, file-system-backed cache with per-entry expiration and LRU eviction.
///
/// `DiskCache` stores arbitrary asset data (images, PDFs, SVGs, audio, video, etc.)
/// as pairs of files inside a private subdirectory of the system caches folder:
///
/// - `<id>.cache` — the raw bytes of the asset.
/// - `<id>.meta`  — a JSON-encoded ``DiskCacheMetadata`` file containing creation
///   date, expiration date, and file size.
///
/// ## Expiration
///
/// Every entry carries an `expiresAt` date written at store time.  On the next read
/// after that date, the entry is treated as a miss: both companion files are deleted
/// and `nil` is returned.
///
/// ## LRU eviction
///
/// When the total size of `.cache` files exceeds the configured ``byteLimit``,
/// `DiskCache` removes the least-recently-accessed entries until the cache fits
/// within the limit.  Access time is tracked by updating the `.cache` file's
/// modification date on every successful read.
///
/// ## Concurrency
///
/// `DiskCache` is an `actor`.  Swift's runtime serialises all method calls,
/// eliminating the need for manual locking.
actor DiskCache {

    // MARK: - Private State

    private let directory: URL
    private let byteLimit: Int
    private let defaultExpiration: TimeInterval

    /// Running total of all `.cache` file sizes, kept in sync with every write and eviction.
    private var currentSize: Int = 0

    // MARK: - Init

    /// Creates a `DiskCache` inside a named subdirectory of the system caches folder.
    ///
    /// - Parameters:
    ///   - namespace: A reverse-DNS string used as the subdirectory name
    ///     (e.g. `"com.assetcachekit.assets"`).  Different namespaces are fully
    ///     independent; they share no state and can have different limits.
    ///   - byteLimit: Maximum total disk usage in bytes before LRU eviction begins.
    ///   - defaultExpiration: Lifetime applied to every entry written through ``store(data:for:)``.
    init(namespace: String, byteLimit: Int, defaultExpiration: TimeInterval) {
        self.byteLimit         = byteLimit
        self.defaultExpiration = defaultExpiration

        let caches = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
        directory = caches.appendingPathComponent(namespace, isDirectory: true)

        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        Task { await recalculateSize() }
    }

    // MARK: - Read

    /// Returns cached data for `key`, or `nil` if the entry is missing or stale.
    ///
    /// On a stale or corrupt entry, both companion files are deleted before returning `nil`.
    /// On a valid hit, the file's modification date is updated to record the current
    /// access time for LRU ordering.
    ///
    /// - Parameter key: A filesystem-safe string identifying the entry.
    /// - Returns: The cached raw bytes, or `nil` on a miss.
    func data(for key: String) -> Data? {
        let (dataURL, metaURL) = fileURLs(for: key)

        guard
            let metaRaw = try? Data(contentsOf: metaURL),
            let meta    = try? JSONDecoder().decode(DiskCacheMetadata.self, from: metaRaw),
            Date() < meta.expiresAt,
            let data    = try? Data(contentsOf: dataURL)
        else {
            remove(key: key)
            return nil
        }

        touchAccessDate(at: dataURL)
        return data
    }

    // MARK: - Write

    /// Persists `data` to disk under `key` using the default expiration.
    ///
    /// Both the `.cache` and `.meta` files are written atomically.  LRU eviction
    /// runs synchronously after the write if the cache has exceeded ``byteLimit``.
    ///
    /// - Parameters:
    ///   - data: The raw asset bytes to store.
    ///   - key: A filesystem-safe string identifying the entry.
    func store(data: Data, for key: String) {
        let (dataURL, metaURL) = fileURLs(for: key)

        let meta = DiskCacheMetadata(
            key: key,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(defaultExpiration),
            fileSize: data.count
        )

        guard let metaRaw = try? JSONEncoder().encode(meta) else { return }

        try? data.write(to: dataURL, options: .atomic)
        try? metaRaw.write(to: metaURL, options: .atomic)

        currentSize += data.count
        evictIfNeeded()
    }

    // MARK: - Clear

    /// Removes all files from the cache directory and resets the size counter.
    func clearAll() {
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        currentSize = 0
    }

    // MARK: - LRU Eviction

    /// Removes the least-recently-accessed `.cache` files until
    /// `currentSize` falls at or below ``byteLimit``.
    private func evictIfNeeded() {
        guard currentSize > byteLimit else { return }

        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        ) else { return }

        let candidates: [(url: URL, date: Date, size: Int)] = contents
            .filter { $0.pathExtension == "cache" }
            .compactMap { url in
                let values = try? url.resourceValues(
                    forKeys: [.contentModificationDateKey, .fileSizeKey]
                )
                guard let date = values?.contentModificationDate,
                      let size = values?.fileSize else { return nil }
                return (url, date, size)
            }
            .sorted { $0.date < $1.date }   // Oldest access first → LRU

        for candidate in candidates {
            guard currentSize > byteLimit else { break }
            try? fm.removeItem(at: candidate.url)
            let metaURL = candidate.url
                .deletingPathExtension()
                .appendingPathExtension("meta")
            try? fm.removeItem(at: metaURL)
            currentSize = max(0, currentSize - candidate.size)
        }
    }

    // MARK: - Helpers

    private func remove(key: String) {
        let (dataURL, metaURL) = fileURLs(for: key)
        try? FileManager.default.removeItem(at: dataURL)
        try? FileManager.default.removeItem(at: metaURL)
    }

    /// Scans the cache directory on start-up to restore an accurate size counter.
    ///
    /// This is necessary because the process may have been killed before a previous
    /// session's in-memory counter was persisted.
    private func recalculateSize() {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return }

        currentSize = contents
            .compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }
            .reduce(0, +)
    }

    /// Sets the modification date of `url` to the current time.
    ///
    /// This records the most-recent access time, which `evictIfNeeded()` uses to
    /// determine LRU order.  `contentAccessDateKey` is not reliably writable on all
    /// Apple platforms, so the modification date is used as a proxy.
    private func touchAccessDate(at url: URL) {
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: url.path
        )
    }

    private func fileURLs(for key: String) -> (data: URL, meta: URL) {
        let base = directory.appendingPathComponent(key)
        return (
            base.appendingPathExtension("cache"),
            base.appendingPathExtension("meta")
        )
    }
}
