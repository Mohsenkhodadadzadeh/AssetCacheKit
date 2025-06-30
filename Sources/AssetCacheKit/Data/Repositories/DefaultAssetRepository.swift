//
//  DefaultAssetRepository.swift
//  AssetCacheKit
//
//  Created by mohsen on 5/23/25.
//

import Foundation

/// Default implementation of `AssetRepository` that handles both network requests and caching.
///
/// This repository uses `URLSession` for network operations and `URLCache` for caching,
/// providing efficient asset loading with built-in caching capabilities.
///
/// Features:
/// - Automatic caching of downloaded assets
/// - Network error handling with specific error cases
/// - Thread-safe operations
/// - Memory-efficient caching
///
/// Example usage:
/// ```swift
/// let repository = DefaultAssetRepository(
///     urlSession: .shared,
///     urlCache: .shared
/// )
/// let data = try await repository.loadAsset(with: imageURL)
/// ```
internal final class DefaultAssetRepository: AssetRepository {

    /// The URLSession instance used for network requests
    private let urlSession: URLSession
    /// The URLCache instance used for caching responses
    private let urlCache: URLCache
    
    /// Creates a new DefaultAssetRepository instance.
    /// - Parameters:
    ///   - urlSession: The URLSession to use for network requests
    ///   - urlCache: The URLCache to use for caching responses
    /// The initializer configures the URLSession with the provided cache.
    init(urlSession: URLSession, urlCache: URLCache) {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = urlCache
        self.urlSession = URLSession(configuration: configuration)
        self.urlCache = urlCache
    }
    
    /// Loads an asset either from cache or network.
    /// - Parameter url: The URL of the asset to load
    /// - Returns: The loaded asset data
    /// - Throws: An `AppError` containing specific error information:
    ///   - `.assetLoading`: For asset-specific errors like invalid URLs
    ///   - `.network`: For various network-related errors with specific cases
    func loadAsset(with url: URL?) async throws -> Data {
        guard let url else {
            throw AppError.assetLoading(.invalidURL)
        }

        let urlRequest = URLRequest(url: url)
        
        if let cachedData = fetchCachedAsset(for: urlRequest) {
            return cachedData
        }
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.assetLoading(.invalidResponse)
        }
        
        switch httpResponse.statusCode {
        case 200..<300: break
        case -1009:     throw AppError.network(.noConnection)
        case -1001:     throw AppError.network(.timeout)
        case -1003:     throw AppError.network(.cannotFindHost)
        case -1004:     throw AppError.network(.cannotConnectToHost)
        case -1000:     throw AppError.network(.badURL)
        case -999:      throw AppError.network(.cancelled)
        case -1005:     throw AppError.network(.networkConnectionLost)
        case -1006:     throw AppError.network(.dnsLookupFailed)
        case -1200:     throw AppError.network(.secureConnectionFailed)
        case -1012:     throw AppError.network(.userCancelledAuthentication)
        case -1022:     throw AppError.network(.appTransportSecurityRequiresSecureConnection)
        default:        throw AppError.network(.badServerResponse(statusCode: httpResponse.statusCode))
        }
        
        cacheAsset(response: httpResponse, data: data, for: urlRequest)
        return data
    }
    
    /// Retrieves an asset from the cache if available.
    /// - Parameter urlRequest: The URLRequest to look up in the cache
    /// - Returns: The cached data if available, nil otherwise
    func fetchCachedAsset(for urlRequest: URLRequest) -> Data? {
        guard let cachedResponse = urlCache.cachedResponse(for: urlRequest) else {
            return nil
        }
        return cachedResponse.data
    }
    
    /// Stores an asset response in the cache.
    /// - Parameters:
    ///   - response: The HTTP response to cache
    ///   - data: The asset data to cache
    ///   - urlRequest: The URLRequest associated with the response
    func cacheAsset(response: HTTPURLResponse, data: Data, for urlRequest: URLRequest) {
        let cacheResponse = CachedURLResponse(response: response, data: data)
        urlCache.storeCachedResponse(cacheResponse, for: urlRequest)
    }
    
    /// Removes a specific asset from the cache.
    /// - Parameter urlRequest: The URLRequest whose cached response should be removed
    func clearCache(for urlRequest: URLRequest) {
        urlCache.removeCachedResponse(for: urlRequest)
    }
}
