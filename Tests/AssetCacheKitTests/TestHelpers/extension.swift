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
    ///
    /// The write happens inline on the actor, so by the time `await` returns the
    /// bytes are guaranteed to be visible to the next `data(for:)` call.
    /// Detaching it into an unawaited `Task` instead would let the loader run
    /// first and fall through to a *real* network request, making every test
    /// that primes the cache both slow and non-deterministic.
    func primeMemory(url: URL, data: Data) {
        storeInMemory(data, for: url)
    }
}
