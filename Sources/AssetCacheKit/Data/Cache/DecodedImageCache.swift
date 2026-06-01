//
//  DecodedImageCache.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/25/26.
//
import Foundation

/// An in-memory cache for decoded ``PlatformImage`` objects.
///
/// `DecodedImageCache` is an image-specific complement to ``AssetCache``.
/// While ``AssetCache`` stores compressed raw bytes (suitable for any asset
/// type), `DecodedImageCache` stores images that have already been
/// decompressed and rendered into bitmaps, eliminating the cost of repeated
/// decoding when the same image is displayed multiple times — for example,
/// when a user scrolls back to a cell they already visited.
///
/// ## Why a separate cache?
///
/// Keeping decoded images separate from compressed data allows each limit to
/// be tuned independently:
///
/// - **``AssetCache`` memory** — small (compressed bytes are tiny).
/// - **`DecodedImageCache`** — larger, since a decoded 4K image can be 16 MB
///   or more depending on resolution and scale factor.
///
/// ## LRU eviction
///
/// `NSCache` handles eviction automatically.  It uses the `cost` value
/// (approximated as `width × height × scale² × 4` bytes) to enforce
/// ``DecodedImageCacheConfiguration/memoryByteLimit`` and evicts the
/// least-recently-used entries when the limit is exceeded.
///
/// Entries also carry an ``MemoryCacheEntry/expiresAt`` date; stale entries
/// are rejected and removed on the next read.
///
/// ## Sendable conformance
///
/// `DecodedImageCache` is marked `@unchecked Sendable` because `NSCache` is
/// internally thread-safe but does not itself conform to `Sendable`.  All
/// mutations go through `NSCache`'s own locking, so the `@unchecked` annotation
/// is safe here.
final class DecodedImageCache: @unchecked Sendable {

    // MARK: - Singleton

    /// The shared instance used by ``CachedImageLoader``.
    static let shared = DecodedImageCache()

    // MARK: - Private State

    private let cache: NSCache<NSString, MemoryCacheEntry>

    // MARK: - Init

    /// Creates a `DecodedImageCache` with the given memory limits.
    ///
    /// - Parameters:
    ///   - countLimit: Maximum number of images to keep in memory.
    ///     When exceeded, `NSCache` evicts entries using its LRU strategy.
    ///     Defaults to **150**.
    ///   - byteLimit: Maximum total decoded memory cost in bytes.
    ///     Defaults to **75 MB**.
    init(countLimit: Int = 150, byteLimit: Int = 75 * 1_024 * 1_024) {
        cache              = NSCache()
        cache.countLimit   = countLimit
        cache.totalCostLimit = byteLimit
    }

    // MARK: - Read

    /// Returns a decoded image for `key`, or `nil` if the entry is absent or stale.
    ///
    /// - Parameter key: The ``CacheKey`` identifying the image.
    /// - Returns: A valid, non-expired ``PlatformImage``, or `nil` on a miss.
    func image(for key: CacheKey) -> PlatformImage? {
        guard
            let entry = cache.object(forKey: key.diskIdentifier as NSString),
            !entry.isExpired
        else { return nil }
        return entry.image
    }

    // MARK: - Write

    /// Stores a decoded image under `key`.
    ///
    /// - Parameters:
    ///   - image: The decoded image to store.
    ///   - key: The ``CacheKey`` identifying this image.
    ///   - expiration: Time interval from now until the entry becomes stale.
    func store(_ image: PlatformImage, for key: CacheKey, expiration: TimeInterval) {
        let cost  = byteCost(of: image)
        let entry = MemoryCacheEntry(image: image, cost: cost, expiration: expiration)
        cache.setObject(entry, forKey: key.diskIdentifier as NSString, cost: cost)
    }

    // MARK: - Eviction

    /// Removes all entries from the cache.
    func clearAll() {
        cache.removeAllObjects()
    }

    // MARK: - Private

    /// Approximates the uncompressed memory cost of `image` in bytes.
    ///
    /// Uses `width × height × scale² × 4` as a conservative estimate for a
    /// BGRA bitmap (4 bytes per pixel).
    private func byteCost(of image: PlatformImage) -> Int {
#if os(macOS)
        guard let rep = image.representations.first else { return 0 }
        return rep.pixelsWide * rep.pixelsHigh * 4
#else
        return Int(image.size.width * image.size.height * image.scale * image.scale * 4)
#endif
    }
}
