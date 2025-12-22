import 'package:flutter/foundation.dart';

/// Model para configurações do app
class AppSettings extends ChangeNotifier {
  String _backendUrl = 'http://localhost:3000';
  String _selectedTone = 'casual';

  String get backendUrl => _backendUrl;
  String get selectedTone => _selectedTone;

  void setBackendUrl(String url) {
    _backendUrl = url;
    notifyListeners();
  }

  void setSelectedTone(String tone) {
    _selectedTone = tone;
    notifyListeners();
  }
}
