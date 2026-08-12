//
//  CacheKey.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/25/26.
//

import CoreGraphics
import Foundation


/// A unique, hashable identifier for a decoded image entry in ``DecodedImageCache``.
///
/// Two keys are equal — and therefore share the same decoded cache entry — only when
/// their ``url``, ``scale``, and ``targetSize`` all match.  This means a full-resolution
/// image and a downsampled thumbnail of the same URL are stored as separate entries,
/// which is the correct behaviour: each represents a distinct set of decoded pixels.
///
/// > Note: ``AssetCache`` (raw data layer) uses the URL alone as its key, because
/// > compressed bytes are the same regardless of the display scale or target size.
/// > `CacheKey` is used exclusively by ``DecodedImageCache``.
struct CacheKey: Hashable, Sendable {

    /// The remote location of the image asset.
    let url: URL

    /// The display scale factor applied during decoding.
    ///
    /// Affects the pixel dimensions of the decoded bitmap.  A scale of `2` on a
    /// retina display produces twice as many pixels as a scale of `1`.
    let scale: CGFloat

    /// The optional maximum display dimensions used for downsampling.
    ///
    /// `nil` means the image was decoded at its original resolution.
    let targetSize: CGSize?

    /// A short, filesystem-safe string that uniquely identifies this key.
    ///
    /// Used as the key string passed to `NSCache`.  Derived by hashing the
    /// combination of ``url``, ``scale``, and ``targetSize`` — all three must
    /// take part, or a downsampled thumbnail and the full-resolution decode of
    /// the same URL would share a single entry and hand back each other's pixels.
    var diskIdentifier: String {
        let sizeComponent = targetSize.map { "\($0.width)x\($0.height)" } ?? "native"
        return "\(url.absoluteString)|scale=\(scale)|size=\(sizeComponent)".cacheDigest
    }
}
