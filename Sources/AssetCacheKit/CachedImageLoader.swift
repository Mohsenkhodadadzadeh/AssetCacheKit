//
//  CachedImageLoader.swift
//  AssetCacheKit
//
//  Created by mohsen on 12/27/24.
//
import SwiftUI

/// An `AssetLoader` implementation that loads and caches images from URLs.
///
/// `CachedImageLoader` uses `URLSession` and `URLCache` to efficiently load and cache images. It handles HTTP responses and data conversion to `Image` objects.
///
/// ## Initialization
///
/// You initialize `CachedImageLoader` with a URL:
///
/// ```swift
/// let imageLoader = CachedImageLoader(url: URL(string: "https://example.com/image.png")!)
/// ```
///
/// ## Related Frameworks
///
/// - `SwiftUI`: For image display.
/// - `Foundation`: For networking (`URLSession`, `URLCache`) and data handling.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CachedImageLoader: AssetLoader, Equatable {
    
    /// The URL of the image to be loaded.
    public let url: URL?
    
    private var urlRequest: URLRequest? {
        if let url {
            return URLRequest(url: url)
        }
        return nil
    }
     private let urlSession: URLSession
     private let urlCache: URLCache
     private let scale: CGFloat

    /// Loads the image asynchronously.
    public func loadAsset() async throws -> Image {
         guard let urlRequest = urlRequest else {
             throw LoaderError.invalidURL
         }

         if let cachedImage = try cachedImage(from: urlRequest, cache: urlCache) {
             return cachedImage
         }

         let (data, response) = try await urlSession.data(for: urlRequest)

         guard let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) else {
             throw LoaderError.invalidResponse
         }

         if let cachedResponse = CachedURLResponse(response: httpResponse, data: data) as? CachedURLResponse {
             urlCache.storeCachedResponse(cachedResponse, for: urlRequest)
         }
         print("return from network")
         return try image(from: data)
     }

    /// Initializes a new `CachedImageLoader` instance.
     public init(url: URL?, urlCache: URLCache = .shared, scale: CGFloat = 1) {
         self.url = url
         let configuration = URLSessionConfiguration.default
         configuration.urlCache = urlCache
         self.urlSession = URLSession(configuration: configuration)
         self.urlCache = urlCache
         self.scale = scale
     }

     private func cachedImage(from request: URLRequest, cache: URLCache) throws -> Image? {
         guard let cachedResponse = cache.cachedResponse(for: request) else { return nil }
         print("return from cache")
         return try image(from: cachedResponse.data)
     }

     private func image(from data: Data) throws -> Image {
 #if os(macOS)
         if let nsImage = NSImage(data: data) {
             return Image(nsImage: nsImage)
         }
 #else
         if let uiImage = UIImage(data: data) {
             return Image(uiImage: uiImage)
         }
 #endif
         throw LoaderError.invalidImageData
     }
    
    public static func == (lhs: CachedImageLoader, rhs: CachedImageLoader) -> Bool {
          return lhs.url == rhs.url && lhs.scale == rhs.scale
      }

    /// Errors that can be thrown by `CachedImageLoader`.
     enum LoaderError: Error {
         
         /// The provided URL was invalid.
         case invalidURL
         
         /// The server returned an invalid response (non-2xx status code).
         case invalidResponse
         
         /// The received data could not be converted to an image.
         case invalidImageData
     }
}
