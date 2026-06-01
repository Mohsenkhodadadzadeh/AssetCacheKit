//
//  AssetCacheConfigurationTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

final class AssetCacheConfigurationTests: XCTestCase {
 
    func test_defaultSingleton_matchesInitDefaults() {
        let d = AssetCacheConfiguration.default
        let i = AssetCacheConfiguration()
        XCTAssertEqual(d.rawDataMemoryByteLimit, i.rawDataMemoryByteLimit)
        XCTAssertEqual(d.diskByteLimit, i.diskByteLimit)
        XCTAssertEqual(d.defaultExpiration, i.defaultExpiration, accuracy: 0.001)
    }
 
    func test_custom_valuesStoredCorrectly() {
        let c = AssetCacheConfiguration(
            rawDataMemoryByteLimit: 5 * 1_024 * 1_024,
            diskByteLimit: 50 * 1_024 * 1_024,
            defaultExpiration: 3 * 24 * 3600,
            retryPolicy: .none
        )
        XCTAssertEqual(c.rawDataMemoryByteLimit, 5 * 1_024 * 1_024)
        XCTAssertEqual(c.diskByteLimit, 50 * 1_024 * 1_024)
        XCTAssertEqual(c.defaultExpiration, 3 * 24 * 3600, accuracy: 0.001)
        XCTAssertEqual(c.retryPolicy.maxAttempts, 1)
    }
}
