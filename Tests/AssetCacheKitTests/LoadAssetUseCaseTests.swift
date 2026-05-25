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

    func testExecute_ForwardsToRepositoryAndReturnsData() async throws {
        mockRepository.mockData = TestData.validImageData

        let result = try await sut.execute(url: TestData.validURL)

        XCTAssertTrue(mockRepository.loadAssetCalled)
        XCTAssertEqual(result, TestData.validImageData)
    }

    func testExecute_PropagatesRepositoryError() async {
        let expectedError = AppError.assetLoading(.invalidURL)
        mockRepository.mockError = expectedError

        do {
            _ = try await sut.execute(url: nil)
            XCTFail("Expected error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertTrue(mockRepository.loadAssetCalled)
    }

    func testExecute_WithNilURL_StillCallsRepository() async {
        mockRepository.mockError = AppError.assetLoading(.invalidURL)

        do {
            _ = try await sut.execute(url: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            // ignore, validated below
        }

        XCTAssertTrue(mockRepository.loadAssetCalled)
    }
}
