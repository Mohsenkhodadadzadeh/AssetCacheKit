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
        pdfView.document = document
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
        pdfView.document = document
    }
}

#endif


