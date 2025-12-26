// Web implementation of Stripe Elements
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:async';

bool _isInitialized = false;

void registerStripeViewFactory(String containerId) {
  // Not needed - using fixed container in HTML
}

void positionStripeContainer(double top, double left, double width) {
  try {
    js.context.callMethod('positionStripeContainer', [top, left, width]);
  } catch (e) {
    print('Error positioning Stripe container: $e');
  }
}

void hideStripeContainer() {
  try {
    js.context.callMethod('hideStripeContainer');
  } catch (e) {
    print('Error hiding Stripe container: $e');
  }
}

Future<bool> initStripeElements({
  required String publishableKey,
  required String clientSecret,
  required String containerId,
  String? returnUrl,
  double? amount,
}) async {
  try {
    final result = js.context.callMethod('initStripeElements', [
      publishableKey,
      clientSecret,
      containerId,
      returnUrl ?? '',
      amount ?? 0,
    ]);

    _isInitialized = result == true;
    return _isInitialized;
  } catch (e) {
    print('Error initializing Stripe Elements: $e');
    return false;
  }
}

Future<String> confirmStripePayment(String returnUrl) async {
  if (!_isInitialized) {
    throw Exception('Stripe not initialized');
  }

  final completer = Completer<String>();

  try {
    final promise = js.context.callMethod('confirmStripePayment', [returnUrl]);

    promise.callMethod('then', [
      js.allowInterop((result) {
        completer.complete(result.toString());
      })
    ]).callMethod('catch', [
      js.allowInterop((error) {
        completer.completeError(error.toString());
      })
    ]);
  } catch (e) {
    completer.completeError(e.toString());
  }

  return completer.future;
}

void destroyStripeElements() {
  try {
    js.context.callMethod('destroyStripeElements');
    _isInitialized = false;
  } catch (e) {
    print('Error destroying Stripe Elements: $e');
  }
}

bool isStripeReady() {
  try {
    return js.context.callMethod('isStripeReady') == true;
  } catch (e) {
    return false;
  }
}
