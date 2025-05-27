import XCTest
import SwiftUI
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@testable import AssetCacheKit

@available(iOS 15.0, *)
final class AssetCacheKitViewTests: XCTestCase {
    private var mockRepository: MockAssetRepository!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAssetRepository()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - View State Tests
    
    @MainActor
    func testView_InitialState_ShowsPlaceholder() async {
        // Given
        
        let loader = createMockLoader()
        let expectation = XCTestExpectation(description: "Content loaded")
        
        // When
        let sut = AssetCacheKit(
            loader: loader,
            content: { _ in Text("Content") },
            placeholder: { Text("Loading...").onAppear { expectation.fulfill()} },
            error: { _ in Text("Error") }
        )
        
        
        // Render the view
#if os(iOS)
        let hostingController = UIHostingController(rootView: sut)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
#elseif os(macOS)
        let hostingController = NSHostingController(rootView: sut)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.makeKeyAndOrderFront(nil)
#endif
//        // Render the view
//        let hostingController = UIHostingController(rootView: sut)
//        let window = UIWindow(frame: UIScreen.main.bounds)
//        window.rootViewController = hostingController
//        window.makeKeyAndVisible()
//        
        // Then
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Clean up
        #if os(iOS)
        window.isHidden = true
        window.rootViewController = nil
        #elseif os(macOS)
        window.orderOut(nil)
        window.contentViewController = nil
        #endif
    }
    
    @MainActor
    func testView_SuccessfulLoad_ShowsContent() async {
        // Given
        
        mockRepository.mockData = TestData.validImageData
        let loader = createMockLoader()
        let expectation = XCTestExpectation(description: "Content loaded")
        
        // When
        let sut = AssetCacheKit(
            loader: loader,
            content: { _ in Text("Content").onAppear { expectation.fulfill() } },
            placeholder: { Text("Loading...") },
            error: { _ in Text("Error") }
        )
        
        // Render the view
#if os(iOS)
        let hostingController = UIHostingController(rootView: sut)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
#elseif os(macOS)
        let hostingController = NSHostingController(rootView: sut)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.makeKeyAndOrderFront(nil)
#endif
        
//        let hostingController = UIHostingController(rootView: sut)
//        let window = UIWindow(frame: UIScreen.main.bounds)
//        window.rootViewController = hostingController
//        window.makeKeyAndVisible()
        
        // Then
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Clean up
#if os(iOS)
        window.isHidden = true
        window.rootViewController = nil
#elseif os(macOS)
        window.orderOut(nil)
        window.contentViewController = nil
#endif
    }
    
    @MainActor
    func testView_LoadError_ShowsError() async {
        // Given
        
        let expectedError = AppError.assetLoading(.invalidURL)
        mockRepository.mockError = expectedError
        let loader = createMockLoader()
        let expectation = XCTestExpectation(description: "Error received")
        
        // When
        let sut = AssetCacheKit(
            loader: loader,
            content: { _ in Text("Content") },
            placeholder: { Text("Loading...") },
            error: { _ in Text("Error").onAppear { expectation.fulfill()} }
        )
        
        // Render the view
#if os(iOS)
        let hostingController = UIHostingController(rootView: sut)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
#elseif os(macOS)
        let hostingController = NSHostingController(rootView: sut)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.makeKeyAndOrderFront(nil)
#endif
        
//        let hostingController = UIHostingController(rootView: sut)
//        let window = UIWindow(frame: UIScreen.main.bounds)
//        window.rootViewController = hostingController
//        window.makeKeyAndVisible()
        
        // Then
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Clean up
#if os(iOS)
        window.isHidden = true
        window.rootViewController = nil
#elseif os(macOS)
        window.orderOut(nil)
        window.contentViewController = nil
#endif
    }
    
    // MARK: - Helper Methods
    
    private func createMockLoader() -> some AssetLoader {
        struct MockLoader: AssetLoader {
            var url: URL? = TestData.validURL
            
            let repository: MockAssetRepository
            
            func loadAsset() async throws -> Data {
                try await repository.loadAsset(with: TestData.validURL)
            }
            
            static func == (lhs: MockLoader, rhs: MockLoader) -> Bool {
                true
            }
        }
        
        return MockLoader(repository: mockRepository)
    }
}
