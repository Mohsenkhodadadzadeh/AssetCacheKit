//
//  AsyncPhase.swift
//  AssetCacheKit
//
//  Created by mohsen on 12/26/24.
//

import SwiftUI

/// An enumeration representing the different phases of an asynchronous operation.
public enum AsyncPhase<Content>: Equatable {
    /// The operation has not yet started.
    case empty
    
    /// The operation has completed successfully with a result.
    case success(Content)
    
    /// The operation has failed with an error.
    case failure(Error)
    
    /// Compares two AsyncPhase values for equality.
    public static func == (lhs: AsyncPhase<Content>, rhs: AsyncPhase<Content>) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.success( _), .success( _)):
            return true
        case (.failure(let leftError), .failure(let rightError)):
            // Compare errors by their localized description or type
            return leftError.localizedDescription == rightError.localizedDescription
        default:
            return false
        }
    }
}
