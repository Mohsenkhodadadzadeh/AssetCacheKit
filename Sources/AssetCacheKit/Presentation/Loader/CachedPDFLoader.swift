//
//  CachedPDFLoader.swift
//  AssetCacheKit
//
//  Created by mohsen on 1/20/25.
//
// Matches the availability of ``PDFKitRepresentedView``: PDFKit is absent on
// watchOS and has no `PDFView` on tvOS, so the loader ships on iOS/macOS only.
#if os(iOS) || os(macOS)

import PDFKit
import SwiftUI

/// An ``AssetLoader`` that loads and caches remote PDF documents.
///
/// `CachedPDFLoader` fetches raw PDF bytes through the shared ``AssetCache``,
/// which provides memory caching, disk persistence, request deduplication, LRU
/// eviction, and configurable retry automatically.  The raw bytes are decoded
/// into a `PDFDocument` on the main actor and wrapped in a ``PDFKitRepresentedView``
/// ready for display inside an ``AssetCacheKit`` view.
///
/// ## Usage
///
/// ```swift
/// AssetCacheKit(
///     loader: CachedPDFLoader(url: url),
///     content: { pdfView in pdfView },
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
/// let loader = CachedPDFLoader(
///     url: url,
///     loadAssetUseCase: MockLoadAssetUseCase(data: pdfData)
/// )
/// ```
@available(iOS 15.0, macOS 12.0, *)
public struct CachedPDFLoader: AssetLoader, Equatable {

    // MARK: - Public Properties

    public var url: URL?

    // MARK: - Private State

    private let loadAssetUseCase: LoadAssetUseCase

    // MARK: - Init

    /// Creates a PDF loader backed by the shared ``AssetCache``.
    ///
    /// - Parameter url: The remote location of the PDF document.
    public init(url: URL?) {
        self.url              = url
        self.loadAssetUseCase = DefaultLoadAssetUseCase(
            repository: DefaultAssetRepository()
        )
    }

    /// Creates a PDF loader with an injected use case.
    ///
    /// Use this initialiser in unit tests to provide a mock ``LoadAssetUseCase``
    /// that returns fixture data without making network requests.
    ///
    /// - Parameters:
    ///   - url: The remote location of the PDF document.
    ///   - loadAssetUseCase: The use case responsible for fetching raw bytes.
    internal init(url: URL?, loadAssetUseCase: LoadAssetUseCase) {
        self.url              = url
        self.loadAssetUseCase = loadAssetUseCase
    }

    // MARK: - AssetLoader

    /// Loads the remote PDF and returns a view ready for display.
    ///
    /// Raw bytes are fetched via the injected use case (backed by ``AssetCache``
    /// by default) and decoded into a `PDFDocument` on the main actor.
    ///
    /// - Returns: A ``PDFKitRepresentedView`` wrapping the decoded document.
    /// - Throws: ``AppError/assetLoading(.invalidURL)`` when ``url`` is `nil`,
    ///   ``AppError/assetLoading(.invalidPDFData)`` if the bytes cannot be parsed
    ///   as a PDF, or ``AppError/network(_:)`` on a network failure.
    public func loadAsset() async throws -> PDFKitRepresentedView {
        let data = try await loadAssetUseCase.execute(url: url)

        return try await MainActor.run {
            guard let document = PDFDocument(data: data) else {
                throw AppError.assetLoading(.invalidPDFData)
            }
            return PDFKitRepresentedView(
                document: document,
                currentPage: .constant(nil),
                totalPages: .constant(nil)
            )
        }
    }

    // MARK: - Equatable

    public static func == (lhs: CachedPDFLoader, rhs: CachedPDFLoader) -> Bool {
        lhs.url == rhs.url
    }
}

#endif  // os(iOS) || os(macOS)
