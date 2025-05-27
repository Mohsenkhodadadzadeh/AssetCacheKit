//
//  LoadAssetUseCase.swift
//  AssetCacheKit
//
//  Created by mohsen on 5/23/25.
//

import Foundation

/// A protocol that defines the contract for loading assets from a data source.
/// This use case encapsulates the business logic for retrieving assets, abstracting away
/// the underlying data source implementation details.
///
/// Example usage:
/// ```swift
/// let useCase: LoadAssetUseCase = DefaultLoadAssetUseCase(repository: repository)
/// let imageData = try await useCase.execute(url: imageURL)
/// ```
internal protocol LoadAssetUseCase: Sendable {
    
    /// Executes the asset loading operation.
    /// - Parameter url: The URL of the asset to load. Can be nil, in which case an error will be thrown.
    /// - Returns: The loaded asset data
    /// - Throws: An error if the asset loading fails
    func execute(url: URL?) async throws -> Data
}

/// Default implementation of the LoadAssetUseCase that uses an AssetRepository
/// to handle the actual asset loading.
///
/// This implementation:
/// - Delegates the loading operation to the provided repository
/// - Maintains a clean separation between use case and data layer
/// - Ensures thread safety through Sendable conformance
internal final class DefaultLoadAssetUseCase: LoadAssetUseCase {
    
    /// The repository responsible for actual asset loading and caching
    private let repository: AssetRepository
    
    /// Creates a new DefaultLoadAssetUseCase instance.
    /// - Parameter repository: The repository to use for loading assets.
    ///                        This repository will handle both network requests and caching.
    internal init(repository: AssetRepository) {
        self.repository = repository
    }
    
    /// Executes the asset loading operation by delegating to the repository.
    /// - Parameter url: The URL of the asset to load
    /// - Returns: The loaded asset data
    /// - Throws: An error if the asset loading fails
    internal func execute(url: URL?) async throws -> Data {
        try await repository.loadAsset(with: url)
    }
}
