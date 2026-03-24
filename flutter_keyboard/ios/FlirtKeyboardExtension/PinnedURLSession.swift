import Foundation

/// URLSession with standard TLS validation.
/// Certificate pinning was removed after migrating from Railway to our own VPS.
/// Security is ensured by: standard HTTPS/TLS + Ed25519 request signing.
final class PinnedURLSession: NSObject {

    static let shared = PinnedURLSession()

    lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
}
