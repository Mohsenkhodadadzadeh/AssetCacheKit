//
//  AssetRepository.swift
//  AssetCacheKit
//
//  Created by mohsen on 5/23/25.
//

import Foundation

/// A protocol that defines the contract for managing asset data storage and retrieval.
/// This repository handles both network loading and caching of assets such as images, PDFs, and SVGs.
///
/// The repository provides methods to:
/// - Load assets from network or cache
/// - Fetch cached assets
/// - Cache new assets
/// - Clear cached assets
///
/// Example usage:
/// ```swift
/// let repository: AssetRepository = DefaultAssetRepository()
/// let data = try await repository.loadAsset(with: imageURL)
/// ```
internal protocol AssetRepository: Sendable {
    
    /// Loads an asset from either the cache or network.
    /// - Parameter url: The URL of the asset to load. Can be nil, in which case an error will be thrown.
    /// - Returns: The loaded asset data
    /// - Throws: An `AppError` if the loading fails due to network issues, invalid URL, or server errors.
    func loadAsset(with url: URL?) async throws -> Data
    
    /// Retrieves a cached asset from storage if available.
    /// - Parameter urlRequest: The URLRequest associated with the asset
    /// - Returns: The cached data if available, nil otherwise
    func fetchCachedAsset(for urlRequest: URLRequest) -> Data?
    
    /// Stores an asset in the cache for future retrieval.
    /// - Parameters:
    ///   - response: The HTTP response containing metadata about the asset
    ///   - data: The asset data to be cached
    ///   - urlRequest: The URLRequest associated with the asset
    func cacheAsset(response: HTTPURLResponse, data: Data, for urlRequest: URLRequest)
    
    /// Removes a specific asset from the cache.
    /// - Parameter urlRequest: The URLRequest associated with the asset to be removed
    func clearCache(for urlRequest: URLRequest)
}
