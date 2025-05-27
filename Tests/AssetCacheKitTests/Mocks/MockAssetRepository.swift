import Foundation
@testable import AssetCacheKit

/// A mock implementation of AssetRepository for testing purposes

final class MockAssetRepository: AssetRepository, @unchecked Sendable {
    
    /// Tracks if loadAsset was called
    private(set) var loadAssetCalled = false
    /// Tracks if fetchCachedAsset was called
    private(set) var fetchCachedAssetCalled = false
    /// Tracks if cacheAsset was called
    private(set) var cacheAssetCalled = false
    /// Tracks if clearCache was called
    private(set) var clearCacheCalled = false
    
    init(loadAssetCalled: Bool = false, fetchCachedAssetCalled: Bool = false, cacheAssetCalled: Bool = false, clearCacheCalled: Bool = false, mockData: Data? = nil, mockError: Error? = nil, mockCachedData: Data? = nil) {
        self.loadAssetCalled = loadAssetCalled
        self.fetchCachedAssetCalled = fetchCachedAssetCalled
        self.cacheAssetCalled = cacheAssetCalled
        self.clearCacheCalled = clearCacheCalled
        self.mockData = mockData
        self.mockError = mockError
        self.mockCachedData = mockCachedData
    }
    /// The data to return from loadAsset
    var mockData: Data?
    /// The error to throw from loadAsset
    var mockError: Error?
    /// The cached data to return
    var mockCachedData: Data?
    
    func loadAsset(with url: URL?) async throws -> Data {
        loadAssetCalled = true
        if let mockError = mockError {
            throw mockError
        }
        guard let mockData = mockData else {
            throw AppError.assetLoading(.invalidImageData)
        }
        return mockData
    }
    
    func fetchCachedAsset(for urlRequest: URLRequest) -> Data? {
        fetchCachedAssetCalled = true
        return mockCachedData
    }
    
    func cacheAsset(response: HTTPURLResponse, data: Data, for urlRequest: URLRequest) {
        cacheAssetCalled = true
        mockCachedData = data
    }
    
    func clearCache(for urlRequest: URLRequest) {
        clearCacheCalled = true
        mockCachedData = nil
    }
    
    /// Resets all tracking variables
    func reset() {
        loadAssetCalled = false
        fetchCachedAssetCalled = false
        cacheAssetCalled = false
        clearCacheCalled = false
        mockData = nil
        mockError = nil
        mockCachedData = nil
    }
} 
