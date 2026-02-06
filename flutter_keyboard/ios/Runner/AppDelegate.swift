import UIKit
import Flutter

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
}
