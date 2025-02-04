//
//  PDFKitRepresentedView.swift
//  AssetCacheKit
//
//  Created by mohsen on 1/20/25.
//

import PDFKit
import SwiftUI

#if os(iOS)
/// A SwiftUI view that represents a `PDFView` from PDFKit.
///
/// This view is designed to display PDF content using a `PDFDocument`. It conforms to the `UIViewRepresentable` protocol,
/// allowing it to integrate with SwiftUI and provide a bridge to UIKit components.
public struct PDFKitRepresentedView: UIViewRepresentable {
    public typealias UIViewType = PDFView

    /// The PDF document to be displayed.
    let document: PDFDocument

    /// Determines whether the `PDFView` should automatically scale the PDF content to fit the view.
    ///
    /// - Default: `true`
    var autoScale: Bool = true
    
    /// Defines how the pages of the PDF document are displayed.
    ///
    /// - Default: `.singlePageContinuous`
    var displayMode: PDFDisplayMode = .singlePageContinuous
    
    /// Specifies the scrolling direction of the PDF pages.
    ///
    /// - Default: `.horizontal`
    var displayDirection: PDFDisplayDirection = .horizontal
    
    /// Creates the `PDFView` instance.
    ///
    /// This method is called once when the view is first created. It configures the `PDFView` with default settings and
    /// loads the provided `PDFDocument`.
    ///
    /// - Parameter context: The context for the `UIViewRepresentable` lifecycle.
    /// - Returns: An initialized `PDFView` instance.
    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .horizontal
        pdfView.document = document
        return pdfView
    }

    /// Updates the `PDFView` instance.
    ///
    /// This method is called whenever the SwiftUI view is updated. It updates the `PDFView` with the provided
    /// `PDFDocument` if it has changed.
    ///
    /// - Parameters:
    ///   - pdfView: The `PDFView` instance to be updated.
    ///   - context: The context for the `UIViewRepresentable` lifecycle.
    public func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.autoScales = autoScale
        pdfView.displayMode = displayMode
        pdfView.displayDirection = displayDirection
        pdfView.document = document
    }
    
    /// Sets whether the `PDFView` should automatically scale the document.
    ///
    /// - Parameter scale: A `Bool` value indicating whether auto-scaling should be enabled (`true`) or disabled (`false`).
    /// - Returns: A new instance of `PDFKitRepresentedView` with the updated setting.
    ///
    /// ```swift
    /// myPDF
    ///     .autoScale(false)
    /// ```
    func autoScale(_ scale: Bool) -> Self {
        var copy = self
        copy.autoScale = scale
        return copy
    }
    
    /// Sets the display mode for how the PDF pages are shown.
    ///
    /// The display mode determines how the pages of the PDF document are arranged and navigated.
    /// The available options for the `mode` parameter are:
    ///
    /// - `.singlePage`: Displays one page at a time, requiring the user to scroll or navigate to the next page.
    /// - `.singlePageContinuous`: Displays the pages continuously in a vertical scrolling manner, allowing for smooth scrolling through the document.
    /// - `.twoUp`: Displays two pages side by side, great for documents like magazines or books that are meant to be viewed in pairs.
    /// - `.twoUpContinuous`: Displays two pages side by side with continuous scrolling, allowing users to scroll through pages seamlessly in pairs.
    ///
    /// - Parameter mode: A `PDFDisplayMode` value determining how the pages are displayed.
    /// - Returns: A new instance of `PDFKitRepresentedView` with the updated mode.
    ///
    /// ### Example:
    /// ```swift
    /// myPDF
    ///     .displayMode(.twoUpContinuous)
    /// ```
    func displayMode(_ mode: PDFDisplayMode) -> Self {
        var copy = self
        copy.displayMode = mode
        return copy
    }
    
    /// Specifies and sets the scrolling direction for the PDF pages.
    ///
    /// This property determines how the pages of the PDF document are scrolled within the view.
    /// The scrolling direction can be customized based on the desired user experience.
    ///
    /// - Default: `.horizontal`
    ///
    /// - Possible values:
    ///   - `.horizontal`: Pages scroll from left to right (ideal for left-to-right languages).
    ///   - `.vertical`: Pages scroll from top to bottom (ideal for documents with a more natural top-to-bottom flow).
    ///
    /// - Parameter direction: A `PDFDisplayDirection` value that defines the scroll orientation.
    /// - Returns: A new instance of `PDFKitRepresentedView` with the updated direction.
    ///
    /// ### Example:
    /// ```swift
    /// myPDF
    ///     .displayDirection(.vertical)
    /// ```
    func displayDirection(_ direction: PDFDisplayDirection) -> Self {
        var copy = self
        copy.displayDirection = direction
        return copy
    }
    
    
}
#elseif os(macOS)
/// A SwiftUI view that represents a `PDFView` from PDFKit.
///
/// This view is designed to display PDF content using a `PDFDocument`. It conforms to the `NSViewRepresentable` protocol,
/// allowing it to integrate with SwiftUI and provide a bridge to UIKit components.
public struct PDFKitRepresentedView: NSViewRepresentable {
    
