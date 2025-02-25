//
//  CachedSVGLoader.swift
//  AssetCacheKit
//
//  Created by mohsen on 2/25/25.
//
import SwiftUI
import Foundation

/// A structure that loads and caches SVG images asynchronously.
///
/// `CachedSVGLoader` fetches an SVG image from a URL and caches it for efficient reuse.
/// It conforms to `AssetLoader` and supports async/await for network operations.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CachedSVGLoader: AssetLoader, Equatable {
    
    /// The URL of the SVG image to be loaded.
    public let url: URL?
    
    /// Creates a `URLRequest` from the provided URL.
    private var urlRequest: URLRequest? {
        if let url {
            return URLRequest(url: url)
        }
        return nil
    }
    
    /// The URL session used for making network requests.
    private let urlSession: URLSession
    
    /// The cache used to store fetched images.
    private let urlCache: URLCache
    
    /// Loads the SVG asset asynchronously.
    ///
    /// - Returns: An `Image` representation of the loaded SVG.
    /// - Throws: `LoaderError.invalidURL` if the URL is invalid,
    ///           `LoaderError.invalidResponse` if the network request fails,
    ///           `LoaderError.invalidSVGData` if the image cannot be processed.
    public func loadAsset() async throws -> Image {
        
        guard let urlRequest = urlRequest else {
            throw LoaderError.invalidURL
        }

        // Check if image is already cached
        if let cachedImage = try cachedImage(from: urlRequest, cache: urlCache) {
            return cachedImage
        }

        // Fetch data from the network
        let (data, response) = try await urlSession.data(for: urlRequest)
       
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw LoaderError.invalidResponse
        }
       
        // Cache the downloaded data
        let cachedResponse = CachedURLResponse(response: httpResponse, data: data)
        urlCache.storeCachedResponse(cachedResponse, for: urlRequest)
        
        return try image(from: data)
    }
    
    /// Initializes the `CachedSVGLoader` with a URL and a URL cache.
    ///
    /// - Parameters:
    ///   - url: The URL of the SVG image.
    ///   - urlCache: The cache used for storing the downloaded image. Defaults to `.shared`.
    public init(url: URL?, urlCache: URLCache = .shared) {
        self.url = url
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = urlCache
        self.urlSession = URLSession(configuration: configuration)
        self.urlCache = urlCache
    }
    
    /// Retrieves a cached image from the URL cache.
    ///
    /// - Parameters:
    ///   - request: The URL request associated with the image.
    ///   - cache: The URL cache where images are stored.
    /// - Returns: The cached `Image` if available.
    private func cachedImage(from request: URLRequest, cache: URLCache) throws -> Image? {
        guard let cachedResponse = cache.cachedResponse(for: request) else { return nil }
        return try image(from: cachedResponse.data)
    }
    
    /// Converts raw SVG data into a SwiftUI `Image`.
    ///
    /// - Parameter data: The raw data of the SVG file.
    /// - Returns: A SwiftUI `Image` representation of the SVG.
    /// - Throws: `LoaderError.invalidSVGData` if the conversion fails.
    private func image(from data: Data) throws -> Image {
        guard let image = SVGKit(data)?.swiftUIImage() else { throw LoaderError.invalidSVGData }

        return image
    }
    
    /// Compares two `CachedSVGLoader` instances.
    ///
    /// - Parameters:
    ///   - lhs: The first instance.
    ///   - rhs: The second instance.
    /// - Returns: `true` if both instances have the same URL.
    public static func == (lhs: CachedSVGLoader, rhs: CachedSVGLoader) -> Bool {
        return lhs.url == rhs.url
    }

    /// Errors that may occur during asset loading.
    enum LoaderError: Error {
        
        /// The provided URL is invalid.
        case invalidURL
        
        /// The network response was invalid.
        case invalidResponse
        
        /// The SVG data could not be converted to an image.
        case invalidSVGData
    }
}
