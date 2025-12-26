import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'stripe_web_stub.dart'
    if (dart.library.html) 'stripe_web_impl.dart' as stripe_impl;

class StripeWebService {
  static Future<bool> initializeElements({
    required String publishableKey,
    required String clientSecret,
    required String containerId,
    String? returnUrl,
    double? amount,
  }) async {
    if (!kIsWeb) return false;
    return stripe_impl.initStripeElements(
      publishableKey: publishableKey,
      clientSecret: clientSecret,
      containerId: containerId,
      returnUrl: returnUrl,
      amount: amount,
    );
  }

  static Future<String> confirmPayment(String returnUrl) async {
    if (!kIsWeb) throw Exception('Only supported on web');
    return stripe_impl.confirmStripePayment(returnUrl);
  }

  static void destroyElements() {
    if (!kIsWeb) return;
    stripe_impl.destroyStripeElements();
  }
}
