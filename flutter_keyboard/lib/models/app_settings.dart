import 'package:flutter/foundation.dart';

class AppSettings extends ChangeNotifier {
  String _selectedTone = 'engraçado';
  String _backendUrl = 'https://dating-app-production-ac43.up.railway.app';

  String get selectedTone => _selectedTone;
  String get backendUrl => _backendUrl;

  void setSelectedTone(String tone) {
    _selectedTone = tone;
    notifyListeners();
  }

  void setBackendUrl(String url) {
    _backendUrl = url;
    notifyListeners();
  }
}
