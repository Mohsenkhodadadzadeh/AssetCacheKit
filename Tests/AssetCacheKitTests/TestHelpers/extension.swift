//
//  extension.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 6/1/26.
//

import XCTest
import SwiftUI
import PDFKit
@testable import AssetCacheKit


// Adds a `primeMemory` hook so tests can inject bytes into the memory
// layer without going through the network, keeping tests fast and
// deterministic. This extension is test-only; do NOT ship it in production.
 
extension AssetCache {
    /// Seeds the memory layer directly — for tests only.
    func primeMemory(url: URL, data: Data) {
        // Access the private NSCache via the existing storeInMemory method.
        // Since it's private we call the actor-isolated wrapper via an actor hop.
        Task { await _primeMemoryInternal(url: url, data: data) }
    }
 
    /// Actor-isolated internal helper called by the test-only `primeMemory`.
    func _primeMemoryInternal(url: URL, data: Data) {
        // Directly write to memory by calling the existing private method.
        // We expose it as internal here purely for test seeding.
        storeInMemory(data, for: url)
    }
}
