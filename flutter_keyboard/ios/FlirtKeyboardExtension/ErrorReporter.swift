import Foundation
import UIKit

/// Lightweight error reporter that sends app/keyboard errors to the backend.
/// Errors are posted fire-and-forget to POST /errors.
final class ErrorReporter {

    static let shared = ErrorReporter()

    private let backendUrl: String
    private let session: URLSession

    private init() {
        let defaults = UserDefaults(suiteName: "group.com.desenrolaai.app.shared")
        self.backendUrl = defaults?.string(forKey: "backendUrl") ?? "https://api.desenrolaai.site"

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        self.session = URLSession(configuration: config)
    }

    func report(
        errorCode: Int,
        message: String,
        context: String? = nil
    ) {
        guard let url = URL(string: "\(backendUrl)/errors") else { return }

        let defaults = UserDefaults(suiteName: "group.com.desenrolaai.app.shared")
        let userId = KeychainHelper.shared.read(forKey: "userId")
            ?? defaults?.string(forKey: "userId")

        var body: [String: Any] = [
            "source": "keyboard",
            "error_code": errorCode,
            "message": message,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "os_version": UIDevice.current.systemVersion,
            "device": UIDevice.current.model,
        ]
        if let userId = userId { body["user_id"] = userId }
        if let context = context { body["context"] = context }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: request) { _, _, _ in }.resume()
    }
}
