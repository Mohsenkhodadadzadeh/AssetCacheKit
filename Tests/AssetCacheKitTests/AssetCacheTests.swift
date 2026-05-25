import XCTest
@testable import AssetCacheKit

final class AssetCacheTests: XCTestCase {
    private var cache: AssetCache!

    override func setUp() async throws {
        try await super.setUp()
        URLProtocolStub.startIntercepting()
        cache = AssetCache(configuration: AssetCacheConfiguration(
            rawDataMemoryByteLimit: 1_024 * 1_024,
            diskByteLimit: 1_024 * 1_024,
            defaultExpiration: 60,
            retryPolicy: .none
        ))
        await cache.clearAll()
    }

    override func tearDown() async throws {
        await cache.clearAll()
        cache = nil
        URLProtocolStub.stopIntercepting()
        try await super.tearDown()
    }

    func testData_ReturnsDataFromNetworkOnceThenMemoryHit() async throws {
        let expected = "network payload".data(using: .utf8)!
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expected)
        }

        let firstResult = try await cache.data(for: TestData.validURL)
        let secondResult = try await cache.data(for: TestData.validURL)

        XCTAssertEqual(firstResult, expected)
        XCTAssertEqual(secondResult, expected)
        XCTAssertEqual(URLProtocolStub.requestCount, 1)
    }

    func testData_UsesDiskCacheAfterMemoryCleared() async throws {
        let expected = "disk payload".data(using: .utf8)!
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expected)
        }

        _ = try await cache.data(for: TestData.validURL)
        await cache.clearMemory()
        let secondResult = try await cache.data(for: TestData.validURL)

        XCTAssertEqual(secondResult, expected)
        XCTAssertEqual(URLProtocolStub.requestCount, 1)
    }

    func testData_DeduplicatesConcurrentRequests() async throws {
        let expected = "deduplicated payload".data(using: .utf8)!
        URLProtocolStub.requestHandler = { request in
            Thread.sleep(forTimeInterval: 0.05)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expected)
        }

        let cacheReference = cache!
        async let firstResult = cacheReference.data(for: TestData.validURL)
        async let secondResult = cacheReference.data(for: TestData.validURL)

        let results = try await (firstResult, secondResult)

        XCTAssertEqual(results.0, expected)
        XCTAssertEqual(results.1, expected)
        XCTAssertEqual(URLProtocolStub.requestCount, 1)
    }

    func testData_ClearAllRemovesDiskAndMemory() async throws {
        let expected = "clear all payload".data(using: .utf8)!
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expected)
        }

        _ = try await cache.data(for: TestData.validURL)
        XCTAssertEqual(URLProtocolStub.requestCount, 1)

        await cache.clearAll()

        _ = try await cache.data(for: TestData.validURL)
        XCTAssertEqual(URLProtocolStub.requestCount, 2)
    }

    func testPrefetch_SilentlyIgnoresFailingURLs() async throws {
        URLProtocolStub.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        await cache.prefetch(urls: [TestData.validURL])
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(URLProtocolStub.requestCount, 1)
    }
}
