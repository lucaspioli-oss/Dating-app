import 'web_url_stub.dart' if (dart.library.html) 'web_url_impl.dart' as impl;

class WebUrlHelper {
  static Uri? getCurrentUri() {
    return impl.getCurrentUri();
  }
}
