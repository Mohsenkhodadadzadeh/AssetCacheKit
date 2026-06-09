//
//  AssetCache.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/25/26.
//

import Foundation

/// A thread-safe, two-layer cache for raw asset data of any type.
///
/// `AssetCache` is the central data store shared by every loader in the framework —
/// images, PDFs, SVGs — and is designed to accommodate any asset type added in
/// the future (video, audio, JSON, etc.).  It stores raw **compressed bytes**
/// rather than decoded objects, keeping the memory footprint small and the
/// implementation fully generic.
///
/// ## Global configuration
///
/// Call ``configure(_:)`` **once** at app startup, before any loader is used,
/// to customise the shared cache — including the storage directory:
///
/// ```swift
/// // AppDelegate.application(_:didFinishLaunchingWithOptions:)
/// // — or — the @main App.init()
/// AssetCache.configure(
///     AssetCacheConfiguration(storageDirectory: .document)
/// )
/// ```
///
/// After that single call, every `CachedImageLoader`, `CachedPDFLoader`, and
/// `CachedSVGLoader` automatically uses the Documents directory without any
/// per-request configuration.
///
/// If ``configure(_:)`` is never called, ``AssetCache/shared`` falls back to
/// ``AssetCacheConfiguration/default``, which targets the Caches directory —
/// preserving full backward compatibility.
///
/// ## Cache layers
///
/// Requests are served from the fastest available source:
///
/// 1. **Memory** — `NSCache<NSURL, NSData>` holding compressed asset bytes.
///    Entries are evicted automatically by the OS under memory pressure.
/// 2. **Disk** — ``DiskCache`` providing persistent storage with explicit
///    expiration and LRU eviction.
/// 3. **Network** — ``NetworkFetcher`` downloads the asset with retry logic.
///    Raw data is written to disk before being returned to the caller.
///
/// ## Request deduplication
///
/// When multiple callers request the same URL concurrently, only a single
/// network request is made.  All callers await the same `Task` and receive the
/// result once it resolves.
///
/// ## Type-specific decoding
///
/// Decoding (e.g. JPEG → `UIImage`, bytes → `PDFDocument`) is deliberately
/// left to each ``AssetLoader`` conformance.  This keeps `AssetCache` generic
/// and avoids coupling it to any specific asset type.
///
/// - Note: For images, ``CachedImageLoader`` supplements `AssetCache` with a
///   ``DecodedImageCache`` that stores already-decoded ``PlatformImage`` objects,
///   eliminating repeated decompression on every display cycle.
actor AssetCache {

    // MARK: - Singleton & Global Configuration

    /// The shared `AssetCache` instance used by all built-in loaders.
    ///
    /// Always access the shared instance *after* calling ``configure(_:)``
    /// during app startup.  The instance is created lazily on first access,
    /// so configuration applied before first use is guaranteed to take effect.
    static let shared: AssetCache = {
        AssetCache(configuration: _pendingConfiguration ?? .default)
    }()

    /// Backing store for the configuration set by ``configure(_:)``.
    ///
    /// `nonisolated(unsafe)` is intentional: this value is written exactly once
    /// on the main thread during app startup (before any concurrent access),
    /// and read exactly once inside the `shared` lazy initialiser, also before
    /// any concurrent access.  The write-before-read ordering is guaranteed by
    /// the requirement that ``configure(_:)`` be called before the first asset
    /// load.  No locking is needed for a single-writer, single-reader pattern
    /// with this ordering guarantee.
    private nonisolated(unsafe) static var _pendingConfiguration: AssetCacheConfiguration?

    /// Configures the shared ``AssetCache`` instance.
    ///
    /// Call this **once**, before any loader is used — typically in
    /// `AppDelegate.application(_:didFinishLaunchingWithOptions:)` or your
    /// SwiftUI `App.init()`.
    ///
    /// ```swift
    /// AssetCache.configure(
    ///     AssetCacheConfiguration(storageDirectory: .document)
    /// )
    /// ```
    ///
    /// Calling this method after ``shared`` has already been accessed has no
    /// effect; the shared instance retains its original configuration.
    ///
    /// - Parameter configuration: The configuration to apply to the shared cache.
    static func configure(_ configuration: AssetCacheConfiguration) {
        // Only honoured if `shared` has not been accessed yet.
        guard _pendingConfiguration == nil else { return }
        _pendingConfiguration = configuration
    }

    // MARK: - Private State

    /// Compressed asset bytes kept in memory for zero-latency cache hits.
    private let memory: NSCache<NSURL, NSData>

    /// Persistent file-system store with expiration and LRU eviction.
    private let disk: DiskCache

    private let config: AssetCacheConfiguration

    /// In-flight download tasks keyed by URL.
    ///
    /// Any new request for a URL that already has an entry here attaches to
    /// the existing task instead of starting a duplicate network request.
    private var inFlight: [URL: Task<Data, Error>] = [:]

    // MARK: - Init

    /// Creates an `AssetCache` with the given configuration.
    ///
    /// - Parameter configuration: Tuning parameters for memory limits, disk
    ///   quota, expiration, retry behaviour, and storage directory.
    ///   Defaults to ``AssetCacheConfiguration/default``.
    init(configuration: AssetCacheConfiguration = .default) {
        config = configuration
        disk   = DiskCache(
            namespace: "com.assetcachekit.assets",
            storageDirectory: configuration.storageDirectory,
            byteLimit: configuration.diskByteLimit,
            defaultExpiration: configuration.defaultExpiration
        )
        memory               = NSCache()
        memory.totalCostLimit = configuration.rawDataMemoryByteLimit
    }

    // MARK: - Fetch

    /// Returns raw asset data for `url`, checking memory → disk → network.
    ///
    /// Concurrent requests for the same URL share a single in-flight `Task`,
    /// so the network is queried at most once per URL regardless of how many
    /// callers are waiting.
    ///
    /// - Parameter url: The remote location of the asset.
    /// - Returns: The raw (compressed) asset bytes.
    /// - Throws: ``AppError/assetLoading(_:)`` or ``AppError/network(_:)`` on failure.
    func data(for url: URL) async throws -> Data {

        // ① Memory hit
        if let cached = memory.object(forKey: url as NSURL) {
            return cached as Data
        }

        // ② Deduplicate — attach to an existing task if one is already loading this URL
        if let existing = inFlight[url] {
            return try await existing.value
        }

        // ③ Start a new task and register it for deduplication
        let task = Task<Data, Error> { try await load(url: url) }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        return try await task.value
    }

    // MARK: - Prefetch

    /// Warms the cache for a list of URLs in the background.
    ///
    /// Each URL is fetched with the same logic as ``data(for:)``.
    /// Errors are silently discarded so a failing prefetch never surfaces to the UI.
    ///
    /// - Parameter urls: The remote locations to prefetch.
    func prefetch(urls: [URL]) {
        for url in urls {
            Task { _ = try? await data(for: url) }
        }
    }

    // MARK: - Eviction

    /// Removes all entries from the memory layer.
    ///
    /// Disk entries are unaffected; subsequent requests are served from disk
    /// rather than the network.
    func clearMemory() {
        memory.removeAllObjects()
    }

    /// Removes all entries from both the memory and disk layers.
    func clearAll() async {
        memory.removeAllObjects()
        await disk.clearAll()
    }

    // MARK: - Private

    private func load(url: URL) async throws -> Data {
        // Disk hit — skip the network entirely
        let key = diskKey(for: url)
        if let cached = await disk.data(for: key) {
            storeInMemory(cached, for: url)
            return cached
        }

        // Network fetch with retry.
        // Raw data is written to disk before being returned so that a caller
        // crash or cancellation after this point does not discard the download.
        let data = try await NetworkFetcher.fetch(url: url, policy: config.retryPolicy)
        await disk.store(data: data, for: key)
        storeInMemory(data, for: url)
        return data
    }

    internal func storeInMemory(_ data: Data, for url: URL) {
        memory.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
    }

    /// Derives a filesystem-safe disk key from a URL.
    private func diskKey(for url: URL) -> String {
        let allowedChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "."))
        return url.absoluteString.suffix(70)
            .addingPercentEncoding(withAllowedCharacters: allowedChars) ?? url.absoluteString
    }
}
