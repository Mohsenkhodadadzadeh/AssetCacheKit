import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

final class DefaultAssetRepositoryTests: XCTestCase {
 
    func test_nilURL_throwsInvalidURL() async {
        let repo = DefaultAssetRepository(cache: AssetCache(
            configuration: AssetCacheConfiguration(retryPolicy: .none)
        ))
        do {
            _ = try await repo.loadAsset(with: nil)
            XCTFail("Expected throw")
        } catch let err as AppError {
            XCTAssertEqual(err, .assetLoading(.invalidURL))
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }
}
