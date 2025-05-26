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
public struct CachedSVGLoader: AssetLoader {
    
    /// The URL of the SVG image to be loaded.
    public var url: URL?
    
    private let loadAssetUseCase: LoadAssetUseCase

    /// Initializes the `CachedSVGLoader` with a URL and a URL cache.
    ///
    /// - Parameters:
    ///   - url: The URL of the SVG image.
    ///   - urlCache: The cache used for storing the downloaded image. Defaults to `.shared`.
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
    
    /// Loads the SVG asset asynchronously.
    ///
    /// - Returns: An `Image` representation of the loaded SVG.
    /// - Throws: `LoaderError.invalidURL` if the URL is invalid,
    ///           `LoaderError.invalidResponse` if the network request fails,
    ///           `LoaderError.invalidSVGData` if the image cannot be processed.
    public func loadAsset() async throws -> Image {
       let svgData = try await loadAssetUseCase.execute(url: url)
        return try dataTosvgImage(from: svgData)
    }
    
    /// Converts raw SVG data into a SwiftUI `Image`.
    ///
    /// - Parameter data: The raw data of the SVG file.
    /// - Returns: A SwiftUI `Image` representation of the SVG.
    /// - Throws: `LoaderError.invalidSVGData` if the conversion fails.
    private func dataTosvgImage(from data: Data) throws -> Image {
        guard let image = SVGKit(data)?.swiftUIImage() else { throw AppError.assetLoading(.invalidSVGData) }
        return image
    }
}
