package com.desenrolaai.app

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityManager
import com.desenrolaai.app.keyboard.auth.AuthHelper

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.desenrolaai/native"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val authHelper = AuthHelper(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isKeyboardEnabled" -> {
                        result.success(isKeyboardEnabled())
                    }

                    "openKeyboardSettings" -> {
                        startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS))
                        result.success(null)
                    }

                    "setBackendUrl" -> {
                        val url = call.argument<String>("url")
                        if (url != null) {
                            authHelper.setBackendUrl(url)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENT", "URL inválida", null)
                        }
                    }

                    "setDefaultTone" -> {
                        val tone = call.argument<String>("tone")
                        if (tone != null) {
                            authHelper.setDefaultTone(tone)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENT", "Tom inválido", null)
                        }
                    }

                    "shareAuthWithKeyboard" -> {
                        val authToken = call.argument<String>("authToken")
                        val userId = call.argument<String>("userId")
                        if (authToken != null && userId != null) {
                            authHelper.saveAuth(authToken, userId)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENT", "authToken e userId são obrigatórios", null)
                        }
                    }

                    "clearKeyboardAuth" -> {
                        authHelper.clearAuth()
                        result.success(null)
                    }

                    "isAccessibilityServiceEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }

                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun isKeyboardEnabled(): Boolean {
        val enabledMethods = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_INPUT_METHODS
        ) ?: return false
        return enabledMethods.contains("com.desenrolaai.app")
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(ACCESSIBILITY_SERVICE) as? AccessibilityManager ?: return false
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        return enabledServices.any {
            it.resolveInfo.serviceInfo.packageName == packageName &&
            it.resolveInfo.serviceInfo.name.contains("DesenrolaAccessibilityService")
        }
    }
}
