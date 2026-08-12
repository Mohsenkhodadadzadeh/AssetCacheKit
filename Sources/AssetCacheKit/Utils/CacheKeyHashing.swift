//
//  CacheKeyHashing.swift
//  AssetCacheKit
//

import CryptoKit
import Foundation

extension String {

    /// A deterministic, filesystem-safe SHA-256 digest of the receiver, in
    /// lowercase hexadecimal.
    ///
    /// Cache identifiers must be **stable across process launches**, which rules
    /// out Swift's built-in `hashValue`: `Hasher` is seeded randomly per process,
    /// so the same URL would map to a different filename on every launch and the
    /// disk cache would never register a hit.
    ///
    /// The digest is always 64 characters — comfortably inside every filesystem's
    /// name limit — and contains only `0-9a-f`, so no escaping is required.
    var cacheDigest: String {
        SHA256.hash(data: Data(utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
