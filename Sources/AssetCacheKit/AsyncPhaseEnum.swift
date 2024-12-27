//
//  AsyncPhase.swift
//  AssetCacheKit
//
//  Created by mohsen on 12/26/24.
//

import SwiftUI

/// An enumeration representing the different phases of an asynchronous operation.
public enum AsyncPhase<Content: Sendable>: Sendable {
    /// The operation has not yet started.
    case empty
    
    /// The operation has completed successfully with a result.
    case success(Content)
    
    /// The operation has failed with an error.
    case failure(Error)
}
