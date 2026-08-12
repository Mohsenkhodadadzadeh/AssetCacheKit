//
//  ImageDecoder.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/25/26.
//

import CoreGraphics
import Foundation
import ImageIO

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Converts raw image data into a ``PlatformImage``, always on a background thread.
///
/// `ImageDecoder` is a caseless `enum` used as a namespace for its `static` API;
/// it is not intended to be instantiated.
///
/// ## Why a separate decoder?
///
/// Decoding compressed image data (JPEG, PNG, HEIC, etc.) into a bitmap is CPU-
/// intensive.  Without explicit off-loading, it happens on the main thread at the
/// first `drawRect` call, causing dropped frames.  `ImageDecoder` dispatches all
/// work to a background `Task` at `.userInitiated` priority, so the calling actor's
/// thread remains free while the image is being prepared.
///
/// ## Downsampling
///
/// When a `targetSize` is supplied, `ImageDecoder` uses
/// `CGImageSourceCreateThumbnailAtIndex` from the ImageIO framework to produce a
/// scaled thumbnail **without** decoding the full source image into memory first.
/// For a 4K photo displayed at 80 × 80 pt, this reduces peak memory usage from
/// roughly 32 MB to under 100 KB.
///
/// ## Pre-rendering
///
/// On non-macOS platforms, decoded `UIImage` objects are drawn into an off-screen
/// `CGContext` immediately after decoding.  This forces the CPU to expand compressed
/// pixel data into an uncompressed BGRA bitmap on the background thread, eliminating
/// the decompression cost at draw time.
enum ImageDecoder {

    // MARK: - Public

    /// Asynchronously decodes `data` into a ``PlatformImage``.
    ///
    /// All work is dispatched to a `Task.detached` closure at `.userInitiated`
    /// priority, keeping the calling actor's thread free during the operation.
    ///
    /// - Parameters:
    ///   - data: Compressed image data in any format supported by ImageIO
    ///     (JPEG, PNG, HEIC, GIF, WebP, etc.).
    ///   - scale: Display scale factor applied when constructing the `UIImage` /
    ///     `NSImage`.  Typically `UIScreen.main.scale` or `1` for macOS.
    ///   - targetSize: When non-`nil`, the image is downsampled using ImageIO to
    ///     fit within these point dimensions multiplied by `scale`.  Pass `nil`
    ///     to decode at the original resolution.
    /// - Returns: A decoded ``PlatformImage`` ready for display.
    /// - Throws: ``AppError/assetLoading(.invalidImageData)`` if the data cannot
    ///   be decoded by the platform's image framework.
    static func decode(
        data: Data,
        scale: CGFloat,
        targetSize: CGSize?
    ) async throws -> PlatformImage {
        try await Task.detached(priority: .userInitiated) {
            if let targetSize {
                return DecodedImage(try downsample(data: data, to: targetSize, scale: scale))
            }
            return DecodedImage(try decode(data: data, scale: scale))
        }.value.image
    }

    // MARK: - Private

    /// Carries a freshly decoded image out of the decoding task.
    ///
    /// `NSImage` only gained a `Sendable` conformance in macOS 14, so returning
    /// a ``PlatformImage`` straight out of `Task.detached` is not expressible on
    /// the older releases this package supports.  The transfer is nonetheless
    /// safe: the image is constructed inside the task and no other reference to
    /// it exists at the moment it is handed back.
    private struct DecodedImage: @unchecked Sendable {
        let image: PlatformImage
        init(_ image: PlatformImage) { self.image = image }
    }

    /// Produces a scaled thumbnail using `CGImageSourceCreateThumbnailAtIndex`.
    ///
    /// This API decodes only the pixels required for the thumbnail, never loading
    /// the full image into memory.  It is significantly more efficient than
    /// decoding the full image and then resizing it in a `CGContext`.
    private static func downsample(
        data: Data,
        to targetSize: CGSize,
        scale: CGFloat
    ) throws -> PlatformImage {
        let sourceOptions: CFDictionary = [kCGImageSourceShouldCache: false] as CFDictionary

        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            throw AppError.assetLoading(.invalidImageData)
        }

        let maxPixels = max(targetSize.width, targetSize.height) * scale
        let thumbOptions: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions) else {
            throw AppError.assetLoading(.invalidImageData)
        }

        return makePlatformImage(from: cgImage, scale: scale)
    }

    /// Decodes the full image and pre-renders it into an uncompressed bitmap.
    private static func decode(data: Data, scale: CGFloat) throws -> PlatformImage {
#if os(macOS)
        guard let image = NSImage(data: data) else {
            throw AppError.assetLoading(.invalidImageData)
        }
        return image
#else
        guard let image = UIImage(data: data, scale: scale) else {
            throw AppError.assetLoading(.invalidImageData)
        }
        return image.prerendered() ?? image
#endif
    }

    /// Wraps a decoded `CGImage` in the platform's image type.
    ///
    /// The point size is derived from the bitmap's real pixel dimensions rather
    /// than from the requested `targetSize`.  `targetSize` is only a *bounding
    /// box* — `kCGImageSourceThumbnailMaxPixelSize` preserves the source aspect
    /// ratio — so a 16:9 photo asked to fit 80 × 80 comes back 80 × 45.
    /// Declaring that bitmap as 80 × 80 would stretch it on screen.
    private static func makePlatformImage(
        from cgImage: CGImage,
        scale: CGFloat
    ) -> PlatformImage {
#if os(macOS)
        let pointSize = CGSize(
            width: CGFloat(cgImage.width) / scale,
            height: CGFloat(cgImage.height) / scale
        )
        return NSImage(cgImage: cgImage, size: pointSize)
#else
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
#endif
    }
}

// MARK: - UIImage Pre-rendering

#if !os(macOS)
private extension UIImage {
    /// Draws the image into an uncompressed BGRA bitmap context on the current thread.
    ///
    /// Without this step, `UIKit` defers decompression to the first `drawRect` call,
    /// which occurs on the main thread and can cause visible frame drops.
    /// By pre-rendering on a background thread, the main thread only performs
    /// a fast GPU texture upload when the image is first displayed.
    func prerendered() -> UIImage? {
        guard let cgImage else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue:
            CGImageAlphaInfo.premultipliedFirst.rawValue |
            CGBitmapInfo.byteOrder32Little.rawValue
        )
        guard let context = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(
            origin: .zero,
            size: CGSize(width: cgImage.width, height: cgImage.height)
        ))

        return context.makeImage().map {
            UIImage(cgImage: $0, scale: scale, orientation: imageOrientation)
        }
    }
}
#endif
