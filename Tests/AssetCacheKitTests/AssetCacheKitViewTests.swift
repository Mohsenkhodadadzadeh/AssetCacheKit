import XCTest
import CoreGraphics
@testable import AssetCacheKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class AssetCacheKitViewTests: XCTestCase {
    func testCachedImageLoaderEquality_SameConfigurationIsEqual() {
        let first = CachedImageLoader(
            url: TestData.validURL,
            scale: 1,
            targetSize: CGSize(width: 32, height: 32)
        )
        let second = CachedImageLoader(
            url: TestData.validURL,
            scale: 1,
            targetSize: CGSize(width: 32, height: 32)
        )

        XCTAssertEqual(first, second)
    }

    func testCachedImageLoaderEquality_DifferentURLIsNotEqual() {
        let first = CachedImageLoader(
            url: TestData.validURL,
            scale: 1,
            targetSize: CGSize(width: 32, height: 32)
        )
        let second = CachedImageLoader(
            url: URL(string: "https://example.com/other.jpg"),
            scale: 1,
            targetSize: CGSize(width: 32, height: 32)
        )

        XCTAssertNotEqual(first, second)
    }
}
