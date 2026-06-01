//
//  AssetCacheConfiguration.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/25/26.
//

import Foundation

// MARK: - AssetCacheConfiguration

/// Configuration for the asset caching system.
///
/// `AssetCacheConfiguration` controls every tunable parameter of ``AssetCache``:
/// how much raw data is kept in memory, how much space is used on disk,
/// when entries expire, and how network failures are retried.
///
/// Pass a custom configuration to ``AssetCache/init(configuration:)`` to override
/// the defaults for a specific use-case — for example, a stricter limit for a
/// secondary cache used only for low-priority background prefetching.
///
/// ```swift
/// let config = AssetCacheConfiguration(
///     rawDataMemoryByteLimit: 10 * 1_024 * 1_024,  // 10 MB raw data in memory
///     diskByteLimit:         100 * 1_024 * 1_024,  // 100 MB on disk
///     defaultExpiration:     3 * 24 * 60 * 60,     // 3 days
///     retryPolicy: RetryPolicy(maxAttempts: 5, initialDelay: 1.0, multiplier: 2.0)
/// )
/// let cache = AssetCache(configuration: config)
/// ```
struct AssetCacheConfiguration: Sendable {

    /// Maximum byte size of raw (compressed) asset data kept in the memory layer.
    ///
    /// The memory layer stores compressed bytes — JPEG, PDF, SVG, MP3, etc. —
    /// rather than decoded objects, so this limit can be set much lower than a
    /// decoded-image cache.  When the limit is exceeded, `NSCache` evicts the
    /// least-recently-used entries automatically.
    ///
    /// Defaults to **20 MB**.
    var rawDataMemoryByteLimit: Int

    /// Maximum total size of the on-disk cache in bytes.
    ///
    /// Once the limit is exceeded after a write, the disk layer removes the
    /// least-recently-accessed files until the total size falls within the limit.
    ///
    /// Defaults to **200 MB**.
    var diskByteLimit: Int

    /// Lifetime of a cached entry before it is considered stale.
    ///
    /// Stale entries are removed lazily on the next read attempt for that key.
    ///
    /// Defaults to **7 days**.
    var defaultExpiration: TimeInterval

    /// Retry strategy applied when a network request fails.
    ///
    /// See ``RetryPolicy`` for built-in presets and customisation options.
    var retryPolicy: RetryPolicy

    /// Creates a configuration with the provided parameters.
    ///
    /// - Parameters:
    ///   - rawDataMemoryByteLimit: Maximum compressed asset data in memory. Defaults to 20 MB.
    ///   - diskByteLimit: Maximum disk cache size in bytes. Defaults to 200 MB.
    ///   - defaultExpiration: Entry lifetime in seconds. Defaults to 7 days.
    ///   - retryPolicy: Network retry strategy. Defaults to ``RetryPolicy/default``.
    init(
        rawDataMemoryByteLimit: Int         = 80  * 1_024 * 1_024,
        diskByteLimit: Int                  = 512 * 1_024 * 1_024,
        defaultExpiration: TimeInterval     = 365 * 24 * 60 * 60,
        retryPolicy: RetryPolicy            = .default
    ) {
        self.rawDataMemoryByteLimit = rawDataMemoryByteLimit
        self.diskByteLimit          = diskByteLimit
        self.defaultExpiration      = defaultExpiration
        self.retryPolicy            = retryPolicy
    }

    /// The default configuration used by ``AssetCache/shared``.
    ///
    /// | Property | Default Value |
    /// |---|---|
    /// | `rawDataMemoryByteLimit` | 20 MB |
    /// | `diskByteLimit` | 200 MB |
    /// | `defaultExpiration` | 7 days |
    /// | `retryPolicy` | ``RetryPolicy/default`` |
    static let `default` = AssetCacheConfiguration()
}

// MARK: - RetryPolicy

/// Describes the retry behaviour applied when a network request fails.
///
/// Each retry waits longer than the previous one, following an exponential
/// back-off schedule controlled by ``initialDelay`` and ``multiplier``.
///
/// ### Example schedule for the default policy
///
/// | Attempt | Waits before attempt |
/// |---------|----------------------|
/// | 1st | — |
/// | 2nd | 0.5 s |
/// | 3rd | 1.0 s |
/// | — | throws last error |
struct RetryPolicy: Sendable {

    /// Total number of attempts, including the initial try.
    ///
    /// A value of `1` means no retries will be performed.
    let maxAttempts: Int

    /// Delay in seconds before the first retry.
    let initialDelay: TimeInterval

    /// Multiplier applied to the delay after each successive failure.
    let multiplier: Double

    /// Creates a retry policy with the given parameters.
    ///
    /// - Parameters:
    ///   - maxAttempts: Total attempts including the first try.
    ///   - initialDelay: Delay in seconds before the first retry.
    ///   - multiplier: Growth factor applied to the delay after each failure.
    init(maxAttempts: Int, initialDelay: TimeInterval, multiplier: Double) {
        self.maxAttempts  = maxAttempts
        self.initialDelay = initialDelay
        self.multiplier   = multiplier
    }

    /// Three attempts with 0.5 s initial delay and a 2× back-off multiplier.
    static let `default` = RetryPolicy(maxAttempts: 3, initialDelay: 0.5, multiplier: 2.0)

    /// A single attempt with no retries.
    static let none = RetryPolicy(maxAttempts: 1, initialDelay: 0, multiplier: 1.0)
}
