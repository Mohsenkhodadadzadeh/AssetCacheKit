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
func load<T>(_ name: String) -> T {
    unsafeBitCast(dlsym(coreSVG, name), to: T.self)
}

/// A utility class for handling and rendering SVG images.
public class SVGKit {

    /// Releases the allocated SVG document when the instance is deallocated.
    deinit { CGSVGDocumentRelease(document) }

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
    public init?(_ data: Data) {
        guard let document = CGSVGDocumentCreateFromData(data as CFData, nil)?.takeUnretainedValue() else { return nil }
        guard CGSVGDocumentGetCanvasSize(document) != .zero else { return nil }
        self.document = document
    }

    /// The size of the SVG canvas.
    public var size: CGSize {
        CGSVGDocumentGetCanvasSize(document)
    }
    
    /// Converts the SVG document into a SwiftUI Image.
    /// - Returns: A SwiftUI `Image` representation of the SVG.
    public func swiftUIImage() -> Image? {
        guard let platformImage = renderPlatformImage() else { return nil }
#if os(iOS)
        return Image(uiImage: platformImage)
            .resizable()
#elseif os(macOS)
        return Image(nsImage: platformImage)
            .resizable()
#endif
        
    }

    /// Renders the SVG document as a PlatformImage.
    /// - Returns: A `PlatformImage` representing the SVG.
    private func renderPlatformImage() -> PlatformImage? {
        guard let document else { return nil }
        
        #if os(iOS)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            CGContextDrawSVGDocument(context.cgContext, document)
        }
        #elseif os(macOS)
        let image = NSImage(size: size)
        image.lockFocusFlipped(true)
        if let context = NSGraphicsContext.current?.cgContext {
            CGContextDrawSVGDocument(context, document)
            image.unlockFocus()
            return image
        }
        image.unlockFocus()
        return nil
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
