import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' if (dart.library.io) 'dart:js' as js;

class MetaPixelService {
  static void trackInitiateCheckout({
    required double value,
    required String currency,
    required String planName,
  }) {
    if (!kIsWeb) {
      debugPrint('MetaPixel: Not running on web, skipping');
      return;
    }

    try {
      debugPrint('MetaPixel: Calling trackInitiateCheckout with value=$value, currency=$currency, planName=$planName');
      js.context.callMethod('trackInitiateCheckout', [value, currency, planName]);
      debugPrint('MetaPixel: trackInitiateCheckout called successfully');
    } catch (e) {
      debugPrint('MetaPixel InitiateCheckout error: $e');
    }
  }

  /// Track Purchase event (after successful payment)
  static void trackPurchase({
    required double value,
    required String currency,
    required String planName,
  }) {
    if (!kIsWeb) return;

    try {
      js.context.callMethod('trackPurchase', [value, currency, planName]);
    } catch (e) {
      debugPrint('MetaPixel Purchase error: $e');
    }
  }
}
