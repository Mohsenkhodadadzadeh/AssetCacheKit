//
//  AssetCacheConfiguration.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/25/26.
//

import Foundation

// MARK: - StorageDirectory

/// Specifies which system directory the disk cache should use for persistent storage.
///
/// Choose `.cache` (the default) for data that the system can safely purge under
/// low-storage conditions.  Choose `.document` when the data must survive low-storage
/// purges — for example, assets that the user explicitly downloaded for offline use.
///
/// > Important: Storing large, re-downloadable assets in `.document` counts against
/// > the user's iCloud backup quota.  Prefer `.cache` unless persistence across
/// > system purges is a hard requirement.
///
/// ## Usage
///
/// ```swift
/// // Default — survives app restarts, but may be purged by the OS
/// let config = AssetCacheConfiguration()          // storageDirectory: .cache
///
/// // Persists across OS-level purges; backed up to iCloud
/// let config = AssetCacheConfiguration(storageDirectory: .document)
/// ```
public enum StorageDirectory: Sendable {
    /// The system Caches directory (`Library/Caches`).
    ///
    /// Files here persist across app launches but **may be deleted** by the OS
    /// when storage is low.  This is the recommended choice for re-downloadable assets.
    case cache

    /// The Documents directory (`Documents`).
    ///
    /// Files here are **never purged** by the OS and are included in iCloud backups.
    /// Use this only when the asset must survive low-storage conditions.
    case document

    /// Resolves this case to the matching `FileManager` search-path directory.
    var searchPathDirectory: FileManager.SearchPathDirectory {
        switch self {
        case .cache:    return .cachesDirectory
        case .document: return .documentDirectory
        }
    }
}

// MARK: - AssetCacheConfiguration

/// Configuration for the asset caching system.
///
/// `AssetCacheConfiguration` controls every tunable parameter of ``AssetCache``—
/// how much raw data is kept in memory, how much space is used on disk,
/// when entries expire, how network failures are retried, and **which system
/// directory is used for persistent storage**.
///
/// Pass a custom configuration to ``AssetCache/configure(_:)`` once at app
/// startup (e.g. in `AppDelegate` or the `@main` entry point) before any
/// loader is invoked.
///
/// ```swift
/// // AppDelegate / @main
/// AssetCache.configure(
///     AssetCacheConfiguration(storageDirectory: .document)
/// )
/// ```
///
/// Individual asset requests do **not** need to carry the configuration — it is
/// read once during ``AssetCache`` initialisation and applied globally.
public struct AssetCacheConfiguration: Sendable {

    /// The file-system directory used for the persistent disk cache.
    ///
    /// Defaults to ``StorageDirectory/cache`` to preserve backward compatibility.
    public var storageDirectory: StorageDirectory

    /// Maximum byte size of raw (compressed) asset data kept in the memory layer.
    ///
    /// The memory layer stores compressed bytes — JPEG, PDF, SVG, MP3, etc. —
    /// rather than decoded objects, so this limit can be set much lower than a
    /// decoded-image cache.  When the limit is exceeded, `NSCache` evicts the
    /// least-recently-used entries automatically.
    ///
    /// Defaults to **80 MB**.
    public var rawDataMemoryByteLimit: Int

    /// Maximum total size of the on-disk cache in bytes.
    ///
    /// Once the limit is exceeded after a write, the disk layer removes the
    /// least-recently-accessed files until the total size falls within the limit.
    ///
    /// Defaults to **512 MB**.
    public var diskByteLimit: Int

    /// Lifetime of a cached entry before it is considered stale.
    ///
    /// Stale entries are removed lazily on the next read attempt for that key.
    ///
    /// Defaults to **365 days**.
    public var defaultExpiration: TimeInterval

    /// Retry strategy applied when a network request fails.
    ///
    /// See ``RetryPolicy`` for built-in presets and customisation options.
    public var retryPolicy: RetryPolicy

    /// Creates a configuration with the provided parameters.
    ///
    /// - Parameters:
    ///   - storageDirectory: File-system directory for the disk cache. Defaults to `.cache`.
    ///   - rawDataMemoryByteLimit: Maximum compressed asset data in memory. Defaults to 80 MB.
    ///   - diskByteLimit: Maximum disk cache size in bytes. Defaults to 512 MB.
    ///   - defaultExpiration: Entry lifetime in seconds. Defaults to 365 days.
    ///   - retryPolicy: Network retry strategy. Defaults to ``RetryPolicy/default``.
    public init(
        storageDirectory: StorageDirectory      = .cache,
        rawDataMemoryByteLimit: Int             = 80  * 1_024 * 1_024,
        diskByteLimit: Int                      = 512 * 1_024 * 1_024,
        defaultExpiration: TimeInterval         = 365 * 24 * 60 * 60,
        retryPolicy: RetryPolicy                = .default
    ) {
        self.storageDirectory       = storageDirectory
        self.rawDataMemoryByteLimit = rawDataMemoryByteLimit
        self.diskByteLimit          = diskByteLimit
        self.defaultExpiration      = defaultExpiration
        self.retryPolicy            = retryPolicy
    }

    /// The default configuration used by ``AssetCache/shared``.
    ///
    /// | Property | Default Value |
    /// |---|---|
    /// | `storageDirectory` | `.cache` |
    /// | `rawDataMemoryByteLimit` | 80 MB |
    /// | `diskByteLimit` | 512 MB |
    /// | `defaultExpiration` | 365 days |
    /// | `retryPolicy` | ``RetryPolicy/default`` |
    public static let `default` = AssetCacheConfiguration()
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
public struct RetryPolicy: Sendable {

    /// Total number of attempts, including the initial try.
    ///
    /// A value of `1` means no retries will be performed.
    public let maxAttempts: Int

    /// Delay in seconds before the first retry.
    public let initialDelay: TimeInterval

    /// Multiplier applied to the delay after each successive failure.
    public let multiplier: Double

    /// Creates a retry policy with the given parameters.
    ///
    /// - Parameters:
    ///   - maxAttempts: Total attempts including the first try.
    ///   - initialDelay: Delay in seconds before the first retry.
    ///   - multiplier: Growth factor applied to the delay after each failure.
    public init(maxAttempts: Int, initialDelay: TimeInterval, multiplier: Double) {
        self.maxAttempts  = maxAttempts
        self.initialDelay = initialDelay
        self.multiplier   = multiplier
    }

    /// Three attempts with 0.5 s initial delay and a 2× back-off multiplier.
    public static let `default` = RetryPolicy(maxAttempts: 3, initialDelay: 0.5, multiplier: 2.0)

    /// A single attempt with no retries.
    public static let none = RetryPolicy(maxAttempts: 1, initialDelay: 0, multiplier: 1.0)
}
