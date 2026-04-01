import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Sends app errors to POST /errors for monitoring in DesenrolaHub.
class ErrorReporter {
  static final ErrorReporter _instance = ErrorReporter._();
  static ErrorReporter get instance => _instance;
  ErrorReporter._();

  /// Report an error to the backend (fire-and-forget).
  void report({
    required String message,
    String? context,
    int? errorCode,
  }) {
    // Don't block — fire and forget
    _send(message: message, context: context, errorCode: errorCode);
  }

  Future<void> _send({
    required String message,
    String? context,
    int? errorCode,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      await http.post(
        Uri.parse('${AppConfig.backendUrl}/errors'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source': 'flutter_app',
          'error_code': errorCode,
          'message': message.length > 2000 ? message.substring(0, 2000) : message,
          'context': context,
          'user_id': userId,
          'app_version': AppConfig.appVersion,
          'os_version': Platform.operatingSystemVersion,
          'device': Platform.isIOS ? 'iOS' : 'Android',
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Silently fail — error reporter must never crash the app
    }
  }

  /// Set up global Flutter error handlers.
  static void init() {
    // Catch Flutter framework errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _instance.report(
        message: details.exceptionAsString(),
        context: details.context?.toString(),
      );
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _instance.report(
        message: error.toString(),
        context: stack.toString().split('\n').take(5).join('\n'),
      );
      return true;
    };
  }
}
