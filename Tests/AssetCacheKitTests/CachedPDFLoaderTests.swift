//
//  CachedPDFLoaderTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

@available(iOS 15.0, macOS 12.0, *)
final class CachedPDFLoaderTests: XCTestCase {

   func test_loadAsset_nilURL_throwsInvalidURL() async {
       let loader = CachedPDFLoader(
           url: nil,
           loadAssetUseCase: MockLoadAssetUseCase(.succeed(Fixtures.minimalPDF))
       )
       // nil url is handled by the use case; inject one that throws
       let nilLoader = CachedPDFLoader(
           url: nil,
           loadAssetUseCase: MockLoadAssetUseCase(.fail(AppError.assetLoading(.invalidURL)))
       )
       do {
           _ = try await nilLoader.loadAsset()
           XCTFail("Expected throw")
       } catch let err as AppError {
           XCTAssertEqual(err, .assetLoading(.invalidURL))
       } catch {
           XCTFail("Wrong error: \(error)")
       }
       _ = loader // suppress unused warning
   }


   func test_loadAsset_invalidPDFData_throwsInvalidPDFData() async {
       let loader = CachedPDFLoader(
           url: Fixtures.sampleURL,
           loadAssetUseCase: MockLoadAssetUseCase(.succeed(Fixtures.invalidData))
       )
       do {
           _ = try await loader.loadAsset()
           XCTFail("Expected throw")
       } catch let err as AppError {
           XCTAssertEqual(err, .assetLoading(.invalidPDFData))
       } catch {
           XCTFail("Wrong error: \(error)")
       }
   }

   func test_loadAsset_networkError_propagates() async {
       let networkErr = AppError.network(.noConnection)
       let loader     = CachedPDFLoader(
           url: Fixtures.sampleURL,
           loadAssetUseCase: MockLoadAssetUseCase(.fail(networkErr))
       )
       do {
           _ = try await loader.loadAsset()
           XCTFail("Expected throw")
       } catch let err as AppError {
           XCTAssertEqual(err, .network(.noConnection))
       } catch {
           XCTFail("Wrong error: \(error)")
       }
   }

   func test_useCaseCalled_exactlyOnce() async throws {
       let uc     = MockLoadAssetUseCase(.succeed(Fixtures.minimalPDF))
       let loader = CachedPDFLoader(url: Fixtures.sampleURL, loadAssetUseCase: uc)
       _ = try? await loader.loadAsset()
       XCTAssertEqual(uc.callCount, 1)
   }

   func test_equatable_sameURL_equal() {
       XCTAssertEqual(
           CachedPDFLoader(url: Fixtures.sampleURL),
           CachedPDFLoader(url: Fixtures.sampleURL)
       )
   }

   func test_equatable_differentURL_notEqual() {
       XCTAssertNotEqual(
           CachedPDFLoader(url: URL(string: "https://a.com/a.pdf")),
           CachedPDFLoader(url: URL(string: "https://b.com/b.pdf"))
       )
   }
}
