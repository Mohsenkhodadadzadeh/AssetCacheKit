//
//  DefaultLoadAssetUseCaseTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

final class DefaultLoadAssetUseCaseTests: XCTestCase {

   func test_execute_delegatesToRepository_success() async throws {
       let repo    = MockAssetRepository(.succeed(Fixtures.onePixelJPEG))
       let useCase = DefaultLoadAssetUseCase(repository: repo)
       let url     = Fixtures.sampleURL

       let result = try await useCase.execute(url: url)

       XCTAssertEqual(result, Fixtures.onePixelJPEG)
       XCTAssertEqual(repo.receivedURLs.count, 1)
       XCTAssertEqual(repo.receivedURLs.first!, url)
   }

   func test_execute_propagatesRepositoryError() async {
       let repo    = MockAssetRepository(.fail(AppError.assetLoading(.invalidURL)))
       let useCase = DefaultLoadAssetUseCase(repository: repo)

       do {
           _ = try await useCase.execute(url: Fixtures.sampleURL)
           XCTFail("Expected throw")
       } catch let err as AppError {
           XCTAssertEqual(err, .assetLoading(.invalidURL))
       } catch {
           XCTFail("Wrong error: \(error)")
       }
   }

   func test_execute_nilURL_passedThrough_toRepository() async {
       let repo    = MockAssetRepository(.fail(AppError.assetLoading(.invalidURL)))
       let useCase = DefaultLoadAssetUseCase(repository: repo)

       _ = try? await useCase.execute(url: nil)

       XCTAssertEqual(repo.receivedURLs.count, 1)
       XCTAssertNil(repo.receivedURLs.first!)
   }
}
