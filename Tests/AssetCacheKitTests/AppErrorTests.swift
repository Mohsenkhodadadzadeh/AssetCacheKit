//
//  AppErrorTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

final class AppErrorTests: XCTestCase {
 
    // MARK: AssetLoadingError equality
    func test_assetLoading_sameCase_equal() {
        XCTAssertEqual(AppError.assetLoading(.invalidURL), AppError.assetLoading(.invalidURL))
        XCTAssertEqual(AppError.assetLoading(.invalidImageData), AppError.assetLoading(.invalidImageData))
        XCTAssertEqual(AppError.assetLoading(.invalidPDFData), AppError.assetLoading(.invalidPDFData))
        XCTAssertEqual(AppError.assetLoading(.invalidSVGData), AppError.assetLoading(.invalidSVGData))
        XCTAssertEqual(AppError.assetLoading(.invalidResponse), AppError.assetLoading(.invalidResponse))
    }
 
    func test_assetLoading_differentCase_notEqual() {
        XCTAssertNotEqual(AppError.assetLoading(.invalidURL), AppError.assetLoading(.invalidImageData))
    }
 
    // MARK: NetworkError equality
    func test_network_sameCase_equal() {
        XCTAssertEqual(AppError.network(.noConnection), AppError.network(.noConnection))
        XCTAssertEqual(AppError.network(.timeout), AppError.network(.timeout))
        XCTAssertEqual(AppError.network(.badServerResponse(statusCode: 404)),
                       AppError.network(.badServerResponse(statusCode: 404)))
    }
 
    func test_network_differentStatusCode_notEqual() {
        XCTAssertNotEqual(AppError.network(.badServerResponse(statusCode: 404)),
                          AppError.network(.badServerResponse(statusCode: 500)))
    }
 
    func test_network_differentCase_notEqual() {
        XCTAssertNotEqual(AppError.network(.noConnection), AppError.network(.timeout))
    }
 
    // MARK: Cross-category inequality
    func test_assetLoading_vs_network_notEqual() {
        XCTAssertNotEqual(AppError.assetLoading(.invalidURL), AppError.network(.noConnection))
    }
 
    // MARK: All NetworkError cases compile correctly
    func test_allNetworkErrorCases_accessible() {
        let cases: [NetworkError] = [
            .noConnection,
            .timeout,
            .cannotFindHost,
            .cannotConnectToHost,
            .badURL,
            .cancelled,
            .networkConnectionLost,
            .dnsLookupFailed,
            .secureConnectionFailed,
            .userCancelledAuthentication,
            .appTransportSecurityRequiresSecureConnection,
            .badServerResponse(statusCode: 429)
        ]
        XCTAssertEqual(cases.count, 12)
    }
}
 
