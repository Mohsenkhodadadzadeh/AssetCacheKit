import XCTest
@testable import AssetCacheKit

final class LoadAssetUseCaseTests: XCTestCase {
    private var sut: DefaultLoadAssetUseCase!
    private var mockRepository: MockAssetRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAssetRepository()
        sut = DefaultLoadAssetUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Success Tests
    
    func testExecute_WithValidURL_CallsRepository() async throws {
        // Given
        mockRepository.mockData = TestData.validImageData
        
        // When
        let result = try await sut.execute(url: TestData.validURL)
        
        // Then
        XCTAssertTrue(mockRepository.loadAssetCalled)
        XCTAssertEqual(result, TestData.validImageData)
    }
    
    func testExecute_WithNilURL_CallsRepository() async {
        // Given
        mockRepository.mockError = AppError.assetLoading(.invalidURL)
        
        // When/Then
        do {
            _ = try await sut.execute(url: nil)
            XCTFail("Expected error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, AppError.assetLoading(.invalidURL))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        XCTAssertTrue(mockRepository.loadAssetCalled)
    }
    
    // MARK: - Error Tests
    
    func testExecute_WithNetworkErrors_PropagatesErrors() async {
        for (_, expectedError) in TestData.networkErrors {
            // Given
            mockRepository.reset()
            mockRepository.mockError = expectedError
            
            // When/Then
            do {
                _ = try await sut.execute(url: TestData.validURL)
                XCTFail("Expected error to be thrown")
            } catch let error as AppError {
                XCTAssertEqual(error, expectedError)
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
            XCTAssertTrue(mockRepository.loadAssetCalled)
        }
    }
    
    func testExecute_WithAssetErrors_PropagatesErrors() async {
        for expectedError in TestData.assetErrors {
            // Given
            mockRepository.reset()
            mockRepository.mockError = expectedError
            
            // When/Then
            do {
                _ = try await sut.execute(url: TestData.validURL)
                XCTFail("Expected error to be thrown")
            } catch let error as AppError {
                XCTAssertEqual(error, expectedError)
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
            XCTAssertTrue(mockRepository.loadAssetCalled)
        }
    }
    
    // MARK: - Cache Interaction Tests
    
    func testExecute_WithCachedData_UsesRepository() async throws {
        // Given
        mockRepository.mockCachedData = TestData.validImageData
        mockRepository.mockData = TestData.validImageData
        
        // When
        let result = try await sut.execute(url: TestData.validURL)
        
        // Then
        XCTAssertTrue(mockRepository.loadAssetCalled)
        XCTAssertEqual(result, TestData.validImageData)
    }
} 
