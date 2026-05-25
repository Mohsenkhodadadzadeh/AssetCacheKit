import Foundation

private final class URLProtocolStubState: @unchecked Sendable {
    let lock = NSLock()
    var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    var requestCount = 0
}

final class URLProtocolStub: URLProtocol {
    private static let state = URLProtocolStubState()

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        get {
            state.lock.lock()
            defer { state.lock.unlock() }
            return state.requestHandler
        }
        set {
            state.lock.lock()
            defer { state.lock.unlock() }
            state.requestHandler = newValue
        }
    }

    static var requestCount: Int {
        state.lock.lock()
        defer { state.lock.unlock() }
        return state.requestCount
    }

    static func startIntercepting() {
        state.lock.lock()
        state.requestHandler = nil
        state.requestCount = 0
        state.lock.unlock()
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopIntercepting() {
        state.lock.lock()
        state.requestHandler = nil
        state.requestCount = 0
        state.lock.unlock()
        URLProtocol.unregisterClass(URLProtocolStub.self)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        requestHandler != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.state.lock.lock()
        Self.state.requestCount += 1
        let handler = Self.state.requestHandler
        Self.state.lock.unlock()

        guard let handler = handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
