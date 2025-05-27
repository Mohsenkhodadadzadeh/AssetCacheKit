# AssetCacheKit

![Alt text](readmeAssets/AssetCacheKit.png)

[![Swift](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square)](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_15.0-yellow?style=flat-square)](https://img.shields.io/badge/Platforms-iOS_15.0-yellow?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-macOS_12.0-green?style=flat-square)](https://img.shields.io/badge/Platforms-macOS_12.0-green?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-tvOS_15.0-khaki?style=flat-square)](https://img.shields.io/badge/Platforms-tvOS_15.0-khaki?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-watchOS_8.0-red?style=flat-square)](https://img.shields.io/badge/Platforms-watchOS_8.0-red?style=flat-square)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)

**A Swift package that provides a generic and efficient way to asynchronously load and cache assets in SwiftUI applications.**

## Overview
`AssetCacheKit` is a powerful and flexible Swift package that provides an elegant solution for asynchronous asset loading and caching in SwiftUI applications. It offers a clean, protocol-oriented approach to handle various types of assets (images, PDFs, SVGs, etc.) with built-in caching capabilities and error handling.


## Features
 - **Generic Asset Loading:** Supports loading any type of asset by implementing the `AssetLoader` protocol.
 - **Caching:** Leverages `URLCache` for optimized performance by caching loaded assets.
 - **Placeholder & Error Handling:** Provides a consistent approach to displaying placeholders while loading and managing errors.
 - **SwiftUI Integration:** Integrates seamlessly with SwiftUI views using the `AssetCacheKit` view.
 - **Asset Types Support:** Currently supports images and PDFs, with plans for SVG, Video, and MP3 support in the future.
 


## Benefits
 - **Improved Performance:** Caching reduces network requests and improves loading times.
 - **Simplified Code:** Streamlines asynchronous asset loading logic and error handling.
 - **Enhanced User Experience:** Provides a smooth user experience by avoiding unnecessary UI stalls during loading in addition of avoids UI stalls with placeholder views and error handling during asset loading.
 - 🚀 Asynchronous asset loading with SwiftUI integration
 - 💾 Built-in caching mechanism
 - 🎨 Customizable placeholder views during loading
 - ⚠️ Elegant error handling
 - 🔄 Automatic retry mechanism
 - 📱 Support for multiple platforms (iOS, macOS, tvOS, watchOS)
 - 🧩 Protocol-oriented design for easy extensibility
 
## Requirements

- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 8.0+
- Swift 6.0+

## Installation

### Swift Package Manager

Add AssetCacheKit to your project through Xcode:

1. File > Add Packages...
2. Enter the package URL: `https://github.com/Mohsenkhodadadzadeh/AssetCacheKit`
3. Select the version you want to use

Or add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Mohsenkhodadadzadeh/AssetCacheKit", from: "2.0.0")
]
```


## Usage
**Loading Images**
```Swift
import AssetCacheKit
import SwiftUI

struct ContentView: View {
    var body: some View {
    
    AssetCacheKit(loader: CachedImageLoader(url: URL(string: "https://example.come/example.png")))
        { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            ProgressView()
        } error: { error in
            Text("Error is \(error.localizedDescription)")
        }
    }
}
```

In this example, `AssetCacheKit` is used to load an image from a URL. You provide a `CachedImageLoader` instance as the loader, a closure to build the content view with the loaded image, and a closure to display a placeholder during loading.

**Loading PDFs with CachedPDFLoader**
```Swift
import AssetCacheKit
import SwiftUI

