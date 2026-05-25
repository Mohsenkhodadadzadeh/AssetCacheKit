//
//  CachedSVGLoader.swift
//  AssetCacheKit
//
//  Created by mohsen on 2/25/25.
//
import SwiftUI

/// An ``AssetLoader`` that loads and caches remote SVG images.
///
/// `CachedSVGLoader` fetches raw SVG bytes through the shared ``AssetCache``,
/// which provides memory caching, disk persistence, request deduplication, LRU
/// eviction, and configurable retry automatically.  The raw bytes are converted
/// to a SwiftUI `Image` by the internal ``SVGKit`` renderer.
///
/// ## Usage
///
/// ```swift
/// AssetCacheKit(
///     loader: CachedSVGLoader(url: url),
///     content: { image in image.resizable().scaledToFit() },
///     placeholder: { ProgressView() },
///     error: { error in Text(error.localizedDescription) }
/// )
/// ```
///
/// ## Testing
///
/// Inject a mock ``LoadAssetUseCase`` through the `internal` initialiser to
/// test loader behaviour without network access:
///
/// ```swift
/// let loader = CachedSVGLoader(
///     url: url,
///     loadAssetUseCase: MockLoadAssetUseCase(data: svgData)
/// )
/// ```
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CachedSVGLoader: AssetLoader, Equatable {

    // MARK: - Public Properties

    public var url: URL?

    // MARK: - Private State

    private let loadAssetUseCase: LoadAssetUseCase

    // MARK: - Init

    /// Creates an SVG loader backed by the shared ``AssetCache``.
    ///
    /// - Parameter url: The remote location of the SVG file.
    public init(url: URL?) {
        self.url              = url
        self.loadAssetUseCase = DefaultLoadAssetUseCase(
            repository: DefaultAssetRepository()
        )
    }

    /// Creates an SVG loader with an injected use case.
    ///
    /// Use this initialiser in unit tests to provide a mock ``LoadAssetUseCase``
    /// that returns fixture data without making network requests.
    ///
    /// - Parameters:
    ///   - url: The remote location of the SVG file.
    ///   - loadAssetUseCase: The use case responsible for fetching raw bytes.
    internal init(url: URL?, loadAssetUseCase: LoadAssetUseCase) {
        self.url              = url
        self.loadAssetUseCase = loadAssetUseCase
    }

    // MARK: - AssetLoader

    /// Loads the remote SVG and returns a SwiftUI `Image`.
    ///
    /// Raw bytes are fetched via the injected use case (backed by ``AssetCache``
    /// by default) and converted to an `Image` by ``SVGKit``.
    ///
    /// - Returns: A SwiftUI `Image` rendered from the SVG source.
    /// - Throws: ``AppError/assetLoading(.invalidURL)`` when ``url`` is `nil`,
    ///   ``AppError/assetLoading(.invalidSVGData)`` if the bytes cannot be parsed
    ///   as SVG, or ``AppError/network(_:)`` on a network failure.
    public func loadAsset() async throws -> Image {
        let data = try await loadAssetUseCase.execute(url: url)
        return try svgImage(from: data)
    }

    // MARK: - Equatable

    public static func == (lhs: CachedSVGLoader, rhs: CachedSVGLoader) -> Bool {
        lhs.url == rhs.url
    }

    // MARK: - Private

    private func svgImage(from data: Data) throws -> Image {
        guard let image = SVGKit(data)?.swiftUIImage() else {
            throw AppError.assetLoading(.invalidSVGData)
        }
        return image
    }
}
