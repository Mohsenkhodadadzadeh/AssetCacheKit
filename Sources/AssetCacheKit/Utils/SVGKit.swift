//
//  SVGKit.swift
//  AssetCacheKit
//
//  Created by mohsen on 2/25/25.
//

import Darwin
import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

import Combine
import SwiftUI

/// Represents an SVG document that can be rendered and manipulated.
@objc
public class CGSVGDocument: NSObject { }

/// Releases the allocated CGSVGDocument instance.
public let CGSVGDocumentRelease: (@convention(c) (CGSVGDocument?) -> Void) = load("CGSVGDocumentRelease")

/// Creates an SVG document from raw data.
public let CGSVGDocumentCreateFromData: (@convention(c) (CFData?, CFDictionary?) -> Unmanaged<CGSVGDocument>?) = load("CGSVGDocumentCreateFromData")

/// Draws an SVG document into a given graphics context.
public let CGContextDrawSVGDocument: (@convention(c) (CGContext?, CGSVGDocument?) -> Void) = load("CGContextDrawSVGDocument")

/// Retrieves the canvas size of the SVG document.
public let CGSVGDocumentGetCanvasSize: (@convention(c) (CGSVGDocument?) -> CGSize) = load("CGSVGDocumentGetCanvasSize")

/// Type alias for rendering an image from an SVG document.
typealias ImageWithCGSVGDocument = @convention(c) (AnyObject, Selector, CGSVGDocument) -> PlatformImage

/// Selector for generating a UIImage from an SVG document.
public let ImageWithCGSVGDocumentSEL: Selector = NSSelectorFromString("_imageWithCGSVGDocument:")

/// Loads the CoreSVG private framework.
nonisolated(unsafe) public let coreSVG = dlopen("/System/Library/PrivateFrameworks/CoreSVG.framework/CoreSVG", RTLD_NOW)

/// Dynamically loads a symbol from the CoreSVG framework.
/// - Parameter name: The name of the symbol to load.
/// - Returns: The loaded symbol cast to the specified type.
///
/// - Warning: When CoreSVG is unavailable, or the symbol has been renamed by a
///   future OS release, `dlsym` returns `nil` and the resulting function
///   pointer is null.  Callers must check ``isCoreSVGAvailable`` before
///   invoking any of the loaded symbols; calling a null pointer crashes.
func load<T>(_ name: String) -> T {
    unsafeBitCast(dlsym(coreSVG, name), to: T.self)
}

/// Indicates whether the private CoreSVG framework — and every symbol this file
/// depends on — could be resolved at runtime.
///
/// CoreSVG is not a public API.  It is absent on some platforms and could be
/// removed or renamed in any OS update, so every entry point that would call
/// into it checks this flag first and degrades to a decode failure rather than
/// jumping through a null function pointer.
let isCoreSVGAvailable: Bool = {
    guard coreSVG != nil else { return false }
    let symbols = [
        "CGSVGDocumentRelease",
        "CGSVGDocumentCreateFromData",
        "CGContextDrawSVGDocument",
        "CGSVGDocumentGetCanvasSize",
    ]
    return symbols.allSatisfy { dlsym(coreSVG, $0) != nil }
}()

/// A utility class for handling and rendering SVG images.
public class SVGKit {

    /// Releases the allocated SVG document when the instance is deallocated.
    deinit {
        guard let document else { return }
        CGSVGDocumentRelease(document)
    }

    /// The internal SVG document.
    var document: CGSVGDocument?

    /// Initializes an `SVGKit` instance from an SVG string.
    /// - Parameter value: The SVG string.
    public convenience init?(_ value: String) {
        guard let data = value.data(using: .utf8) else { return nil }
        self.init(data)
    }

