// The Swift Programming Language
// https://docs.swift.org/swift-book


import SwiftUI

// MARK: - AssetCacheKit

/// A generic SwiftUI view that asynchronously loads assets using a provided `AssetLoader` and displays them with a placeholder and error handling.
///
/// `AssetCacheKit` simplifies the process of loading various types of assets, such as images, videos, or data, by abstracting the loading logic behind the `AssetLoader` protocol. It provides a consistent way to handle loading states, display placeholders while loading, and manage errors.
///
/// ## Usage
///
/// To use `AssetCacheKit`, you need to create a type that conforms to the `AssetLoader` protocol. This type will be responsible for fetching the actual asset. Then, you can use `AssetCacheKit` in your SwiftUI views, providing the loader, a content closure to display the loaded asset, and a placeholder closure for the loading state.
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         AssetCacheKit(
///             loader: CachedImageLoader(url: URL(string: "https://example.come/example.png")!),
///             content: { image in
///                 image
///                     .resizable()
///                     .scaledToFit()
///             } placeholder: {
///                 ProgressView()
///             } error: { error in
///                 Text("Error is \(error.localizedDescription)")
///             }
///         )
///     }
/// }
/// ```
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct AssetCacheKit<Loader: AssetLoader, Content: View, Placeholder: View, ErrorContent: View>: View {
    /// The current phase of the asynchronous asset loading process.
    @State internal var phase: AsyncPhase<Loader.Asset> = .empty
    
    /// The asset loader responsible for fetching the asset.
    let loader: Loader
    
    /// A closure that builds the content view from the loaded asset.
    let content: (Loader.Asset) -> Content
    
    /// A closure that builds the placeholder view to be displayed while the asset is loading.
    let placeholder: () -> Placeholder
    /// A closure that throw errors to a view to be displayed in case the asset downloading faced error.
    let errorView: ((Error) -> ErrorContent)
    
    
    /// Initializes a new `AssetCacheKit` instance.
    public init(loader: Loader, @ViewBuilder content: @escaping (Loader.Asset) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder, @ViewBuilder error: @escaping (Error) -> ErrorContent) {
        self.loader = loader
        self.content = content
        self.placeholder = placeholder
        self.errorView = error
    }
    
    public var body: some View {
        Group {
            switch phase {
            case .empty:
                placeholder()
            case .success(let asset):
                content(asset)
            case .failure(let error):
                errorView(error)
            }
        }
        .task(id: loader, priority: .userInitiated) {
            phase = .empty
            await loadAsset()
        }
    }
    
    /// Loads the asset asynchronously.
    private func loadAsset() async {
        do {
            let asset = try await loader.loadAsset()
            await MainActor.run {
                phase = .success(asset)
            }
        } catch {
            await MainActor.run {
                phase = .failure(error)
            }
        }
    }
    
}
