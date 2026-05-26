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
    /// combination of ``url``, ``scale``, and ``targetSize``.
    var diskIdentifier: String {
//        let sizeTag = targetSize.map { "\(Int($0.width))x\(Int($0.height))" } ?? "full"
//        let raw = "\(url.absoluteString)@@\(scale)@@\(sizeTag)"
//        return String(format: "%llx", UInt64(bitPattern: Int64(raw.hashValue)))
      //  return String(format: "%llx", UInt64(bitPattern: Int64(url.absoluteString.hashValue)))
        let allowedChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "."))
        return url.absoluteString.suffix(70)
            .addingPercentEncoding(withAllowedCharacters: allowedChars) ?? url.absoluteString
    }
}
