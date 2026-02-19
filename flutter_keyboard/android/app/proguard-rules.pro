# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }

# JSON
-keep class org.json.** { *; }

# AndroidX Security (EncryptedSharedPreferences)
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Google Play Core (referenced by Flutter deferred components)
-dontwarn com.google.android.play.core.**

# Google API Client (referenced by Tink)
-dontwarn com.google.api.client.**

# Joda Time (referenced by Tink KeysDownloader)
-dontwarn org.joda.time.**

# Keep our keyboard service (must be discoverable by system)
-keep class com.desenrolaai.app.keyboard.DesenrolaKeyboardService { *; }
-keep class com.desenrolaai.app.MainActivity { *; }

# Keep accessibility service (must be discoverable by system)
-keep class com.desenrolaai.app.keyboard.accessibility.DesenrolaAccessibilityService { *; }

# Obfuscate everything else
-repackageclasses ''
-allowaccessmodification
-optimizationpasses 5
