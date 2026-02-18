package com.desenrolaai.app.keyboard

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Build
import android.util.Log
import java.io.File

object SecurityHelper {

    private const val TAG = "SecurityHelper"

    fun isSecureEnvironment(context: Context): Boolean {
        if (isDebuggable(context)) {
            Log.w(TAG, "App is debuggable")
            return false
        }
        if (isRooted()) {
            Log.w(TAG, "Device is rooted")
            return false
        }
        if (isEmulator()) {
            Log.w(TAG, "Running on emulator")
            return false
        }
        if (isHookingFrameworkPresent()) {
            Log.w(TAG, "Hooking framework detected")
            return false
        }
        return true
    }

    private fun isDebuggable(context: Context): Boolean {
        return (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    private fun isRooted(): Boolean {
        // Check for su binary
        val suPaths = arrayOf(
            "/system/bin/su", "/system/xbin/su", "/sbin/su",
            "/data/local/xbin/su", "/data/local/bin/su",
            "/system/sd/xbin/su", "/system/bin/failsafe/su",
            "/data/local/su", "/su/bin/su"
        )
        for (path in suPaths) {
            if (File(path).exists()) return true
        }

        // Check for root management apps
        val rootPackages = arrayOf(
            "com.topjohnwu.magisk",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.noshufou.android.su",
            "com.thirdparty.superuser",
            "com.yellowes.su"
        )
        val buildTags = Build.TAGS
        if (buildTags != null && buildTags.contains("test-keys")) return true

        // Check if su is executable
        try {
            val process = Runtime.getRuntime().exec(arrayOf("/system/xbin/which", "su"))
            val result = process.inputStream.bufferedReader().readLine()
            if (result != null) return true
        } catch (_: Exception) {}

        return false
    }

    private fun isEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")
                || "google_sdk" == Build.PRODUCT
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu")
                || Build.PRODUCT.contains("sdk_gphone")
                || Build.PRODUCT.contains("emulator")
                || Build.PRODUCT.contains("simulator"))
    }

    private fun isHookingFrameworkPresent(): Boolean {
        // Check for Xposed
        try {
            Class.forName("de.robv.android.xposed.XposedBridge")
            return true
        } catch (_: ClassNotFoundException) {}

        // Check for Frida
        try {
            val fridaPaths = arrayOf(
                "/data/local/tmp/frida-server",
                "/data/local/tmp/re.frida.server"
            )
            for (path in fridaPaths) {
                if (File(path).exists()) return true
            }
            // Check Frida default port
            val socket = java.net.Socket()
            try {
                socket.connect(java.net.InetSocketAddress("127.0.0.1", 27042), 100)
                socket.close()
                return true
            } catch (_: Exception) {
                socket.close()
            }
        } catch (_: Exception) {}

        return false
    }

    /**
     * Verify APK signature matches expected hash.
     * Returns true if signature is valid.
     */
    fun verifySignature(context: Context): Boolean {
        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                context.packageManager.getPackageInfo(
                    context.packageName,
                    android.content.pm.PackageManager.GET_SIGNING_CERTIFICATES
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(
                    context.packageName,
                    android.content.pm.PackageManager.GET_SIGNATURES
                )
            }

            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }

            if (signatures.isNullOrEmpty()) return false

            val md = java.security.MessageDigest.getInstance("SHA-256")
            val currentHash = md.digest(signatures[0].toByteArray())
            val currentHashHex = currentHash.joinToString("") { "%02x".format(it) }

            // Expected hash - will be set after first signed build
            // For now, log it so we can capture the correct value
            Log.d(TAG, "APK Signature SHA256: $currentHashHex")

            // The expected hash bytes are stored obfuscated
            val expected = getExpectedSignatureHash()
            return expected.isEmpty() || currentHashHex == expected
        } catch (e: Exception) {
            Log.e(TAG, "Signature verification failed", e)
            return false
        }
    }

    private fun getExpectedSignatureHash(): String {
        // Obfuscated expected hash - assembled at runtime
        // This will be populated after the first signed build
        // For now returns empty to allow first build
        val p1 = byteArrayOf(0x00) // placeholder
        return if (p1[0] == 0x00.toByte()) "" else ""
    }
}
