//
//  DiskCacheMetadataTests.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit

final class DiskCacheMetadataTests: XCTestCase {
 
    func test_roundTrip_throughJSONCodable() throws {
        let now  = Date()
        let meta = DiskCacheMetadata(
            key: "test_key",
            createdAt: now,
            expiresAt: now.addingTimeInterval(3600),
            fileSize: 1024
        )
        let encoded = try JSONEncoder().encode(meta)
        let decoded = try JSONDecoder().decode(DiskCacheMetadata.self, from: encoded)
 
        XCTAssertEqual(decoded.key, meta.key)
        XCTAssertEqual(decoded.fileSize, meta.fileSize)
        // Date precision may differ slightly due to JSON encoding
        XCTAssertEqual(decoded.createdAt.timeIntervalSince1970,
                       meta.createdAt.timeIntervalSince1970,
                       accuracy: 0.001)
        XCTAssertEqual(decoded.expiresAt.timeIntervalSince1970,
                       meta.expiresAt.timeIntervalSince1970,
                       accuracy: 0.001)
    }
 
    func test_corruptJSON_throwsOnDecode() {
        let corrupt = Data("{ not json }".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(DiskCacheMetadata.self, from: corrupt))
    }
}
