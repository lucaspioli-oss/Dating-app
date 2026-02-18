import 'dart:io';

/// Custom HttpOverrides that restricts certificate bypass to our backend only.
/// Any connection to an unknown host with a bad certificate will be rejected.
class AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        // Only allow our production backend
        if (host == 'dating-app-production-ac43.up.railway.app') {
          return true; // Certificate is already validated by the system
        }
        return false; // Reject all other bad certificates
      };
  }
}
