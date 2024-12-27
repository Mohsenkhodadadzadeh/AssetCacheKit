//
//  AssetLoader.swift
//  AssetCacheKit
//
//  Created by mohsen on 12/26/24.
//

import SwiftUI

/// A protocol defining the contract for an asynchronous asset loader.
///
/// Types conforming to this protocol are responsible for fetching assets of a specific type.
public protocol AssetLoader: Sendable {
    /// The type of the asset being loaded.
    associatedtype Asset: Sendable
    
    /// Asynchronously loads the asset.
    ///
    /// - Returns: The loaded asset.
    /// - Throws: An error if the asset could not be loaded.
    func loadAsset() async throws -> Asset
}
