//
//  PDFKitRepresentedView.swift
//  AssetCacheKit
//
//  Created by mohsen on 1/20/25.
//

// PDFKit ships only on iOS and macOS — it does not exist on watchOS, and on
// tvOS it offers no `PDFView`.  Everything in this file is therefore gated to
// the two platforms that can actually render a PDF.
#if os(iOS) || os(macOS)

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
    
    /// The current page number in the displayed PDF document.
    ///
    /// This is a `Binding` that a data binding variable which allows track the current page as the user
    /// navigates through the PDF document.
    @Binding var currentPage: Int?
    
    /// The total number of pages in the displayed PDF document.
    ///
    /// This is a `Binding` that a data binding variable which allows track the total number of pages in the PDF
    /// document.
    @Binding var totalPages: Int?
    
    
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
        pdfView.delegate = context.coordinator
        context.coordinator.observePageChanges(for: pdfView)
        if let totalPages = pdfView.document?.pageCount {
            DispatchQueue.main.async {
                self.totalPages = totalPages
            }
        }
       
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
        // Reassigning `document` reloads the view and snaps it back to page one.
        // SwiftUI calls this on every state change, so only swap when the
        // document has actually changed — otherwise the reader jumps to the
        // start whenever anything else in the hierarchy updates.
        if pdfView.document !== document {
            pdfView.document = document
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(currentPage: $currentPage)
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
    public func autoScale(_ scale: Bool) -> Self {
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
    public func displayMode(_ mode: PDFDisplayMode) -> Self {
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
    public func displayDirection(_ direction: PDFDisplayDirection) -> Self {
        var copy = self
        copy.displayDirection = direction
        return copy
    }
    
    /// Updates the `totalPages` binding to track the total number of pages in the PDF document.
    ///
    /// - Parameter totalPages: A binding to an `Int?` that will be updated with the total number of pages.
    /// - Returns: A modified `PDFKitRepresentedView` instance with the updated binding.
    public func totalPage(_ totalPages: Binding<Int?>) -> Self {
        var copy = self
        copy._totalPages = totalPages
        return copy
    }

    /// Updates the `currentPage` binding to track the current page number in the PDF document.
    ///
    /// - Parameter currentPage: A binding to an `Int?` that will be updated with the current page number.
    /// - Returns: A modified `PDFKitRepresentedView` instance with the updated binding.
    public func currentPage(_ currentPage: Binding<Int?>) -> Self {
        var copy = self
        copy._currentPage = currentPage
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
    
    /// The current page number in the displayed PDF document.
    ///
    /// This is a `Binding` that a data binding variable which allows track the current page as the user
    /// navigates through the PDF document.
    @Binding var currentPage: Int?
    
    /// The total number of pages in the displayed PDF document.
    ///
    /// This is a `Binding` that a data binding variable which allows track the total number of pages in the PDF
    /// document.
    @Binding var totalPages: Int?
    
    
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
        pdfView.delegate = context.coordinator
        context.coordinator.observePageChanges(for: pdfView)
        if let totalPages = pdfView.document?.pageCount {
            DispatchQueue.main.async {
                self.totalPages = totalPages
            }
        }
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
        // Reassigning `document` reloads the view and snaps it back to page one.
        // SwiftUI calls this on every state change, so only swap when the
        // document has actually changed — otherwise the reader jumps to the
        // start whenever anything else in the hierarchy updates.
        if pdfView.document !== document {
            pdfView.document = document
        }
    }
    
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(currentPage: $currentPage)
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
    public func autoScale(_ scale: Bool) -> Self {
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
    public func displayMode(_ mode: PDFDisplayMode) -> Self {
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
    public func displayDirection(_ direction: PDFDisplayDirection) -> Self {
        var copy = self
        copy.displayDirection = direction
        return copy
    }
    
    /// Updates the `totalPages` binding to track the total number of pages in the PDF document.
    ///
    /// - Parameter totalPages: A binding to an `Int?` that will be updated with the total number of pages.
    /// - Returns: A modified `PDFKitRepresentedView` instance with the updated binding.
    public func totalPage(_ totalPages: Binding<Int?>) -> Self {
        var copy = self
        copy._totalPages = totalPages
        return copy
    }

    /// Updates the `currentPage` binding to track the current page number in the PDF document.
    ///
    /// - Parameter currentPage: A binding to an `Int?` that will be updated with the current page number.
    /// - Returns: A modified `PDFKitRepresentedView` instance with the updated binding.
    public func currentPage(_ currentPage: Binding<Int?>) -> Self {
        var copy = self
        copy._currentPage = currentPage
        return copy
    }
    
}

#endif

/// A coordinator class responsible for observing page changes in a `PDFView` and updating the current page binding.
///
/// `Coordinator` listens for page change notifications and updates the `currentPage` binding accordingly.
///
/// The type is `@MainActor`-isolated because every value it touches — the
/// `PDFView`, its document, and the SwiftUI binding — is main-actor state.
@MainActor
public final class Coordinator: NSObject, PDFViewDelegate {

    /// A binding to the current page number in the PDF document.
    ///
    /// This binding is updated when the page changes in the associated `PDFView`.
    @Binding var currentPage: Int?

    /// The opaque token returned when registering the block-based observer.
    ///
    /// `removeObserver(_:name:object:)` only unregisters *selector*-based
    /// observers; block-based ones must be removed with `removeObserver(_:)`
    /// using this token, otherwise `NotificationCenter` retains the block —
    /// and the `PDFView` it references — for the lifetime of the process.
    ///
    /// `nonisolated(unsafe)` is required so `deinit` (which is never
    /// actor-isolated) can read it.  The property is only ever written from
    /// the main actor, and `NotificationCenter` is itself thread-safe.
    private nonisolated(unsafe) var pageChangeObserver: (any NSObjectProtocol)?

    /// The `PDFView` currently being observed.
    ///
    /// Held weakly so the coordinator never keeps a torn-down view alive, and
    /// read inside the notification block instead of unwrapping the (non-
    /// `Sendable`) `Notification` payload.
    private weak var observedPDFView: PDFView?

    /// Initializes a new `Coordinator` instance.
    ///
    /// - Parameter currentPage: A binding to an `Int?` representing the current page number.
    init(currentPage: Binding<Int?>) {
        self._currentPage = currentPage
    }

    /// Observes page change events in the specified `PDFView` and updates the `currentPage` binding.
    ///
    /// Calling this more than once replaces the previous registration rather
    /// than stacking a second one.
    ///
    /// - Parameter pdfView: The `PDFView` to observe for page changes.
    func observePageChanges(for pdfView: PDFView) {
        removePageChangeObserver()
        observedPDFView = pdfView

        pageChangeObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name.PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { [weak self] _ in
            // The observer is registered on `.main`, so the block already runs
            // on the main thread; `assumeIsolated` records that for the compiler
            // without an extra async hop that would drop frames while scrolling.
            MainActor.assumeIsolated {
                self?.synchronizeCurrentPage()
            }
        }
    }

    /// Reads the observed view's current page and pushes it into the binding.
    private func synchronizeCurrentPage() {
        guard let pdfView = observedPDFView,
              let page = pdfView.currentPage,
              let pageIndex = pdfView.document?.index(for: page)
        else { return }

        let pageNumber = pageIndex + 1
        // Avoid redundant binding writes, which would invalidate the SwiftUI
        // view on every scroll tick even when the page has not changed.
        guard currentPage != pageNumber else { return }
        currentPage = pageNumber
    }

    private nonisolated func removePageChangeObserver() {
        guard let pageChangeObserver else { return }
        NotificationCenter.default.removeObserver(pageChangeObserver)
        self.pageChangeObserver = nil
    }

    /// Cleans up the notification observer when the `Coordinator` is deallocated.
    deinit {
        removePageChangeObserver()
    }
}

#endif  // os(iOS) || os(macOS)


