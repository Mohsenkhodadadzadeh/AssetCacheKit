//
//  RequestDeduplicator.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/20/26.
//

import Foundation

/// An actor responsible for deduplicating in-flight network requests.
/// If multiple requests ask for the same URL, only one network call is made.
public actor RequestDeduplicator {
    
    private var inFlightTasks: [URL: Task<Data, Error>] = [:]
    
    public init() {}
    
    /// Executes the given operation only if there isn't an ongoing task for the URL.
    /// - Parameters:
    ///   - url: The target URL.
    ///   - operation: The network operation to execute.
    /// - Returns: The resulting Data.
    public func deduplicate(url: URL, operation: @escaping @Sendable () async throws -> Data) async throws -> Data {
        if let existingTask = inFlightTasks[url] {
            return try await existingTask.value
        }
        
        let task = Task {
            try await operation()
        }
        
        inFlightTasks[url] = task
        
        defer { inFlightTasks[url] = nil }
        
        return try await task.value
    }
}
