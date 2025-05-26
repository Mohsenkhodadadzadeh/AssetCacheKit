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
    public var url: URL?
    private let loadAssetUseCase: LoadAssetUseCase
    
     private let scale: CGFloat

    /// Initializes a new `CachedImageLoader` instance.
     public init(url: URL?, urlCache: URLCache = .shared, scale: CGFloat = 1) {
         self.url = url
         let configuration = URLSessionConfiguration.default
         configuration.urlCache = urlCache
         let urlSession = URLSession(configuration: configuration)
         let defaultRepository = DefaultAssetRepository(urlSession: urlSession, urlCache: urlCache)
         self.loadAssetUseCase = DefaultLoadAssetUseCase(repository: defaultRepository)
         self.scale = scale
     }
    
    
    internal init (url: URL?, loadAssetUseCase: LoadAssetUseCase, scale: CGFloat = 1) {
        self.url = url
        self.loadAssetUseCase = loadAssetUseCase
        self.scale = scale
    }
    
    /// Loads the image asynchronously.
    public func loadAsset() async throws -> Image {
        
        let data = try await loadAssetUseCase.execute(url: url)
        
         return try image(from: data)
        
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
         throw AppError.assetLoading(.invalidImageData)
     }
    

    nonisolated public static func == (lhs: CachedImageLoader, rhs: CachedImageLoader) -> Bool {
          return lhs.url == rhs.url && lhs.scale == rhs.scale
      }
    
}
