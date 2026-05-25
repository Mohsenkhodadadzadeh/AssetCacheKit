//
//  DiskCacheMetadata.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/25/26.
//

import Foundation

/// Metadata persisted alongside each file in ``DiskCache``.
///
/// Every cached asset on disk is accompanied by a JSON-encoded `DiskCacheMetadata`
/// file stored with a `.meta` extension.  ``DiskCache`` reads this metadata on every
/// cache hit to verify that the entry has not expired before serving its data.
///
/// ### File layout on disk
///
/// ```
/// <caches>/com.assetcachekit.assets/
///   ├── a1b2c3d4.cache   ← raw asset bytes
///   ├── a1b2c3d4.meta    ← DiskCacheMetadata (JSON)
///   ├── e5f6a7b8.cache
///   └── e5f6a7b8.meta
/// ```
struct DiskCacheMetadata: Codable {

    /// The disk identifier of the cached entry, used to correlate the `.meta` file
    /// with its companion `.cache` file.
    let key: String

    /// The date and time at which this entry was first written to disk.
    let createdAt: Date

    /// The date and time after which the entry is considered stale.
    ///
    /// ``DiskCache`` checks this field on every read.  Stale entries are removed
    /// from disk before `nil` is returned to the caller.
    let expiresAt: Date

    /// The size of the companion `.cache` data file in bytes.
    ///
    /// Used by ``DiskCache`` to maintain an accurate running total of disk usage
    /// without repeatedly querying the file system.
    let fileSize: Int
}
