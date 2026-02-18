import Foundation
import CommonCrypto

/// URLSession with certificate pinning for the backend server
final class PinnedURLSession: NSObject, URLSessionDelegate {

    static let shared = PinnedURLSession()

    /// SHA256 pins for the backend server certificate
    private let pinnedHashes: [String] = [
        "u6dScLDuE2TrAks7ct4HDBekXo9byFES6oApqW/pAjQ=" // Railway production
    ]

    lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Validate the certificate chain
        let policies = [SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)]
        SecTrustSetPolicies(serverTrust, policies as CFTypeRef)

        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Check if any certificate in the chain matches our pin
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) else { continue }

            let publicKey = SecCertificateCopyKey(certificate)
            guard let publicKeyData = publicKey.flatMap({ SecKeyCopyExternalRepresentation($0, nil) as Data? }) else { continue }

            let hash = sha256(data: publicKeyData)
            let hashBase64 = hash.base64EncodedString()

            if pinnedHashes.contains(hashBase64) {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }

        // No pin matched - reject connection
        completionHandler(.cancelAuthenticationChallenge, nil)
    }

    private func sha256(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}
