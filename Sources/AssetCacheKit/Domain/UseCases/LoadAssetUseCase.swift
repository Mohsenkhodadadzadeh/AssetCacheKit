//
//  LoadAssetUseCase.swift
//  AssetCacheKit
//
//  Created by mohsen on 5/23/25.
//

import Foundation

// MARK: - Protocol

/// Encapsulates the business logic for loading a single asset.
///
/// The use-case layer sits between the presentation layer (`AssetLoader` conformances)
/// and the data layer (`AssetRepository` conformances), keeping each layer
/// independently testable and open for extension.
///
/// The framework ships with ``DefaultLoadAssetUseCase``, which delegates directly
/// to an ``AssetRepository``.  You can provide a custom implementation to add
/// cross-cutting concerns such as logging, analytics, or data transformation
/// without modifying either the loaders or the repositories.
///
/// ## Injecting a custom use case in tests
///
/// ```swift
/// struct LoggingLoadAssetUseCase: LoadAssetUseCase {
///     private let inner: LoadAssetUseCase
///
///     func execute(url: URL?) async throws -> Data {
///         print("Loading asset:", url?.absoluteString ?? "nil")
///         let data = try await inner.execute(url: url)
///         print("Loaded \(data.count) bytes")
///         return data
///     }
/// }
///
/// let loader = CachedPDFLoader(
///     url: url,
///     loadAssetUseCase: LoggingLoadAssetUseCase(inner: DefaultLoadAssetUseCase(
///         repository: DefaultAssetRepository()
///     ))
/// )
/// ```
internal protocol LoadAssetUseCase: Sendable {

    /// Executes the asset-loading operation for the given URL.
    ///
    /// - Parameter url: The remote location of the asset.
    /// - Returns: The raw asset bytes.
    /// - Throws: An ``AppError`` describing the failure.
    func execute(url: URL?) async throws -> Data
}

// MARK: - Default Implementation

/// The default ``LoadAssetUseCase`` implementation.
///
/// Delegates every request directly to the injected ``AssetRepository`` without
/// adding additional business logic.  This keeps the use-case layer lightweight
/// while still allowing callers to swap the repository — for example, to inject
/// a mock in unit tests.
internal final class DefaultLoadAssetUseCase: LoadAssetUseCase {

    // MARK: Private State

    private let repository: AssetRepository

    // MARK: Init

    /// Creates a use case backed by the given repository.
    ///
    /// - Parameter repository: The data source responsible for fetching
    ///   and caching raw asset bytes.
    internal init(repository: AssetRepository) {
        self.repository = repository
    }

    // MARK: LoadAssetUseCase

    internal func execute(url: URL?) async throws -> Data {
        try await repository.loadAsset(with: url)
    }
}
