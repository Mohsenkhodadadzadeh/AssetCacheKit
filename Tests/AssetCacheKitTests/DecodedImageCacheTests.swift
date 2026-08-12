//
//  DecodedImageCacheTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

final class DecodedImageCacheTests: XCTestCase {
 
    private var cache: DecodedImageCache!
 
    override func setUp() {
        super.setUp()
        cache = DecodedImageCache(countLimit: 10, byteLimit: 10 * 1_024 * 1_024)
    }
 
    override func tearDown() {
        cache.clearAll()
        super.tearDown()
    }
 
    private func makeKey(_ suffix: String = "") -> CacheKey {
        CacheKey(url: URL(string: "https://example.com/img\(suffix).jpg")!,
                 scale: 1,
                 targetSize: nil)
    }
 
    private func makePlatformImage() -> PlatformImage {
#if os(macOS)
        NSImage(size: NSSize(width: 2, height: 2))
#else
        UIGraphicsBeginImageContext(CGSize(width: 2, height: 2))
        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
#endif
    }
 
    func test_store_thenRetrieve_returnsImage() {
        let key   = makeKey("_A")
        let image = makePlatformImage()
        cache.store(image, for: key, expiration: 3600)
        XCTAssertNotNil(cache.image(for: key))
    }
 
    func test_miss_returnsNil() {
        let key = makeKey("_missing")
        XCTAssertNil(cache.image(for: key))
    }
 
    func test_expiredEntry_returnsNil() {
        let key   = makeKey("_exp")
        let image = makePlatformImage()
        cache.store(image, for: key, expiration: -1)
        XCTAssertNil(cache.image(for: key), "Expired entry must return nil")
    }
 
    func test_downsampledVariant_doesNotCollideWithFullResolution() {
        let url       = URL(string: "https://example.com/photo.jpg")!
        let thumbnail = CacheKey(url: url, scale: 1, targetSize: CGSize(width: 80, height: 80))
        let fullSize  = CacheKey(url: url, scale: 1, targetSize: nil)

        cache.store(makePlatformImage(), for: thumbnail, expiration: 3600)

        XCTAssertNotNil(cache.image(for: thumbnail))
        XCTAssertNil(cache.image(for: fullSize),
            "Caching an 80×80 thumbnail must not satisfy a full-resolution request")
    }

    func test_differentScales_doNotCollide() {
        let url  = URL(string: "https://example.com/photo.jpg")!
        let at1x = CacheKey(url: url, scale: 1, targetSize: nil)
        let at3x = CacheKey(url: url, scale: 3, targetSize: nil)

        cache.store(makePlatformImage(), for: at1x, expiration: 3600)

        XCTAssertNotNil(cache.image(for: at1x))
        XCTAssertNil(cache.image(for: at3x),
            "A 1x decode must not be served for a 3x request")
    }

    func test_clearAll_removesAllEntries() {
        for i in 0..<5 {
            cache.store(makePlatformImage(), for: makeKey("_\(i)"), expiration: 3600)
        }
        cache.clearAll()
        for i in 0..<5 {
            XCTAssertNil(cache.image(for: makeKey("_\(i)")))
        }
    }
}
