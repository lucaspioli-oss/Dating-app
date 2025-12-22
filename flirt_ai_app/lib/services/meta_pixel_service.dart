import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' if (dart.library.io) 'dart:js' as js;

class MetaPixelService {
  static void trackInitiateCheckout({
    required double value,
    required String currency,
    required String planName,
  }) {
    if (!kIsWeb) return;

    try {
      js.context.callMethod('trackInitiateCheckout', [value, currency, planName]);
    } catch (e) {
      debugPrint('MetaPixel InitiateCheckout error: $e');
    }
  }
}

void debugPrint(String message) {
  if (kIsWeb) {
    // ignore in web
  }
}