struct ContentView: View {
    @State private var totalPage: Int? = nil
    @State private var currentPage: Int? = nil
    var body: some View {
    
        AssetCacheKit(loader: CachedPDFLoader(url: URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")))
        { pdf in
            pdf
                .autoScale(true)               // Automatically scales the PDF to fit the view
                .displayMode(.twoUpContinuous) // Displays the PDF with two pages side by side and continuous scrolling
                .displayDirection(.vertical)   // Makes the PDF scroll vertically
                .totalPage($totalPage)         // Binds the total number of pages in the PDF to a state variable
                .currentPage($currentPage)     // Binds the current page number to a state variable
        } placeholder: {
            Text("Loading...")
        } error: { err in
            Text("Error is: \(err)")
        }
        if let totalPage, let currentPage {
            Text("Page \(currentPage) from \(totalPage)")
        }
    }
}

```

The CachedPDFLoader works similarly to the image loader but for PDF documents. It loads and caches the PDF file and displays it in a SwiftUI view. Here are some view modifiers you can apply:
 - **autoScale(_):** Automatically scales the PDF to fit the view’s dimensions.
 - **displayMode(_:):** Sets how the PDF pages are displayed (e.g., `.singlePage`, `.twoUpContinuous`).
 - **displayDirection(_:):** Specifies the scroll direction of the PDF pages (e.g., `.horizontal`, `.vertical`).
 - **totalPage(_:):** Binds to an `Int?` to provide the total number of pages in the PDF document. This binding is updated automatically when the PDF is fully loaded.
 - **currentPage(_:):** Binds to an `Int?` to track the currently displayed page number. This binding is updated as the user navigates through the PDF pages.
 
These modifiers allow for customization of how the PDF is presented and interacted with in your app.


**Loading SVGs with CachedSVGLoader**
```Swift
import AssetCacheKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        AssetCacheKit(loader: CachedSVGLoader(url: URL(string: "https://example.com/example.svg"))) { image in
                image
                    .resizable()
                    .frame(width: 350, height: 200)
        } placeholder: {
            ProgressView()
        } error: { err in
            Text(err.localizedDescription)
        }
    }
}
```
CachedSVGLoader enables loading and caching of **SVG images** from remote URLs. It integrates seamlessly with **AssetCacheKit**, ensuring efficient retrieval and rendering of SVG assets while reducing redundant network requests.



## Custom Asset Loaders

Create your own asset loader by conforming to the `AssetLoader` protocol:

```swift
struct CustomAssetLoader: AssetLoader {
    var url: URL?
    
    func loadAsset() async throws -> YourAssetType {
        // Implement your custom loading logic here
    }
}
```

### Asset Repository

The package includes a repository layer for managing asset caching and network operations:

```swift
class YourCustomRepository: AssetRepository {
    func loadAsset(with url: URL?) async throws -> Data {
        // Implement loading logic
    }
    
    func fetchCachedAsset(for urlRequest: URLRequest) -> Data? {
        // Implement cache retrieval
    }
    
    func cacheAsset(response: HTTPURLResponse, data: Data, for urlRequest: URLRequest) {
        // Implement caching logic
    }
    
    func clearCache(for urlRequest: URLRequest) {
        // Implement cache clearing
    }
}
```

## Architecture

AssetCacheKit follows a clean architecture pattern with three main layers:

- **Presentation**: SwiftUI views and view models
- **Domain**: Core business logic, protocols, and use cases
- **Data**: Implementation of repositories and data sources

### Key Components

- `AssetCacheKit`: The main SwiftUI view that handles the asset loading UI
- `AssetLoader`: Protocol defining the contract for asset loading
- `AssetRepository`: Protocol for managing asset storage and retrieval
- `AsyncPhase`: Enum representing the different states of asset loading

## Best Practices

1. **Memory Management**
   - Assets are automatically cached and managed
   - Large assets are handled efficiently to prevent memory issues

2. **Error Handling**
   - Comprehensive error handling with custom error types
   - User-friendly error messages and recovery options

3. **Performance**
   - Asynchronous loading to prevent UI blocking
   - Efficient caching mechanism for faster subsequent loads


## Contribution
We welcome contributions to improve `AssetCacheKit`. Feel free to submit pull requests that enhance functionality, fix bugs, or add documentation.

## License

AssetCacheKit is available under the MIT license. See the LICENSE file for more info.
