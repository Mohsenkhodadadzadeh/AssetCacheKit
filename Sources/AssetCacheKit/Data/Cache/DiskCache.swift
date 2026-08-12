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
/// as pairs of files inside a private subdirectory of the configured system directory:
///
/// - `<id>.cache` — the raw bytes of the asset.
/// - `<id>.meta`  — a JSON-encoded ``DiskCacheMetadata`` file containing creation
///   date, expiration date, and file size.
///
/// The root directory is determined by the ``StorageDirectory`` passed at
/// initialisation time — either `.cachesDirectory` (the default) or
/// `.documentDirectory`.  This value is set once by ``AssetCache`` and never
/// changes for the lifetime of the cache.
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
    ///
    /// Only ever read through ``size()``, which performs the one-time
    /// directory scan on first use.
    private var currentSize: Int = 0

    /// Whether ``currentSize`` has been seeded from the on-disk contents yet.
    private var didLoadSize = false

    // MARK: - Init

    /// Creates a `DiskCache` inside a named subdirectory of the specified system directory.
    ///
    /// - Parameters:
    ///   - namespace: A reverse-DNS string used as the subdirectory name
    ///     (e.g. `"com.assetcachekit.assets"`).  Different namespaces are fully
    ///     independent; they share no state and can have different limits.
    ///   - storageDirectory: The system directory that should hold the cache folder.
    ///     Defaults to ``StorageDirectory/cache`` (``FileManager/SearchPathDirectory/cachesDirectory``).
    ///   - byteLimit: Maximum total disk usage in bytes before LRU eviction begins.
    ///   - defaultExpiration: Lifetime applied to every entry written through ``store(data:for:)``.
    init(
        namespace: String,
        storageDirectory: StorageDirectory = .cache,
        byteLimit: Int,
        defaultExpiration: TimeInterval
    ) {
        self.byteLimit         = byteLimit
        self.defaultExpiration = defaultExpiration

        // Resolve the base system directory from the StorageDirectory enum value.
        // The search path can legitimately come back empty in sandboxed or
        // command-line contexts, so fall back to the temporary directory rather
        // than trapping on a force-unwrap.
        let base = FileManager.default
            .urls(for: storageDirectory.searchPathDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory
        directory = base.appendingPathComponent(namespace, isDirectory: true)

        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        // `currentSize` is seeded lazily by `size()` on first use.  Kicking off
        // an unawaited `Task` here instead would let the scan land *after* early
        // writes and clobber the byte count they contributed.
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

        // Overwriting an existing key replaces its bytes rather than adding to
        // them, so drop the previous file's contribution before counting the
        // new one — otherwise repeated writes to the same key inflate
        // `currentSize` until eviction wipes the whole cache.
        let previousSize = fileSize(at: dataURL)

        do {
            try data.write(to: dataURL, options: .atomic)
            try metaRaw.write(to: metaURL, options: .atomic)
        } catch {
            // The write failed; leave the byte count untouched.
            return
        }

        currentSize = max(0, size() - previousSize) + data.count
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
        didLoadSize = true
    }

    // MARK: - LRU Eviction

    /// Removes the least-recently-accessed `.cache` files until
    /// `currentSize` falls at or below ``byteLimit``.
    private func evictIfNeeded() {
        guard size() > byteLimit else { return }

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

        // Discount the bytes being dropped, otherwise expired and corrupt
        // entries permanently inflate `currentSize` and eventually push the
        // cache into evicting healthy entries it should have kept.
        let removedSize = fileSize(at: dataURL)

        try? FileManager.default.removeItem(at: dataURL)
        try? FileManager.default.removeItem(at: metaURL)

        currentSize = max(0, size() - removedSize)
    }

    /// Returns the running byte total, scanning the directory once on first use.
    private func size() -> Int {
        if !didLoadSize {
            didLoadSize = true
            recalculateSize()
        }
        return currentSize
    }

    /// Scans the cache directory to restore an accurate size counter.
    ///
    /// This is necessary because the process may have been killed before a previous
    /// session's in-memory counter was persisted.
    ///
    /// Only `.cache` files are counted, matching what ``store(data:for:)`` adds
    /// and what ``evictIfNeeded()`` subtracts.  Counting the `.meta` sidecars
    /// here too would leave a floor of metadata bytes that eviction can never
    /// reclaim, so a cache near its limit would delete every entry it holds and
    /// still believe it was over budget.
    private func recalculateSize() {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            currentSize = 0
            return
        }

        currentSize = contents
            .filter { $0.pathExtension == "cache" }
            .compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }
            .reduce(0, +)
    }

    /// Returns the on-disk size of `url` in bytes, or `0` when it does not exist.
    private func fileSize(at url: URL) -> Int {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
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
