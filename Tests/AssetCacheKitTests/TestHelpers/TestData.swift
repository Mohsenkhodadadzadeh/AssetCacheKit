import Foundation
@testable import AssetCacheKit

enum TestData {
    /// Test URLs
    static let validURL = URL(string: "https://example.com/image.jpg")!
    static let invalidURL = URL(string: "invalid://url")!
    
    /// Test Data
    static let validImageData = "test image data".data(using: .utf8)!
    static let validPDFData = "test PDF data".data(using: .utf8)!
    static let validSVGData = "test SVG data".data(using: .utf8)!
    
    /// Test Responses
    static func mockHTTPResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "image/jpeg"]
        )!
    }
    
    /// Network Errors
    static let networkErrors: [(code: Int, error: AppError)] = [
        (-1009, .network(.noConnection)),
        (-1001, .network(.timeout)),
        (-1003, .network(.cannotFindHost)),
        (-1004, .network(.cannotConnectToHost)),
        (-1000, .network(.badURL)),
        (-999,  .network(.cancelled)),
        (-1005, .network(.networkConnectionLost)),
        (-1006, .network(.dnsLookupFailed)),
        (-1200, .network(.secureConnectionFailed)),
        (-1012, .network(.userCancelledAuthentication)),
        (-1022, .network(.appTransportSecurityRequiresSecureConnection)),
        (400,   .network(.badServerResponse(statusCode: 400))),
        (401,   .network(.badServerResponse(statusCode: 401))),
        (403,   .network(.badServerResponse(statusCode: 403))),
        (404,   .network(.badServerResponse(statusCode: 404))),
        (500,   .network(.badServerResponse(statusCode: 500)))
    ]
    
    /// Asset Loading Errors
    static let assetErrors: [AppError] = [
        .assetLoading(.invalidURL),
        .assetLoading(.invalidImageData),
        .assetLoading(.invalidResponse)
    ]
    
    /// Test URLRequests
    static func mockURLRequest(url: URL) -> URLRequest {
        URLRequest(url: url)
    }
} 
