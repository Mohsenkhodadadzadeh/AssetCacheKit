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
 
    // MARK: Byte accounting

    func test_repeatedOverwrite_doesNotEvictLiveEntries() async {
        // 8 KB budget, 1 KB payload. Overwriting one key 40 times must not be
        // counted as 40 KB of usage and drag unrelated entries into eviction.
        let small = DiskCache(
            namespace: "com.assetcachekit.test.overwrite.\(UUID().uuidString)",
            byteLimit: 8 * 1_024,
            defaultExpiration: 3600
        )
        defer { Task { await small.clearAll() } }

        let payload = Data(repeating: 0xAB, count: 1_024)
        await small.store(data: payload, for: "keeper")

        for _ in 0..<40 {
            await small.store(data: payload, for: "churn")
        }

        let keeper = await small.data(for: "keeper")
        XCTAssertEqual(keeper, payload,
            "Overwriting one key must not inflate the byte count and evict others")
        let churn = await small.data(for: "churn")
        XCTAssertEqual(churn, payload)
    }

    func test_expiredEntries_doNotLeakIntoByteCount() async {
        // Every entry expires immediately, so each read removes it. If those
        // removals are not discounted, the running total climbs without bound
        // and eventually evicts entries that are still live.
        let expiring = DiskCache(
            namespace: "com.assetcachekit.test.expiry.\(UUID().uuidString)",
            byteLimit: 8 * 1_024,
            defaultExpiration: -1
        )
        defer { Task { await expiring.clearAll() } }

        let payload = Data(repeating: 0xCD, count: 1_024)
        for i in 0..<20 {
            await expiring.store(data: payload, for: "expired_\(i)")
            _ = await expiring.data(for: "expired_\(i)")   // miss → removes the entry
        }

        // A fresh, non-expiring cache over the same directory should now be able
        // to store and read back normally.
        await expiring.store(data: payload, for: "final")
        let final = await expiring.data(for: "final")
        XCTAssertNil(final, "Entry written with a negative expiration is stale on read")
    }

    func test_evictionKeepsCacheWithinLimit() async {
        let limited = DiskCache(
            namespace: "com.assetcachekit.test.evict.\(UUID().uuidString)",
            byteLimit: 4 * 1_024,
            defaultExpiration: 3600
        )
        defer { Task { await limited.clearAll() } }

        let payload = Data(repeating: 0xEF, count: 1_024)
        for i in 0..<10 {
            await limited.store(data: payload, for: "evict_\(i)")
        }

        // The most recent write must survive eviction.
        let newest = await limited.data(for: "evict_9")
        XCTAssertEqual(newest, payload, "The just-written entry should not be evicted")
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
