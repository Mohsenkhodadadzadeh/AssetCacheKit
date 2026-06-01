import XCTest
import SwiftUI
import XCTest
import PDFKit
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#else
import AppKit
#endif
@testable import AssetCacheKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CachedImageLoaderTests: XCTestCase {
 
    func test_loadAsset_nilURL_throwsInvalidURL() async {
        let assetCache   = AssetCache(configuration: .init(retryPolicy: .none))
        let decodedCache = DecodedImageCache()
        let loader = CachedImageLoader(
            url: nil,
            assetCache: assetCache,
            decodedCache: decodedCache
        )
        do {
            _ = try await loader.loadAsset()
            XCTFail("Expected throw")
        } catch let err as AppError {
            XCTAssertEqual(err, .assetLoading(.invalidURL))
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }
 
    func test_loadAsset_withValidJPEG_returnsImage() async throws {
        let assetCache   = AssetCache(configuration: .init(retryPolicy: .none))
        let decodedCache = DecodedImageCache()
 
        // Prime the asset cache with our fixture bytes so no network call is made
        await assetCache.primeMemory(url: Fixtures.sampleURL, data: Fixtures.onePixelJPEG)
 
        let loader = CachedImageLoader(
            url: Fixtures.sampleURL,
            assetCache: assetCache,
            decodedCache: decodedCache
        )
        // Should succeed — if it throws the test fails
        let image = try await loader.loadAsset()
        _ = image // Image is a value type; just verifying no throw
    }
 
    func test_loadAsset_invalidImageData_throwsInvalidImageData() async {
        let assetCache   = AssetCache(configuration: .init(retryPolicy: .none))
        let decodedCache = DecodedImageCache()
        await assetCache.primeMemory(url: Fixtures.sampleURL, data: Fixtures.invalidData)
 
        let loader = CachedImageLoader(
            url: Fixtures.sampleURL,
            assetCache: assetCache,
            decodedCache: decodedCache
        )
        do {
            _ = try await loader.loadAsset()
            XCTFail("Expected throw for invalid image data")
        } catch let err as AppError {
            XCTAssertEqual(err, .assetLoading(.invalidImageData))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
 
    func test_equatable_sameURL_equal() {
        let a = CachedImageLoader(url: Fixtures.sampleURL)
        let b = CachedImageLoader(url: Fixtures.sampleURL)
        XCTAssertEqual(a, b)
    }
 
    func test_equatable_differentURL_notEqual() {
        let a = CachedImageLoader(url: URL(string: "https://a.com/1.jpg"))
        let b = CachedImageLoader(url: URL(string: "https://b.com/2.jpg"))
        XCTAssertNotEqual(a, b)
    }
 
    func test_equatable_nilURL_equal() {
        let a = CachedImageLoader(url: nil)
        let b = CachedImageLoader(url: nil)
        XCTAssertEqual(a, b)
    }
 
    func test_equatable_nilVsNonNil_notEqual() {
        let a = CachedImageLoader(url: nil)
        let b = CachedImageLoader(url: Fixtures.sampleURL)
        XCTAssertNotEqual(a, b)
    }
 
    func test_secondLoad_servesFromDecodedCache() async throws {
        let assetCache   = AssetCache(configuration: .init(retryPolicy: .none))
        let decodedCache = DecodedImageCache()
        await assetCache.primeMemory(url: Fixtures.sampleURL, data: Fixtures.onePixelJPEG)
 
        let loader = CachedImageLoader(
            url: Fixtures.sampleURL,
            assetCache: assetCache,
            decodedCache: decodedCache
        )
        _ = try await loader.loadAsset()    // first call populates decoded cache
        _ = try await loader.loadAsset()    // second call should hit decoded cache
        // Primary verification: no throw on second call
    }
}
