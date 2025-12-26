// Web implementation for checkout view factory
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

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
