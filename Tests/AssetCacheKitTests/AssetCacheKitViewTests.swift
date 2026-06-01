import XCTest
import CoreGraphics
@testable import AssetCacheKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class AssetCacheKitViewTests: XCTestCase {
 
    func test_failureLoader_propagatesError() async {
        let uc     = MockLoadAssetUseCase(.fail(AppError.assetLoading(.invalidPDFData)))
        let loader = CachedPDFLoader(url: Fixtures.sampleURL, loadAssetUseCase: uc)
        do {
            _ = try await loader.loadAsset()
            XCTFail("Should have thrown")
        } catch let err as AppError {
            XCTAssertEqual(err, .assetLoading(.invalidPDFData))
        } catch {
            XCTFail("Unexpected: \(error)")
        }
    }
 
    // MARK: AsyncPhase transitions
 
    func test_asyncPhase_initialState_isEmpty() {
        let phase: AsyncPhase<String> = .empty
        if case .empty = phase { } else { XCTFail("Expected .empty") }
    }
 
    func test_asyncPhase_afterSuccess_isSuccess() {
        var phase: AsyncPhase<String> = .empty
        phase = .success("loaded")
        if case .success(let v) = phase {
            XCTAssertEqual(v, "loaded")
        } else {
            XCTFail("Expected .success")
        }
    }
 
    func test_asyncPhase_afterFailure_isFailure() {
        var phase: AsyncPhase<String> = .empty
        let err = AppError.assetLoading(.invalidURL)
        phase = .failure(err)
        if case .failure(let e) = phase {
            XCTAssertEqual(e as? AppError, err)
        } else {
            XCTFail("Expected .failure")
        }
    }
 
    // MARK: Loader identity drives re-fetch (.task(id:))
 
    func test_loaderEquality_sameURL_doesNotRetrigger() {
        let a = CachedImageLoader(url: Fixtures.sampleURL)
        let b = CachedImageLoader(url: Fixtures.sampleURL)
        XCTAssertEqual(a, b,
            ".task(id:) uses Equatable — same loader should not re-trigger fetch")
    }
 
    func test_loaderEquality_differentURL_retriggersTask() {
        let a = CachedImageLoader(url: URL(string: "https://a.com/1.jpg"))
        let b = CachedImageLoader(url: URL(string: "https://a.com/2.jpg"))
        XCTAssertNotEqual(a, b,
            "Different URLs should produce unequal loaders, triggering a new fetch")
    }
}