    /// Initializes an `SVGKit` instance from raw SVG data.
    /// - Parameter data: The raw SVG data.
    ///
    /// Returns `nil` when CoreSVG is unavailable on this OS, when the bytes are
    /// not parseable SVG, or when the parsed document has an empty canvas.
    public init?(_ data: Data) {
        guard isCoreSVGAvailable else { return nil }
        guard let document = CGSVGDocumentCreateFromData(data as CFData, nil)?.takeUnretainedValue() else { return nil }

        // `CGSVGDocumentCreateFromData` follows the Core Foundation *create*
        // rule and hands back a +1 reference.  Bailing out here without
        // releasing it would leak the document, since `deinit` never runs on a
        // failed initialiser.
        guard CGSVGDocumentGetCanvasSize(document) != .zero else {
            CGSVGDocumentRelease(document)
            return nil
        }
        self.document = document
    }

    /// The size of the SVG canvas.
    public var size: CGSize {
        guard let document else { return .zero }
        return CGSVGDocumentGetCanvasSize(document)
    }
    
    /// Converts the SVG document into a SwiftUI Image.
    /// - Returns: A SwiftUI `Image` representation of the SVG.
    public func swiftUIImage() -> Image? {
        guard let platformImage = renderPlatformImage() else { return nil }
#if os(macOS)
        return Image(nsImage: platformImage)
            .resizable()
#else
        return Image(uiImage: platformImage)
            .resizable()
#endif
    }

    /// Renders the SVG document as a PlatformImage.
    /// - Returns: A `PlatformImage` representing the SVG.
    private func renderPlatformImage() -> PlatformImage? {
        guard let document, size != .zero else { return nil }

        #if os(macOS)
        let image = NSImage(size: size)
        image.lockFocusFlipped(true)
        if let context = NSGraphicsContext.current?.cgContext {
            CGContextDrawSVGDocument(context, document)
            image.unlockFocus()
            return image
        }
        image.unlockFocus()
        return nil
        #elseif os(watchOS)
        // watchOS has no `UIGraphicsImageRenderer`, so draw into a raw bitmap
        // context and wrap the result.
        let width  = Int(size.width.rounded())
        let height = Int(size.height.rounded())

        guard width > 0, height > 0,
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                    | CGBitmapInfo.byteOrder32Little.rawValue
              )
        else { return nil }

        // A bare `CGContext` has a bottom-left origin, while CoreSVG draws in a
        // top-left space — flip before drawing so the render isn't upside down.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        CGContextDrawSVGDocument(context, document)

        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
        #else
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            CGContextDrawSVGDocument(context.cgContext, document)
        }
        #endif
    }
   
    /// Draws the SVG document into a given graphics context.
    /// - Parameter context: The graphics context where the SVG should be drawn.
    public func draw(in context: CGContext) {
        draw(in: context, size: size)
    }

    /// Draws the SVG document into a given graphics context with a specified target size.
    /// - Parameters:
    ///   - context: The graphics context where the SVG should be drawn.
    ///   - target: The target size for rendering the SVG.
    public func draw(in context: CGContext, size target: CGSize) {

        var target = target

        let ratio = (
            x: target.width / size.width,
            y: target.height / size.height
        )

        let rect = (
            document: CGRect(origin: .zero, size: size), ()
        )

        let scale: (x: CGFloat, y: CGFloat)

        if target.width <= 0 {
            scale = (ratio.y, ratio.y)
            target.width = size.width * scale.x
        } else if target.height <= 0 {
            scale = (ratio.x, ratio.x)
            target.width = size.width * scale.y
        } else {
            let min = min(ratio.x, ratio.y)
            scale = (min, min)
            target.width = size.width * scale.x
            target.height = size.height * scale.y
        }

        let transform = (
            scale: CGAffineTransform(scaleX: scale.x, y: scale.y),
            aspect: CGAffineTransform(translationX: (target.width / scale.x - rect.document.width) / 2, y: (target.height / scale.y - rect.document.height) / 2)
        )

        context.translateBy(x: 0, y: target.height)
        context.scaleBy(x: 1, y: -1)
        context.concatenate(transform.scale)
        context.concatenate(transform.aspect)

        CGContextDrawSVGDocument(context, document)
    }
    
    
}
