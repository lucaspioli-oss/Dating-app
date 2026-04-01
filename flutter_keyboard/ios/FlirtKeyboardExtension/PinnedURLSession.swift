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
        // Keyboard extensions may not have the network stack ready on cold start.
        // Wait for connectivity instead of failing immediately with -1003.
        if #available(iOS 11.0, *) {
            config.waitsForConnectivity = true
        }
        // Ensure network access on constrained/expensive networks (Low Data Mode, hotspot)
        if #available(iOS 13.0, *) {
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
        }
        return URLSession(configuration: config)
    }()

    /// Execute a data task with automatic retry on DNS failures (-1003).
    /// Keyboard extensions often fail DNS on first attempt during cold start.
    func dataTask(with request: URLRequest, retries: Int = 2, delay: TimeInterval = 1.0, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        session.dataTask(with: request) { data, response, error in
            if let nsError = error as NSError?,
               nsError.code == NSURLErrorCannotFindHost,
               retries > 0 {
                NSLog("[KB] DNS failed (-1003), retrying in \(delay)s... (\(retries) left)")
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.dataTask(with: request, retries: retries - 1, delay: delay * 2, completion: completion)
                }
                return
            }
            completion(data, response, error)
        }.resume()
    }
}
