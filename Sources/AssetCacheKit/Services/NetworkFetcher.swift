//
//  NetworkFetcher.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/25/26.
//

import Foundation

/// Downloads asset data from the network with configurable retry logic.
///
/// `NetworkFetcher` is a caseless `enum` used as a namespace for its `static` API;
/// it is not intended to be instantiated.
///
/// Failed requests are retried up to ``RetryPolicy/maxAttempts`` times using an
/// exponential back-off schedule.  `URLError` values thrown by `URLSession` are
/// mapped to strongly-typed ``AppError/network(_:)`` cases before propagating.
///
/// ## Retry schedule
///
/// For ``RetryPolicy/default`` (`maxAttempts: 3`, `initialDelay: 0.5 s`, `multiplier: 2.0`):
///
/// | Attempt | Delay before next attempt |
/// |---------|--------------------------|
/// | 1st | — |
/// | 2nd | 0.5 s |
/// | 3rd | 1.0 s |
/// | — | throws last error |
///
/// ## Error mapping
///
/// `URLSession` reports transport-level failures as `URLError`.  `NetworkFetcher`
/// catches these and translates them to the framework's own ``AppError/network(_:)``
/// type so callers never need to import or pattern-match on `URLError` directly.
enum NetworkFetcher {

    // MARK: - Public

    /// Downloads data from `url`, retrying on transient failures.
    ///
    /// - Parameters:
    ///   - url: The remote location to fetch.
    ///   - policy: The retry strategy to apply on failure.
    /// - Returns: The raw response body.
    /// - Throws: ``AppError/network(_:)`` or ``AppError/assetLoading(_:)`` after
    ///   all retry attempts are exhausted.
    static func fetch(url: URL, policy: RetryPolicy) async throws -> Data {
        var attempt = 0
        var delay   = policy.initialDelay

        while true {
            do {
                return try await download(url: url)
            } catch {
                attempt += 1
                guard attempt < policy.maxAttempts, isRetryable(error) else { throw error }
                try await sleep(seconds: delay)
                delay *= policy.multiplier
            }
        }
    }

    // MARK: - Private

    /// Reports whether re-issuing the request could plausibly succeed.
    ///
    /// Backing off and trying again only helps for *transient* failures.  A
    /// `404`, a malformed URL, or a cancelled task will fail identically on
    /// every attempt, so retrying them just delays the error the caller is
    /// already going to get — by 1.5 s under the default policy — while holding
    /// the request open and burning battery.
    private static func isRetryable(_ error: Error) -> Bool {
        // Honour cooperative cancellation immediately.
        if error is CancellationError { return false }

        guard let appError = error as? AppError else {
            // Unknown error shape — assume transient rather than failing early.
            return true
        }

        switch appError {
        case .network(let networkError):
            switch networkError {
            case .timeout,
                 .noConnection,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .networkConnectionLost,
                 .dnsLookupFailed:
                return true

            case .badURL,
                 .cancelled,
                 .secureConnectionFailed,
                 .userCancelledAuthentication,
                 .appTransportSecurityRequiresSecureConnection:
                return false

            case .badServerResponse(let statusCode):
                // A negative value is not an HTTP status at all: `network(from:)`
                // funnels unmapped `URLError` codes (which are negative) through
                // this same case, and those are transport failures worth
                // retrying.
                if statusCode < 0 { return true }
                // 5xx and 408/429 are worth another attempt; other 4xx are not.
                return statusCode >= 500 || statusCode == 408 || statusCode == 429
            }

        case .assetLoading:
            // Malformed or undecodable payloads do not improve on a retry.
            return false

        case .unknown:
            return true
        }
    }

    private static func download(url: URL) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let http = response as? HTTPURLResponse else {
                throw AppError.assetLoading(.invalidResponse)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw AppError.network(.badServerResponse(statusCode: http.statusCode))
            }
            return data

        } catch let urlError as URLError {
            throw AppError.network(from: urlError)
        }
    }

    private static func sleep(seconds: TimeInterval) async throws {
        guard seconds > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - URLError → AppError

private extension AppError {
    /// Maps a `URLError` to the nearest ``AppError/network(_:)`` case.
    static func network(from urlError: URLError) -> AppError {
        switch urlError.code {
        case .notConnectedToInternet:
            return .network(.noConnection)
        case .timedOut:
            return .network(.timeout)
        case .cannotFindHost:
            return .network(.cannotFindHost)
        case .cannotConnectToHost:
            return .network(.cannotConnectToHost)
        case .badURL:
            return .network(.badURL)
        case .cancelled:
            return .network(.cancelled)
        case .networkConnectionLost:
            return .network(.networkConnectionLost)
        case .dnsLookupFailed:
            return .network(.dnsLookupFailed)
        case .secureConnectionFailed:
            return .network(.secureConnectionFailed)
        case .userCancelledAuthentication:
            return .network(.userCancelledAuthentication)
        case .appTransportSecurityRequiresSecureConnection:
            return .network(.appTransportSecurityRequiresSecureConnection)
        default:
            return .network(.badServerResponse(statusCode: urlError.code.rawValue))
        }
    }
}
