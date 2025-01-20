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
public struct CachedPDFLoader: AssetLoader, Equatable {
    
    /// The URL of the PDF document to load.
    ///
    /// This property holds the URL to the PDF file that will be fetched, cached, and displayed. It must not be `nil`.
    public let url: URL?
    
    private var urlRequest: URLRequest? {
        if let url {
            return URLRequest(url: url)
        }
        return nil
    }
    
    private let urlSession: URLSession
    private let urlCache: URLCache

    /// Loads the PDF document asynchronously and returns a SwiftUI `View`.
    ///
    /// This method fetches the PDF document, either from the cache or the network, and returns a `PDFKitRepresentedView`
    /// that can be used in a SwiftUI view hierarchy to display the PDF content.
    ///
    /// - Returns: A SwiftUI `View` displaying the PDF content.
    /// - Throws: `LoaderError.invalidURL`, `LoaderError.invalidResponse`, or `LoaderError.invalidPDFData` if any issues occur.
    public func loadAsset() async throws -> PDFKitRepresentedView  {
        guard let urlRequest = urlRequest else {
            throw LoaderError.invalidURL
        }

       
        // Fetch PDF data asynchronously
        let pdfData = try await fetchPDFData(from: urlRequest)
    
        
        // Create a PDF view on the main thread
        return try await MainActor.run {
            guard let pdfDocument = PDFDocument(data: pdfData) else {
                throw LoaderError.invalidPDFData
            }
            return PDFKitRepresentedView(document: pdfDocument)
        }
    }
    
    /// Fetches the PDF data, either from cache or from the network.
    ///
    /// - Parameter url: The URL request for the PDF document.
    /// - Returns: The PDF data.
    /// - Throws: `LoaderError.invalidResponse` if the response is invalid or cannot be fetched.
    private func fetchPDFData(from url: URLRequest) async throws -> Data {
        
        // Check if the PDF is already cached
        if let cachedData = cachedPDFData(from: url, cache: urlCache) {
            return cachedData
        }

        // Fetch from the network if not cached
        let (data, response) = try await urlSession.data(for: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw LoaderError.invalidResponse
        }

        // Cache the response
        let cachedResponse = CachedURLResponse(response: httpResponse, data: data)
        urlCache.storeCachedResponse(cachedResponse, for: url)
        return data

        
    }

    /// Initializes a new `CachedPDFLoader` instance.
    ///
    /// - Parameters:
    ///   - url: The URL of the PDF document to load.
    ///   - urlCache: The cache to store downloaded PDFs. Defaults to `.shared`.
    public init(url: URL?, urlCache: URLCache = .shared) {
        self.url = url
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = urlCache
        self.urlSession = URLSession(configuration: configuration)
        self.urlCache = urlCache
    }

    /// Attempts to retrieve cached PDF data from the cache.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` associated with the PDF document.
    ///   - cache: The `URLCache` to search for the cached response.
    /// - Returns: The cached PDF data if it exists in the cache, otherwise `nil`.
    private func cachedPDFData(from request: URLRequest, cache: URLCache) -> Data? {
        guard let cachedResponse = cache.cachedResponse(for: request) else { return nil }
        print("Returning cached PDF data")
        return cachedResponse.data
    }

    /// Defines errors that can be thrown by `CachedPDFLoader`.
    public enum LoaderError: Error {
        case invalidURL
        case invalidResponse
        case invalidPDFData
    }
    
    /// Conformance to `Equatable` to compare two instances of `CachedPDFLoader`.
    ///
    /// - Parameters:
    ///   - lhs: The first `CachedPDFLoader` instance.
    ///   - rhs: The second `CachedPDFLoader` instance.
    /// - Returns: A boolean value indicating whether the two instances are equal.
    public static func == (lhs: CachedPDFLoader, rhs: CachedPDFLoader) -> Bool {
        return lhs.url == rhs.url
    }
}
