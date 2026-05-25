//
//  MemoryCacheEntry.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/25/26.
//

import Foundation

/// A wrapper stored in `NSCache` that pairs a decoded ``PlatformImage`` with its
/// expiration date and memory cost.
///
/// `NSCache` requires reference-type values, so `MemoryCacheEntry` is a `final class`.
/// All properties are written once at initialisation and never mutated afterward,
/// making instances safe to read from multiple threads without additional locking.
final class MemoryCacheEntry: @unchecked Sendable {

    // MARK: Stored Properties

    /// The decoded image ready for display.
    let image: PlatformImage

    /// Approximate memory cost in bytes, used by `NSCache` to enforce the total
    /// byte limit configured on ``DecodedImageCache``.
    ///
    /// Computed as `width × height × scale² × 4` (bytes per pixel for BGRA).
    let cost: Int

    /// The point in time after which this entry must not be served from cache.
    let expiresAt: Date

    // MARK: Computed Properties

    /// Returns `true` when the wall clock has passed ``expiresAt``.
    var isExpired: Bool { Date() > expiresAt }

    // MARK: Init

    /// Creates a new cache entry.
    ///
    /// - Parameters:
    ///   - image: The decoded ``PlatformImage`` to cache.
    ///   - cost: Approximate uncompressed size in bytes.
    ///   - expiration: Seconds from now until the entry becomes stale.
    init(image: PlatformImage, cost: Int, expiration: TimeInterval) {
        self.image     = image
        self.cost      = cost
        self.expiresAt = Date().addingTimeInterval(expiration)
    }
}
