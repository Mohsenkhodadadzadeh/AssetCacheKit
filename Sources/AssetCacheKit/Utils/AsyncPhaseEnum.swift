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
    
    /// Compares two `AsyncPhase` values **by case, not by payload**.
    ///
    /// - Important: Any two `.success` values compare equal regardless of the
    ///   assets they carry, and any two `.failure` values compare equal when
    ///   their `localizedDescription`s match.  `Content` is not constrained to
    ///   `Equatable` — the framework's own assets (`Image`,
    ///   `PDFKitRepresentedView`) do not conform — so the payload cannot be
    ///   inspected here.
    ///
    ///   Do not use this operator to detect that a *different* asset finished
    ///   loading, and do not feed an `AsyncPhase` to `onChange(of:)`,
    ///   `.animation(_:value:)`, or any other API that suppresses work when
    ///   values compare equal: a transition from one loaded asset to another
    ///   would be dropped.
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
