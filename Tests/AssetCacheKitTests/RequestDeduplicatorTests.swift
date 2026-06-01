

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

final class RequestDeduplicatorTests: XCTestCase {
 
    func test_singleRequest_returnsData() async throws {
        let dedup  = RequestDeduplicator()
        let url    = URL(string: "https://example.com/dedup.jpg")!
        let expected = Data("hello".utf8)
 
        let result = try await dedup.deduplicate(url: url) { expected }
        XCTAssertEqual(result, expected)
    }
 
    func test_concurrentRequests_sameURL_callsOperationOnce() async throws {
        let dedup  = RequestDeduplicator()
        let url    = URL(string: "https://example.com/dedup2.jpg")!
        let callCount = LockingCounter()
        let expected  = Data("shared".utf8)
 
        await withTaskGroup(of: Data?.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try? await dedup.deduplicate(url: url) {
                        await callCount.increment()
                        try await Task.sleep(nanoseconds: 10_000_000) // 10 ms
                        return expected
                    }
                }
            }
        }
 
        let count = await callCount.value
        // Actor serialises execution; some tasks may piggyback, but count should be low.
        // With proper deduplication, exactly 1 network call for 10 concurrent requests.
        XCTAssertEqual(count, 1, "Deduplicator should fire the operation exactly once for concurrent requests to the same URL")
    }
 
    func test_differentURLs_callsOperationForEach() async throws {
        let dedup     = RequestDeduplicator()
        let callCount = LockingCounter()
        let expected  = Data("ok".utf8)
 
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                let url = URL(string: "https://example.com/item_\(i).jpg")!
                group.addTask {
                    _ = try? await dedup.deduplicate(url: url) {
                        await callCount.increment()
                        return expected
                    }
                }
            }
        }
 
        let count = await callCount.value
        XCTAssertEqual(count, 5, "Each distinct URL should trigger its own operation")
    }
 
    func test_failingOperation_propagatesError() async {
        let dedup = RequestDeduplicator()
        let url   = URL(string: "https://example.com/fail.jpg")!
 
        do {
            _ = try await dedup.deduplicate(url: url) {
                throw AppError.assetLoading(.invalidURL)
            }
            XCTFail("Expected throw")
        } catch let error as AppError {
            XCTAssertEqual(error, .assetLoading(.invalidURL))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
 
// MARK: LockingCounter helper (actor-safe)
private actor LockingCounter {
    private var _value: Int = 0
    func increment() { _value += 1 }
    var value: Int { _value }
}
