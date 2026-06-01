//
//  MemoryCacheEntryTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

final class MemoryCacheEntryTests: XCTestCase {
 
#if os(macOS)
    private func makeImage() -> PlatformImage {
        let img = NSImage(size: NSSize(width: 1, height: 1))
        return img
    }
#else
    private func makeImage() -> PlatformImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
#endif
 
    func test_isExpired_false_whenFutureExpiration() {
        let entry = MemoryCacheEntry(image: makeImage(), cost: 100, expiration: 60)
        XCTAssertFalse(entry.isExpired)
    }
 
    func test_isExpired_true_whenPastExpiration() {
        let entry = MemoryCacheEntry(image: makeImage(), cost: 100, expiration: -1)
        XCTAssertTrue(entry.isExpired, "Entry with expiration -1s should already be expired")
    }
 
    func test_cost_storedCorrectly() {
        let entry = MemoryCacheEntry(image: makeImage(), cost: 4096, expiration: 3600)
        XCTAssertEqual(entry.cost, 4096)
    }
 
    func test_expiresAt_approximatelyNowPlusExpiration() {
        let before = Date()
        let entry  = MemoryCacheEntry(image: makeImage(), cost: 0, expiration: 100)
        let after  = Date()
        let expectedMin = before.addingTimeInterval(100)
        let expectedMax = after.addingTimeInterval(100)
        XCTAssertGreaterThanOrEqual(entry.expiresAt, expectedMin)
        XCTAssertLessThanOrEqual(entry.expiresAt, expectedMax)
    }
}
 
