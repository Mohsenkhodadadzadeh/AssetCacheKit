import XCTest
@testable import AssetCacheKit

actor Counter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

final class RequestDeduplicatorTests: XCTestCase {
    func testDeduplicate_PreventsDuplicateOperationsForSameURL() async throws {
        let deduplicator = RequestDeduplicator()
        let counter = Counter()

        async let first = deduplicator.deduplicate(url: TestData.validURL) {
            await counter.increment()
            try await Task.sleep(nanoseconds: 50_000_000)
            return TestData.validImageData
        }

        async let second = deduplicator.deduplicate(url: TestData.validURL) {
            await counter.increment()
            try await Task.sleep(nanoseconds: 50_000_000)
            return TestData.validImageData
        }

        let (firstResult, secondResult) = try await (first, second)
        let operationCount = await counter.value

        XCTAssertEqual(operationCount, 1)
        XCTAssertEqual(firstResult, secondResult)
    }

    func testDeduplicate_CleansUpAfterCompletedTask() async throws {
        let deduplicator = RequestDeduplicator()
        let counter = Counter()

        let firstResult = try await deduplicator.deduplicate(url: TestData.validURL) {
            await counter.increment()
            return TestData.validImageData
        }

        let secondResult = try await deduplicator.deduplicate(url: TestData.validURL) {
            await counter.increment()
            return TestData.validImageData
        }

        let operationCount = await counter.value
        XCTAssertEqual(operationCount, 2)
        XCTAssertEqual(firstResult, secondResult)
    }
}
