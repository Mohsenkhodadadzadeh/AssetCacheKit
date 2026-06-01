//
//  DefaultAssetRepository.swift
//  AssetCacheKit
//
//  Created by mohsen on 5/23/25.
//

import Foundation

/// The default ``AssetRepository`` implementation.
///
/// `DefaultAssetRepository` is a thin adapter between the ``LoadAssetUseCase``
/// layer and ``AssetCache``.  All caching logic — memory, disk, request
/// deduplication, LRU eviction, expiration, and retry — lives in ``AssetCache``;
/// this class only translates between the repository protocol and the cache API.
///
/// Using a shared ``AssetCache`` means that all loaders — images, PDFs, SVGs,
/// and any future asset type — share the same disk namespace and deduplication
/// table.  A PDF and an image that happen to reference the same URL will
/// correctly share a single cached copy.
///
/// `DefaultAssetRepository` is `internal` and not part of the public API.
internal final class DefaultAssetRepository: AssetRepository {

    // MARK: - Private State

    private let cache: AssetCache

    // MARK: - Init

    /// Creates a repository backed by the given ``AssetCache``.
    ///
    /// - Parameter cache: The asset cache to use. Defaults to ``AssetCache/shared``.
    init(cache: AssetCache = .shared) {
        self.cache = cache
    }

    // MARK: - AssetRepository

    /// Loads raw asset data by delegating to the underlying ``AssetCache``.
    ///
    /// - Parameter url: The remote location of the asset.
    /// - Returns: The raw (compressed) asset bytes.
    /// - Throws: ``AppError/assetLoading(.invalidURL)`` when `url` is `nil`,
    ///   or a ``AppError/network(_:)`` error after all retry attempts fail.
    func loadAsset(with url: URL?) async throws -> Data {
        guard let url else {
            throw AppError.assetLoading(.invalidURL)
        }
        return try await cache.data(for: url)
    }
}
