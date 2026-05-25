import XCTest
@testable import AssetCacheKit

final class DefaultAssetRepositoryTests: XCTestCase {
    private var cache: AssetCache!
    private var sut: DefaultAssetRepository!

    override func setUp() async throws {
        try await super.setUp()
        URLProtocolStub.startIntercepting()
        cache = AssetCache(configuration: AssetCacheConfiguration(
            rawDataMemoryByteLimit: 1_024 * 1_024,
            diskByteLimit: 1_024 * 1_024,
            defaultExpiration: 60,
            retryPolicy: .none
        ))
        sut = DefaultAssetRepository(cache: cache)
        await cache.clearAll()
    }

    override func tearDown() async throws {
        await cache.clearAll()
        cache = nil
        sut = nil
        URLProtocolStub.stopIntercepting()
        try await super.tearDown()
    }

    func testLoadAsset_WithNilURL_ThrowsInvalidURL() async {
        do {
            _ = try await sut.loadAsset(with: nil)
            XCTFail("Expected invalid URL error")
        } catch let error as AppError {
            XCTAssertEqual(error, .assetLoading(.invalidURL))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLoadAsset_ReturnsDataFromAssetCache() async throws {
        let expected = "repository payload".data(using: .utf8)!
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expected)
        }

        let result = try await sut.loadAsset(with: TestData.validURL)

        XCTAssertEqual(result, expected)
        XCTAssertEqual(URLProtocolStub.requestCount, 1)
    }

    func testLoadAsset_PropagatesNetworkError() async {
        URLProtocolStub.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await sut.loadAsset(with: TestData.validURL)
            XCTFail("Expected network error")
        } catch let error as AppError {
            XCTAssertEqual(error, .network(.noConnection))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertEqual(URLProtocolStub.requestCount, 1)
    }
}
