import UIKit
import Flutter
import CoreImage

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

        // Configurar MethodChannel para comunicação Flutter <-> iOS
        let keyboardChannel = FlutterMethodChannel(
            name: "com.desenrolaai/native",
            binaryMessenger: controller.binaryMessenger
        )

        keyboardChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handleMethodCall(call: call, result: result)
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Method Channel Handler

    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isKeyboardEnabled":
            result(isKeyboardEnabled())

        case "openKeyboardSettings":
            openKeyboardSettings()
            result(nil)

        case "setBackendUrl":
            if let args = call.arguments as? [String: Any],
               let url = args["url"] as? String {
                saveToSharedDefaults(key: "backendUrl", value: url)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT",
                                   message: "URL inválida",
                                   details: nil))
            }

        case "setDefaultTone":
            if let args = call.arguments as? [String: Any],
               let tone = args["tone"] as? String {
                saveToSharedDefaults(key: "defaultTone", value: tone)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT",
                                   message: "Tom inválido",
                                   details: nil))
            }

        case "shareAuthWithKeyboard":
            if let args = call.arguments as? [String: Any],
               let authToken = args["authToken"] as? String,
               let userId = args["userId"] as? String {
                saveToSharedDefaults(key: "authToken", value: authToken)
                saveToSharedDefaults(key: "userId", value: userId)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT",
                                   message: "authToken e userId são obrigatórios",
                                   details: nil))
            }

        case "clearKeyboardAuth":
            if let sharedDefaults = UserDefaults(suiteName: "group.com.desenrolaai.app.shared") {
                sharedDefaults.removeObject(forKey: "authToken")
                sharedDefaults.removeObject(forKey: "userId")
                sharedDefaults.synchronize()
            }
            result(nil)

        case "detectFace":
            if let args = call.arguments as? [String: Any],
               let imageBytes = args["imageBytes"] as? FlutterStandardTypedData {
                let width = args["width"] as? Int ?? 0
                let height = args["height"] as? Int ?? 0
                let faceRect = detectFaceInImage(imageData: imageBytes.data, width: width, height: height)
                result(faceRect)
            } else {
                result(nil)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Helper Methods

    /// Verifica se o teclado customizado está habilitado
    private func isKeyboardEnabled() -> Bool {
        guard let keyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] else {
            return false
        }

        // Procurar pelo bundle identifier do keyboard extension
        // Formato: com.desenrolaai.app.keyboard
        return keyboards.contains { $0.contains("keyboard") }
    }

    /// Abre as configurações do sistema
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    /// Salva dados no UserDefaults compartilhado com o Keyboard Extension
    /// IMPORTANTE: Requer App Groups configurado
    private func saveToSharedDefaults(key: String, value: String) {
        // Usar UserDefaults compartilhado entre app e keyboard extension
        // O App Group ID deve ser configurado em Capabilities
        if let sharedDefaults = UserDefaults(suiteName: "group.com.desenrolaai.app.shared") {
            sharedDefaults.set(value, forKey: key)
            sharedDefaults.synchronize()
        }
    }

    /// Detects the largest face in an image using CIDetector.
    /// Returns a dictionary with {x, y, width, height} or nil if no face found.
    private func detectFaceInImage(imageData: Data, width: Int, height: Int) -> [String: Any]? {
        guard let ciImage = CIImage(data: imageData) else { return nil }

        let detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )

        guard let features = detector?.features(in: ciImage) as? [CIFaceFeature],
              !features.isEmpty else {
            return nil
        }

        // Find the largest face by area
        var largest = features[0]
        var largestArea = largest.bounds.width * largest.bounds.height
        for face in features.dropFirst() {
            let area = face.bounds.width * face.bounds.height
            if area > largestArea {
                largest = face
                largestArea = area
            }
        }

        // CIDetector uses bottom-left origin, convert to top-left for Flutter
        let imageHeight = CGFloat(ciImage.extent.height)
        let flippedY = imageHeight - largest.bounds.origin.y - largest.bounds.height

        return [
            "x": Double(largest.bounds.origin.x),
            "y": Double(flippedY),
            "width": Double(largest.bounds.width),
            "height": Double(largest.bounds.height),
        ]
    }
}
