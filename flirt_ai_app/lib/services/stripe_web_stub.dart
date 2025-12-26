// Stub file for non-web platforms

Future<bool> initStripeElements({
  required String publishableKey,
  required String clientSecret,
  required String containerId,
  String? returnUrl,
  double? amount,
}) async {
  throw UnsupportedError('Stripe Elements only works on web');
}

Future<String> confirmStripePayment(String returnUrl) async {
  throw UnsupportedError('Stripe Elements only works on web');
}

void destroyStripeElements() {
  // No-op on non-web platforms
}

void registerStripeViewFactory() {
  // No-op on non-web platforms
}

void showStripeModal() {
  // No-op on non-web platforms
}

void hideStripeModal() {
  // No-op on non-web platforms
}
