// Web implementation
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Uri? getCurrentUri() {
  return Uri.parse(html.window.location.href);
}