    public typealias NSViewType = PDFView
    
    /// The PDF document to be displayed.
    let document: PDFDocument

    /// Determines whether the `PDFView` should automatically scale the PDF content to fit the view.
    ///
    /// - Default: `true`
    var autoScale: Bool = true
    
    /// Defines how the pages of the PDF document are displayed.
    ///
    /// - Default: `.singlePageContinuous`
    var displayMode: PDFDisplayMode = .singlePageContinuous
    
    /// Specifies the scrolling direction of the PDF pages.
    ///
    /// - Default: `.horizontal`
    var displayDirection: PDFDisplayDirection = .horizontal
    /// Creates the `PDFView` instance.
    ///
    /// This method is called once when the view is first created. It configures the `PDFView` with default settings and
    /// loads the provided `PDFDocument`.
    ///
    /// - Parameter context: The context for the `NSViewRepresentable` lifecycle.
    /// - Returns: An initialized `PDFView` instance.
    public func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .horizontal
        pdfView.document = document
        return pdfView
    }

    /// Updates the `PDFView` instance.
    ///
    /// This method is called whenever the SwiftUI view is updated. It updates the `PDFView` with the provided
    /// `PDFDocument` if it has changed.
    ///
    /// - Parameters:
    ///   - pdfView: The `PDFView` instance to be updated.
    ///   - context: The context for the `NSViewRepresentable` lifecycle.
    public func updateNSView(_ pdfView: PDFView, context: Context) {
        pdfView.autoScales = autoScale
        pdfView.displayMode = displayMode
        pdfView.displayDirection = displayDirection
        pdfView.document = document
    }
    
    /// Sets whether the `PDFView` should automatically scale the document.
    ///
    /// - Parameter scale: A `Bool` value indicating whether auto-scaling should be enabled (`true`) or disabled (`false`).
    /// - Returns: A new instance of `PDFKitRepresentedView` with the updated setting.
    ///
    /// ```swift
    /// myPDF
    ///     .autoScale(false)
    /// ```
    func autoScale(_ scale: Bool) -> Self {
        var copy = self
        copy.autoScale = scale
        return copy
    }
    
    /// Sets the display mode for how the PDF pages are shown.
    ///
    /// The display mode determines how the pages of the PDF document are arranged and navigated.
    /// The available options for the `mode` parameter are:
    ///
    /// - `.singlePage`: Displays one page at a time, requiring the user to scroll or navigate to the next page.
    /// - `.singlePageContinuous`: Displays the pages continuously in a vertical scrolling manner, allowing for smooth scrolling through the document.
    /// - `.twoUp`: Displays two pages side by side, great for documents like magazines or books that are meant to be viewed in pairs.
    /// - `.twoUpContinuous`: Displays two pages side by side with continuous scrolling, allowing users to scroll through pages seamlessly in pairs.
    ///
    /// - Parameter mode: A `PDFDisplayMode` value determining how the pages are displayed.
    /// - Returns: A new instance of `PDFKitRepresentedView` with the updated mode.
    ///
    /// ### Example:
    /// ```swift
    /// myPDF
    ///     .displayMode(.twoUpContinuous)
    /// ```
    func displayMode(_ mode: PDFDisplayMode) -> Self {
        var copy = self
        copy.displayMode = mode
        return copy
    }
    
    /// Specifies and sets the scrolling direction for the PDF pages.
    ///
    /// This property determines how the pages of the PDF document are scrolled within the view.
    /// The scrolling direction can be customized based on the desired user experience.
    ///
    /// - Default: `.horizontal`
    ///
    /// - Possible values:
    ///   - `.horizontal`: Pages scroll from left to right (ideal for left-to-right languages).
    ///   - `.vertical`: Pages scroll from top to bottom (ideal for documents with a more natural top-to-bottom flow).
    ///
    /// - Parameter direction: A `PDFDisplayDirection` value that defines the scroll orientation.
    /// - Returns: A new instance of `PDFKitRepresentedView` with the updated direction.
    ///
    /// ### Example:
    /// ```swift
    /// myPDF
    ///     .displayDirection(.vertical)
    /// ```
    func displayDirection(_ direction: PDFDisplayDirection) -> Self {
        var copy = self
        copy.displayDirection = direction
        return copy
    }
}

#endif


