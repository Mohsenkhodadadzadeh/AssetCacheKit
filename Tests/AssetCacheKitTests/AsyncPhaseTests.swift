//
//  AsyncPhaseTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

final class AsyncPhaseTests: XCTestCase {
 
    func test_empty_equalsEmpty() {
        let a: AsyncPhase<String> = .empty
        let b: AsyncPhase<String> = .empty
        XCTAssertEqual(a, b)
    }
 
    func test_success_equalsSuccess_regardlessOfValue() {
        // NOTE: .success equality intentionally ignores the associated value
        // because assets like Image/PDFView don't conform to Equatable.
        let a: AsyncPhase<String> = .success("foo")
        let b: AsyncPhase<String> = .success("bar")
        XCTAssertEqual(a, b, "Two .success cases should be equal (value ignored)")
    }
 
    func test_failure_equalsFailure_whenSameDescription() {
        let err = AppError.assetLoading(.invalidURL)
        let a: AsyncPhase<String> = .failure(err)
        let b: AsyncPhase<String> = .failure(err)
        XCTAssertEqual(a, b)
    }
 
    func test_empty_notEqual_toSuccess() {
        let a: AsyncPhase<String> = .empty
        let b: AsyncPhase<String> = .success("x")
        XCTAssertNotEqual(a, b)
    }
 
    func test_success_notEqual_toFailure() {
        let a: AsyncPhase<String> = .success("x")
        let b: AsyncPhase<String> = .failure(AppError.assetLoading(.invalidURL))
        XCTAssertNotEqual(a, b)
    }
}
