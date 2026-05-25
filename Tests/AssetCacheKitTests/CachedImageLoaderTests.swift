import XCTest
import SwiftUI
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#else
import AppKit
#endif
@testable import AssetCacheKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CachedImageLoaderTests: XCTestCase {
    func testLoadAsset_WhenDecodedCacheContainsImage_ReturnsSwiftUIImage() async throws {
        let decodedCache = DecodedImageCache()
        let assetCache = AssetCache(configuration: AssetCacheConfiguration(retryPolicy: .none))
        let loader = CachedImageLoader(
            url: TestData.validURL,
            assetCache: assetCache,
            decodedCache: decodedCache
        )

        let key = CacheKey(url: TestData.validURL, scale: 1, targetSize: nil)
        decodedCache.store(makePlatformImage(), for: key, expiration: 60)

        let image = try await loader.loadAsset()

        XCTAssertNotNil(image)
    }

    func testLoadAsset_WithNilURL_ThrowsInvalidURL() async {
        let decodedCache = DecodedImageCache()
        let assetCache = AssetCache(configuration: AssetCacheConfiguration(retryPolicy: .none))
        let loader = CachedImageLoader(
            url: nil,
            assetCache: assetCache,
            decodedCache: decodedCache
        )

        do {
            _ = try await loader.loadAsset()
            XCTFail("Expected invalid URL error")
        } catch let error as AppError {
            XCTAssertEqual(error, .assetLoading(.invalidURL))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    private func makePlatformImage() -> PlatformImage {
#if os(iOS) || os(tvOS) || os(watchOS)
        if let image = UIImage(systemName: "checkmark") {
            return image
        }
        return UIImage()
#else
        let image = NSImage(size: NSSize(width: 1, height: 1))
        image.lockFocus()
        NSColor.black.setFill()
        NSRect(x: 0, y: 0, width: 1, height: 1).fill()
        image.unlockFocus()
        return image
#endif
    }
}
