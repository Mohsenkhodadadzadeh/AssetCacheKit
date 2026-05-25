//
//  PlatformImage.swift
//  AssetCacheKit
//
//  Created by Mohsen Khodadadzadeh on 5/25/26.
//

#if os(macOS)
import AppKit

/// A platform-agnostic alias for the native image type.
///
/// Resolves to `NSImage` on macOS and `UIImage` on iOS, tvOS, and watchOS.
/// Use `PlatformImage` in shared code to avoid conditional compilation at every call site.
typealias PlatformImage = NSImage
#else
import UIKit

/// A platform-agnostic alias for the native image type.
///
/// Resolves to `NSImage` on macOS and `UIImage` on iOS, tvOS, and watchOS.
/// Use `PlatformImage` in shared code to avoid conditional compilation at every call site.
typealias PlatformImage = UIImage
#endif
