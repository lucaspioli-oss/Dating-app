import Foundation
import CryptoKit

/// Signs API requests using Ed25519 asymmetric cryptography.
/// The private key is fragmented and reconstructed at runtime.
final class RequestSigner {

    static let shared = RequestSigner()
    private init() {}

    struct SignedRequest {
        let signature: String  // Base64
        let timestamp: String  // Unix seconds
        let nonce: String      // UUID
    }

    /// Sign a request body and return signature headers
    func sign(body: String) -> SignedRequest {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()

        // SHA256 of body
        let bodyHash = sha256Hex(body)
        let message = "\(timestamp)|\(nonce)|\(bodyHash)"

        // Reconstruct private key from fragments
        let privateKeyBytes = reconstructKey()

        do {
            let signingKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyBytes)
            let messageData = Data(message.utf8)
            let signature = try signingKey.signature(for: messageData)

            // Clear key material
            // (Swift doesn't allow direct zeroing of let, but the local scope handles it)

            return SignedRequest(
                signature: signature.base64EncodedString(),
                timestamp: timestamp,
                nonce: nonce
            )
        } catch {
            NSLog("[Security] Signing failed: \(error)")
            return SignedRequest(signature: "", timestamp: timestamp, nonce: nonce)
        }
    }

    private func reconstructKey() -> Data {
        return KeyFragments.reconstruct()
    }

    private func sha256Hex(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
