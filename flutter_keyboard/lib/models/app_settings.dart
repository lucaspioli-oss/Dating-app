import 'package:flutter/foundation.dart';

class AppSettings extends ChangeNotifier {
  String _selectedTone = 'engraçado';
  String _backendUrl = 'https://api.desenrolaai.site';

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
