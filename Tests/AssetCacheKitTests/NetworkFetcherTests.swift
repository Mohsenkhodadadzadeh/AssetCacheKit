
import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit


/// `NetworkFetcher` is tested with real URLs only for error paths (bad URLs).
/// Live network tests are skipped in CI; they are integration tests.
final class NetworkFetcherTests: XCTestCase {
 
    func test_badURL_scheme_throws() async {
        let bad = URL(string: "not-a-valid-url://???")!
        do {
            _ = try await NetworkFetcher.fetch(url: bad, policy: .none)
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is AppError, "Should be AppError, got \(type(of: error))")
        }
    }
 
    func test_retryPolicy_none_doesNotRetry() async {
        // Use a localhost URL that will fail instantly
        let dead = URL(string: "http://localhost:19999/no-server")!
        let start = Date()
        do {
            _ = try await NetworkFetcher.fetch(url: dead, policy: .none)
        } catch { /* expected */ }
        let elapsed = Date().timeIntervalSince(start)
        // With no retries the call should return quickly (< 5 s)
        XCTAssertLessThan(elapsed, 5.0, "Single attempt should fail fast")
    }
}
