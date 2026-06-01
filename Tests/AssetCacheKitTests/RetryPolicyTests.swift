//
//  RetryPolicyTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

final class RetryPolicyTests: XCTestCase {
 
    func test_defaultPolicy_hasExpectedValues() {
        let p = RetryPolicy.default
        XCTAssertEqual(p.maxAttempts, 3)
        XCTAssertEqual(p.initialDelay, 0.5, accuracy: 0.001)
        XCTAssertEqual(p.multiplier, 2.0, accuracy: 0.001)
    }
 
    func test_nonePolicy_hasSingleAttempt() {
        let p = RetryPolicy.none
        XCTAssertEqual(p.maxAttempts, 1)
    }
 
    func test_customPolicy_storedCorrectly() {
        let p = RetryPolicy(maxAttempts: 5, initialDelay: 1.0, multiplier: 3.0)
        XCTAssertEqual(p.maxAttempts, 5)
        XCTAssertEqual(p.initialDelay, 1.0, accuracy: 0.001)
        XCTAssertEqual(p.multiplier, 3.0, accuracy: 0.001)
    }
}
