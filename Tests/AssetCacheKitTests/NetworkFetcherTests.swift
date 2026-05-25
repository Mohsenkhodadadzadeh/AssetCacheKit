import XCTest
@testable import AssetCacheKit

final class NetworkFetcherTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        URLProtocolStub.startIntercepting()
    }

    override func tearDown() async throws {
        URLProtocolStub.stopIntercepting()
        try await super.tearDown()
    }

    func testFetch_ReturnsDataForHTTP200() async throws {
        let expected = "fetch payload".data(using: .utf8)!
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expected)
        }

        let result = try await NetworkFetcher.fetch(url: TestData.validURL, policy: .none)

        XCTAssertEqual(result, expected)
        XCTAssertEqual(URLProtocolStub.requestCount, 1)
    }

    func testFetch_RetriesOnTransientURLErrorThenSucceeds() async throws {
        let expected = "retry payload".data(using: .utf8)!
        var attempts = 0

        URLProtocolStub.requestHandler = { request in
            attempts += 1

            if attempts == 1 {
                throw URLError(.timedOut)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expected)
        }

        let result = try await NetworkFetcher.fetch(
            url: TestData.validURL,
            policy: RetryPolicy(maxAttempts: 2, initialDelay: 0, multiplier: 1)
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(attempts, 2)
    }

    func testFetch_ThrowsMappedTimeoutErrorWhenNoRetries() async {
        URLProtocolStub.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        do {
            _ = try await NetworkFetcher.fetch(url: TestData.validURL, policy: .none)
            XCTFail("Expected fetch to throw")
        } catch let error as AppError {
            XCTAssertEqual(error, .network(.timeout))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertEqual(URLProtocolStub.requestCount, 1)
    }

    func testFetch_ThrowsBadServerResponseForNon2xxStatus() async {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await NetworkFetcher.fetch(url: TestData.validURL, policy: .none)
            XCTFail("Expected fetch to throw")
        } catch let error as AppError {
            XCTAssertEqual(error, .network(.badServerResponse(statusCode: 503)))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertEqual(URLProtocolStub.requestCount, 1)
    }
}
