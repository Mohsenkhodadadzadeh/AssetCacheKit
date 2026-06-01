//
//  CachedSVGLoaderTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CachedSVGLoaderTests: XCTestCase {
 
    func test_loadAsset_invalidSVG_throwsInvalidSVGData() async {
        let loader = CachedSVGLoader(
            url: Fixtures.sampleURL,
            loadAssetUseCase: MockLoadAssetUseCase(.succeed(Fixtures.invalidData))
        )
        do {
            _ = try await loader.loadAsset()
            XCTFail("Expected throw")
        } catch let err as AppError {
            XCTAssertEqual(err, .assetLoading(.invalidSVGData))
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }
 
    func test_loadAsset_networkError_propagates() async {
        let loader = CachedSVGLoader(
            url: Fixtures.sampleURL,
            loadAssetUseCase: MockLoadAssetUseCase(.fail(AppError.network(.timeout)))
        )
        do {
            _ = try await loader.loadAsset()
            XCTFail("Expected throw")
        } catch let err as AppError {
            XCTAssertEqual(err, AppError.network(.timeout))
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }
 
    func test_equatable_sameURL_equal() {
        XCTAssertEqual(
            CachedSVGLoader(url: Fixtures.sampleURL),
            CachedSVGLoader(url: Fixtures.sampleURL)
        )
    }
 
    func test_equatable_nilURL_equal() {
        XCTAssertEqual(CachedSVGLoader(url: nil), CachedSVGLoader(url: nil))
    }
 
    func test_equatable_differentURL_notEqual() {
        XCTAssertNotEqual(
            CachedSVGLoader(url: URL(string: "https://a.com/a.svg")),
            CachedSVGLoader(url: URL(string: "https://b.com/b.svg"))
        )
    }
}
 
