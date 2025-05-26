//
//  CachedPDFLoader.swift
//  AssetCacheKit
//
//  Created by mohsen on 1/20/25.
//
import PDFKit
import SwiftUI

/// A utility for loading and caching PDF documents from URLs, conforming to the `AssetLoader` protocol.
///
/// `CachedPDFLoader` uses `URLSession` and `URLCache` to efficiently load and cache PDF documents. It provides a SwiftUI
/// `View` for displaying the PDF content, while handling errors and caching for optimal performance.
///
/// ## Overview
///
/// `CachedPDFLoader` is an implementation of the `AssetLoader` protocol that loads PDF documents from the provided URL.
/// It handles caching to minimize redundant network requests and provide a seamless experience for displaying PDF files.
/// The loader fetches the PDF data either from the cache (if available) or from the network, then provides a SwiftUI view
/// for rendering the PDF document using `PDFKitRepresentedView`.
///
/// ## Features
/// - Loads and displays PDF documents using `PDFKitRepresentedView`.
/// - Caches PDF documents for efficient reuse, reducing network usage.
/// - Handles network requests and caches responses via `URLSession` and `URLCache`.
/// - Provides error handling for invalid URLs, responses, and PDF data.
///
/// ## Example Usage
///
/// ```swift
/// AssetCacheKit(loader: CachedPDFLoader(url: URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"))) { pdf in
///     pdf
/// } placeholder: {
///     Text("Loading...")
/// } error: { err in
///     Text("error is : \(err)")
/// }

/// ```
///
/// ## Requirements
/// - iOS 15.0+
/// - macOS 12.0+
/// - Requires the `PDFKit` framework to display PDF content.
///
/// ## API
@available(iOS 15.0, macOS 12.0, *)
public struct CachedPDFLoader: AssetLoader {
    
    /// The URL of the PDF document to load.
    ///
    /// This property holds the URL to the PDF file that will be fetched, cached, and displayed. It must not be `nil`.
    public var url: URL?
    private let loadAssetUseCase: LoadAssetUseCase
   
    
    
    /// Initializes a new `CachedPDFLoader` instance.
    ///
    /// - Parameters:
    ///   - url: The URL of the PDF document to load.
    ///   - urlCache: The cache to store downloaded PDFs. Defaults to `.shared`.
    public init(url: URL?, urlCache: URLCache = .shared) {
        self.url = url
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = urlCache
        let urlSession = URLSession(configuration: configuration)
        let defaultAssetRepository = DefaultAssetRepository(urlSession: urlSession, urlCache: urlCache)
        self.loadAssetUseCase = DefaultLoadAssetUseCase(repository: defaultAssetRepository)
        
    }
    
    internal init(url: URL?, loadAssetUseCase: LoadAssetUseCase) {
        self.url = url
        self.loadAssetUseCase = loadAssetUseCase
    }
    
    /// Loads the PDF document asynchronously and returns a SwiftUI `View`.
    ///
    /// This method fetches the PDF document, either from the cache or the network, and returns a `PDFKitRepresentedView`
    /// that can be used in a SwiftUI view hierarchy to display the PDF content.
    ///
    /// - Returns: A SwiftUI `View` displaying the PDF content.
    /// - Throws: `LoaderError.invalidURL`, `LoaderError.invalidResponse`, or `LoaderError.invalidPDFData` if any issues occur.
    public func loadAsset() async throws -> PDFKitRepresentedView  {
        
       
        // Fetch PDF data asynchronously
        let pdfData = try await loadAssetUseCase.execute(url: url)
    
        
        // Create a PDF view on the main thread
        return try await MainActor.run {
            guard let pdfDocument = PDFDocument(data: pdfData) else {
                throw AppError.assetLoading(.invalidPDFData)
            }
            return PDFKitRepresentedView(document: pdfDocument, currentPage: .constant(nil), totalPages: .constant(nil))
        }
    }
}
