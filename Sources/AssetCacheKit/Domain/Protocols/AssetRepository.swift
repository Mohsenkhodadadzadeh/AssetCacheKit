//
//  AssetRepository.swift
//  AssetCacheKit
//
//  Created by mohsen on 5/23/25.
//

import Foundation

/// Defines the contract for loading raw asset data from any source.
///
/// Conforming types are responsible for returning the raw bytes of an asset
/// located at a given URL.  The caching strategy, eviction policy, and network
/// behaviour are implementation details left to each conforming type.
///
/// The framework ships with ``DefaultAssetRepository``, which delegates to the
/// shared ``AssetCache`` to provide memory caching, disk persistence, request
/// deduplication, LRU eviction, and configurable retry out of the box.
///
/// ## Implementing a custom repository
///
/// Provide a custom conformance when you need to load assets from a non-standard
/// source — for example, a local bundle, an encrypted store, or a mock for testing.
///
/// ```swift
/// struct BundleAssetRepository: AssetRepository {
///     func loadAsset(with url: URL?) async throws -> Data {
///         guard let url,
///               let name = url.pathComponents.last,
///               let fileURL = Bundle.main.url(forResource: name, withExtension: nil)
///         else { throw AppError.assetLoading(.invalidURL) }
///         return try Data(contentsOf: fileURL)
///     }
/// }
/// ```
///
/// Inject your implementation through the loader's `internal` initialiser in tests:
///
/// ```swift
/// let loader = CachedPDFLoader(
///     url: url,
///     loadAssetUseCase: DefaultLoadAssetUseCase(repository: BundleAssetRepository())
/// )
/// ```
internal protocol AssetRepository: Sendable {

    /// Loads raw asset data for the given URL.
    ///
    /// Implementations should check local caches before making a network
    /// request, and persist the result for future calls where applicable.
    ///
    /// - Parameter url: The remote location of the asset.  May be `nil` if the
    ///   caller has not yet set a URL; implementations should throw
    ///   ``AppError/assetLoading(_:)`` with `.invalidURL` in that case.
    /// - Returns: The raw (compressed) asset bytes.
    /// - Throws: An ``AppError`` describing the failure.
    func loadAsset(with url: URL?) async throws -> Data
}
