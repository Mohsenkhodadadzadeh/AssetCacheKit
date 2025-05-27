import XCTest
@testable import AssetCacheKit

final class DefaultAssetRepositoryTests: XCTestCase {
    private var sut: DefaultAssetRepository!
    private var urlSession: URLSession!
    private var urlCache: URLCache!
    
    override func setUp() {
        super.setUp()
        urlCache = URLCache(memoryCapacity: 1024 * 1024, diskCapacity: 1024 * 1024, diskPath: nil)
        urlSession = URLSession(configuration: .ephemeral)
        sut = DefaultAssetRepository(urlSession: urlSession, urlCache: urlCache)
    }
    
    override func tearDown() {
        urlCache.removeAllCachedResponses()
        sut = nil
        urlSession = nil
        urlCache = nil
        super.tearDown()
    }
    
    // MARK: - Load Asset Tests
    
    func testLoadAsset_WithNilURL_ThrowsInvalidURL() async {
        do {
            _ = try await sut.loadAsset(with: nil)
            XCTFail("Expected error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, AppError.assetLoading(.invalidURL))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testLoadAsset_WithCachedData_ReturnsCachedData() async throws {
        // Given
        let request = TestData.mockURLRequest(url: TestData.validURL)
        let response = TestData.mockHTTPResponse(url: TestData.validURL, statusCode: 200)
        let cachedResponse = CachedURLResponse(response: response, data: TestData.validImageData)
        urlCache.storeCachedResponse(cachedResponse, for: request)
        
        // When
        let result = try await sut.loadAsset(with: TestData.validURL)
        
        // Then
        XCTAssertEqual(result, TestData.validImageData)
    }
    
    // MARK: - Cache Tests
    
    func testCacheAsset_StoresDataInCache() {
        // Given
        let request = TestData.mockURLRequest(url: TestData.validURL)
        let response = TestData.mockHTTPResponse(url: TestData.validURL, statusCode: 200)
        
        // When
        sut.cacheAsset(response: response, data: TestData.validImageData, for: request)
        
        // Then
        let cachedData = sut.fetchCachedAsset(for: request)
        XCTAssertEqual(cachedData, TestData.validImageData)
    }
    
    func testClearCache_RemovesDataFromCache() {
        // Given
        let request = TestData.mockURLRequest(url: TestData.validURL)
        let response = TestData.mockHTTPResponse(url: TestData.validURL, statusCode: 200)
        sut.cacheAsset(response: response, data: TestData.validImageData, for: request)
        
        // When
        sut.clearCache(for: request)
        
        // Then
        let cachedData = sut.fetchCachedAsset(for: request)
        XCTAssertNil(cachedData)
    }
} 
