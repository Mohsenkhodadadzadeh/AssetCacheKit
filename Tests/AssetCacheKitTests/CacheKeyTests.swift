//
//  CacheKeyTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

final class CacheKeyTests: XCTestCase {
 
    private let urlA = URL(string: "https://cdn.example.com/photos/abc123.jpg")!
    private let urlB = URL(string: "https://cdn.example.com/photos/abc456.jpg")!
 
    func test_sameURL_sameScale_noTargetSize_areEqual() {
        let k1 = CacheKey(url: urlA, scale: 1, targetSize: nil)
        let k2 = CacheKey(url: urlA, scale: 1, targetSize: nil)
        XCTAssertEqual(k1, k2)
    }
 
    func test_differentURL_notEqual() {
        let k1 = CacheKey(url: urlA, scale: 1, targetSize: nil)
        let k2 = CacheKey(url: urlB, scale: 1, targetSize: nil)
        XCTAssertNotEqual(k1, k2)
    }
 
    func test_differentScale_notEqual() {
        let k1 = CacheKey(url: urlA, scale: 1, targetSize: nil)
        let k2 = CacheKey(url: urlA, scale: 2, targetSize: nil)
        XCTAssertNotEqual(k1, k2)
    }
 
    func test_differentTargetSize_notEqual() {
        let k1 = CacheKey(url: urlA, scale: 1, targetSize: CGSize(width: 80, height: 80))
        let k2 = CacheKey(url: urlA, scale: 1, targetSize: CGSize(width: 160, height: 160))
        XCTAssertNotEqual(k1, k2)
    }
 
    func test_withTargetSize_vs_withoutTargetSize_notEqual() {
        let k1 = CacheKey(url: urlA, scale: 1, targetSize: CGSize(width: 80, height: 80))
        let k2 = CacheKey(url: urlA, scale: 1, targetSize: nil)
        XCTAssertNotEqual(k1, k2)
    }

    func test_diskIdentifier_isStable() {
        let k = CacheKey(url: urlA, scale: 2, targetSize: CGSize(width: 40, height: 40))
        XCTAssertEqual(k.diskIdentifier, k.diskIdentifier)
    }
 
    func test_diskIdentifier_nonEmpty() {
        let k = CacheKey(url: urlA, scale: 1, targetSize: nil)
        XCTAssertFalse(k.diskIdentifier.isEmpty)
    }
 
    func test_hashValue_matchesEquality() {
        let k1 = CacheKey(url: urlA, scale: 2, targetSize: CGSize(width: 100, height: 100))
        let k2 = CacheKey(url: urlA, scale: 2, targetSize: CGSize(width: 100, height: 100))
        XCTAssertEqual(k1.hashValue, k2.hashValue)
    }
 
    func test_longURL_diskIdentifier_bounded() {
        let longURL = URL(string: "https://example.com/" + String(repeating: "a", count: 300) + ".jpg")!
        let k = CacheKey(url: longURL, scale: 1, targetSize: nil)
        XCTAssertLessThanOrEqual(k.diskIdentifier.count, 250,
            "diskIdentifier should not exceed filesystem path limits")
    }
}
