# AssetCacheKit

[![Swift](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square)](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_15.0-yellow?style=flat-square)](https://img.shields.io/badge/Platforms-iOS_15.0-yellow?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-macOS_12.0-green?style=flat-square)](https://img.shields.io/badge/Platforms-macOS_12.0-green?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-tvOS_15.0-khaki?style=flat-square)](https://img.shields.io/badge/Platforms-tvOS_15.0-khaki?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-watchOS_8.0-red?style=flat-square)](https://img.shields.io/badge/Platforms-watchOS_8.0-red?style=flat-square)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)

**A Swift package that provides a generic and efficient way to asynchronously load and cache assets in SwiftUI applications.**

## Overview
`AssetCacheKit` simplifies the management of asynchronous asset loading in your SwiftUI projects. It offers a reusable and well-documented solution for handling various asset types (images) with built-in caching (SVG, Video, and mp3 will be added), placeholder/error handling, and seamless integration with SwiftUI views.

## Features
 - **Generic Asset Loading:** Supports loading any type of asset by implementing the `AssetLoader` protocol.
 - **Caching:** Leverages `URLCache` for optimized performance by caching loaded assets.
 - **Placeholder & Error Handling:** Provides a consistent approach to displaying placeholders while loading and managing errors.
 - **SwiftUI Integration:** Integrates seamlessly with SwiftUI views using the `AssetCacheKit` view.

## Benefits
 - **Improved Performance:** Caching reduces network requests and improves loading times.
 - **Simplified Code:** Streamlines asynchronous asset loading logic and error handling.
 - **Enhanced User Experience:** Provides a smooth user experience by avoiding unnecessary UI stalls during loading.

## Installation
Integrate `AssetCacheKit` into your project using Swift Package Manager (SPM):
1. In Xcode, navigate to File > Add Packages....
2. Search for Mohsenkhodadadzadeh/AssetCacheKit (replace with your actual username and repository name).
3. Select the package and add it to your project.

## Usage
**Loading Images**
```Swift
import AssetCacheKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        AssetCacheKit(
            loader: CachedImageLoader(url: URL(string: "https://example.com/image.png")),
            content: { image in
                image
                    .resizable()
                    .scaledToFit()
            },
            placeholder: {
                ProgressView()
            },
            error: { error in
                Text("Error: \(error.localizedDescription)")
            }
        )
    }
}
```

In this example, `AssetCacheKit` is used to load an image from a URL. You provide a `CachedImageLoader` instance as the loader, a closure to build the content view with the loaded image, and a closure to display a placeholder during loading.

## Custom Asset Loaders
For assets beyond images, create a custom type conforming to the `AssetLoader` protocol. This type defines the specific logic for fetching your desired asset type.

## Contribution
We welcome contributions to improve `AssetCacheKit`. Feel free to submit pull requests that enhance functionality, fix bugs, or add documentation.

