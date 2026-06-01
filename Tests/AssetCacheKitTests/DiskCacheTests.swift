//
//  DiskCacheTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

/// Tests that exercise `DiskCache` through a private namespace so tests never
/// pollute the production cache directory.
final class DiskCacheTests: XCTestCase {
 
    private var cache: DiskCache!
    private let namespace = "com.assetcachekit.test.\(UUID().uuidString)"
 
    override func setUp() {
        super.setUp()
        cache = DiskCache(
            namespace: namespace,
            byteLimit: 10 * 1_024 * 1_024,
            defaultExpiration: 3600
        )
    }
 
    override func tearDown() async throws {
        await cache.clearAll()
        try await super.tearDown()
    }
 
    func test_store_andRetrieve_returnsOriginalData() async {
        let data = Data("hello disk".utf8)
        await cache.store(data: data, for: "key1")
        let retrieved = await cache.data(for: "key1")
        XCTAssertEqual(retrieved, data)
    }
 
    func test_miss_returnsNil() async {
        let result = await cache.data(for: "nonexistent_key")
        XCTAssertNil(result)
    }
 
    func test_expiredEntry_returnsNil() async {
        let expiredCache = DiskCache(
            namespace: "com.assetcachekit.test.expired.\(UUID().uuidString)",
            byteLimit: 1 * 1_024 * 1_024,
            defaultExpiration: -1   // Already expired
        )
        defer { Task { await expiredCache.clearAll() } }
 
        await expiredCache.store(data: Data("stale".utf8), for: "stale_key")
        let result = await expiredCache.data(for: "stale_key")
        XCTAssertNil(result, "Expired entries should return nil")
    }
 
    func test_clearAll_removesEntries() async {
        await cache.store(data: Data("x".utf8), for: "k1")
        await cache.store(data: Data("y".utf8), for: "k2")
        await cache.clearAll()
        let r1 = await cache.data(for: "k1")
        XCTAssertNil(r1)
        let r2 = await cache.data(for: "k2")
        XCTAssertNil(r2)
    }
 
    func test_overwrite_replacesData() async {
        await cache.store(data: Data("original".utf8), for: "key_ow")
        await cache.store(data: Data("updated".utf8),  for: "key_ow")
        let result = await cache.data(for: "key_ow")
        XCTAssertEqual(result, Data("updated".utf8))
    }
 
 
    func test_multipleStores_accumulateSize() async {
        let chunk = Data(repeating: 0xFF, count: 1024)
        for i in 0..<5 {
            await cache.store(data: chunk, for: "chunk_\(i)")
        }
        // All 5 should still be retrievable (well within 10 MB limit)
        for i in 0..<5 {
            let chunckResult = await cache.data(for: "chunk_\(i)")
            XCTAssertNotNil(chunckResult)
        }
    }
 
    func test_diskKey_collision_differentURLs() async {
        // Two clearly distinct keys should not return each other's data
        let data1 = Data("asset1".utf8)
        let data2 = Data("asset2".utf8)
        await cache.store(data: data1, for: "key_alpha")
        await cache.store(data: data2, for: "key_beta")
        let rAlpha = await cache.data(for: "key_alpha")
        XCTAssertEqual(rAlpha, data1)
        let rBeta = await cache.data(for: "key_beta")
        XCTAssertEqual(rBeta,  data2)
    }
}
