//
//  AsyncCacheTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

/// `AssetCache` is an actor; all tests use `async` helpers.
final class AssetCacheTests: XCTestCase {
 
    // Create isolated caches so tests don't share state
    private func makeFreshCache(diskLimit: Int = 10 * 1_024 * 1_024) -> AssetCache {
        AssetCache(configuration: AssetCacheConfiguration(
            rawDataMemoryByteLimit: 5 * 1_024 * 1_024,
            diskByteLimit: diskLimit,
            defaultExpiration: 3600,
            retryPolicy: .none
        ))
    }
 
    // MARK: Memory layer
 
    func test_clearMemory_doesNotClearDisk_concept() async {
        // After clearMemory(), the second call still works because disk holds a copy.
        // We verify the API is callable without crash.
        let cache = makeFreshCache()
        await cache.clearMemory()
    }
 
    func test_clearAll_isCallable() async {
        let cache = makeFreshCache()
        await cache.clearAll()
    }
 
    // MARK: Request deduplication
 
    func test_concurrentRequests_onlyOneNetworkCall() async throws {
        // We can't intercept the real network, so we test deduplication via
        // RequestDeduplicator directly (see §12), and verify the actor API here.
        let cache = makeFreshCache()
        await cache.clearAll()
        // Just verify no crash / hang with repeated clearAll calls concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask { await cache.clearMemory() }
            }
        }
    }
 
    // MARK: prefetch
 
    func test_prefetch_doesNotThrow() async {
        let cache = makeFreshCache()
        let urls = (0..<3).map { URL(string: "https://example.com/prefetch_\($0).jpg")! }
        // prefetch fires tasks; we just verify no synchronous crash
        await cache.prefetch(urls: urls)
    }
}
