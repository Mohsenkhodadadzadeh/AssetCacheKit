//
//  Errors.swift
//  AssetCacheKit
//
//  Created by mohsen on 5/23/25.
//

import Foundation

/// Errors that can be thrown by `CachedImageLoader`.
 public enum AssetLoadingError: Error {
     
     /// The provided URL was invalid.
     case invalidURL
     
     /// The server returned an invalid response (non-2xx status code).
     case invalidResponse
     
     /// The received data could not be converted to an image.
     case invalidImageData
     
     /// The received data could not be converted to a PDF document
     case invalidPDFData
     
     /// The received data could not be converted to a SVG image.
     case invalidSVGData
     
 }


// Another distinct error enum, perhaps for network-level issues
public enum NetworkError: Error, Equatable {
    case noConnection
    case timeout
    case cannotFindHost
    case cannotConnectToHost
    case badURL
    case cancelled
    case networkConnectionLost
    case dnsLookupFailed
    case secureConnectionFailed
    case userCancelledAuthentication
    case appTransportSecurityRequiresSecureConnection
    case badServerResponse(statusCode: Int)
}

public enum AppError: Error, Equatable {
    case assetLoading(AssetLoadingError) // Wraps an AssetLoadingError
    case network(NetworkError)         // Wraps a NetworkError
    case unknown(Error)                // Handle unexpected errors (needs custom Equatable)

  public static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.assetLoading(let lhsError), .assetLoading(let rhsError)):
            return lhsError == rhsError
        case (.network(let lhsError), .network(let rhsError)):
            return lhsError == rhsError
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
