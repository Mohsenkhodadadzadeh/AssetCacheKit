//
//  CachedImageLoader.swift
//  AssetCacheKit
//
//  Created by mohsen on 12/27/24.
//
import CoreGraphics
import SwiftUI

/// An ``AssetLoader`` that loads and caches remote images.
///
/// `CachedImageLoader` uses a two-stage cache strategy optimised for images:
///
/// 1. **Decoded image cache** — ``DecodedImageCache`` holds already-decompressed
///    ``PlatformImage`` objects in memory.  A hit here requires no decoding work
///    and is ideal for cells revisited during scrolling.
///
/// 2. **Asset data cache** — ``AssetCache`` holds compressed raw bytes in memory
///    and on disk.  On a hit, the compressed data is decoded in the background
///    via ``ImageDecoder`` before being returned.
///
/// All other caching features — disk persistence, expiration, LRU eviction,
/// request deduplication, and retry — are provided by the shared ``AssetCache``
/// and apply equally to every other loader in the framework.
///
/// ## Downsampling
///
/// Pass `targetSize` to decode only the pixels that fit on screen.  This uses
/// ImageIO internally and avoids loading a full-resolution image into memory
/// just to display a small thumbnail.
///
/// ## Usage
///
/// ```swift
/// // Standard usage
/// AssetCacheKit(
///     loader: CachedImageLoader(url: url),
///     content: { image in image.resizable().scaledToFill() },
///     placeholder: { ProgressView() },
///     error: { _ in Image(systemName: "exclamationmark.triangle") }
/// )
///
/// // With downsampling for a thumbnail list
/// CachedImageLoader(url: url, targetSize: CGSize(width: 80, height: 80))
/// ```
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CachedImageLoader: AssetLoader, Equatable {

    // MARK: - Public Properties

    public var url: URL?

    // MARK: - Private State

    private let scale: CGFloat
    private let targetSize: CGSize?
    private let assetCache: AssetCache
    private let decodedCache: DecodedImageCache

    // MARK: - Init

    /// Creates an image loader using the shared caches.
    ///
    /// - Parameters:
    ///   - url: The remote location of the image.
    ///   - scale: Display scale used when decoding. Defaults to `1`.
    ///   - targetSize: When provided, the image is downsampled to fit within
    ///     these dimensions using ImageIO.  Pass `nil` to decode at full resolution.
    public init(url: URL?, scale: CGFloat = 1, targetSize: CGSize? = nil) {
        self.url          = url
        self.scale        = scale
        self.targetSize   = targetSize
        self.assetCache   = .shared
        self.decodedCache = .shared
    }

    /// Creates an image loader with injected caches.
    ///
    /// Intended for unit testing, where mock caches can be provided to avoid
    /// disk I/O or network access.
    ///
    /// - Parameters:
    ///   - url: The remote location of the image.
    ///   - scale: Display scale. Defaults to `1`.
    ///   - targetSize: Optional downsampling target.
    ///   - assetCache: The ``AssetCache`` providing raw compressed data.
    ///   - decodedCache: The ``DecodedImageCache`` storing decoded images.
    internal init(
        url: URL?,
        scale: CGFloat = 1,
        targetSize: CGSize? = nil,
        assetCache: AssetCache,
        decodedCache: DecodedImageCache
    ) {
        self.url          = url
        self.scale        = scale
        self.targetSize   = targetSize
        self.assetCache   = assetCache
        self.decodedCache = decodedCache
    }

    // MARK: - AssetLoader

    /// Loads the remote image and returns a SwiftUI `Image` ready for display.
    ///
    /// The resolution order is:
    /// 1. ``DecodedImageCache`` — decoded ``PlatformImage`` in memory (fastest).
    /// 2. ``AssetCache`` — compressed data in memory or on disk, decoded in background.
    /// 3. Network — downloaded with retry, stored in both caches before returning.
    ///
    /// - Returns: A SwiftUI `Image` wrapping a decoded ``PlatformImage``.
    /// - Throws: ``AppError/assetLoading(.invalidURL)`` when ``url`` is `nil`,
    ///   or a network / decoding error on failure.
    public func loadAsset() async throws -> Image {
        guard let url else {
            throw AppError.assetLoading(.invalidURL)
        }

        let key = CacheKey(url: url, scale: scale, targetSize: targetSize)

        // ① Decoded memory hit — no async work required
        if let decoded = decodedCache.image(for: key) {
            return swiftUIImage(from: decoded)
        }

        // ② Raw data from AssetCache (memory or disk or network)
        let data = try await assetCache.data(for: url)

        // ③ Decode in background
        let platformImage = try await ImageDecoder.decode(
            data: data,
            scale: scale,
            targetSize: targetSize
        )

        // ④ Store decoded image so the next hit is instant
        let expiration = AssetCacheConfiguration.default.defaultExpiration
        decodedCache.store(platformImage, for: key, expiration: expiration)

        return swiftUIImage(from: platformImage)
    }

    // MARK: - Equatable

    public static func == (lhs: CachedImageLoader, rhs: CachedImageLoader) -> Bool {
        lhs.url        == rhs.url       &&
        lhs.scale      == rhs.scale     &&
        lhs.targetSize == rhs.targetSize
    }

    // MARK: - Private

    private func swiftUIImage(from platformImage: PlatformImage) -> Image {
#if os(macOS)
        Image(nsImage: platformImage)
#else
        Image(uiImage: platformImage)
#endif
    }
}
