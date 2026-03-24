import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AppState extends ChangeNotifier {
  // Historico de conversas
  List<ConversationMessage> _messages = [];

  // Loading state
  bool _isLoading = false;

  // Locale
  Locale _locale = const Locale('pt', 'BR');

  // Getters
  String get backendUrl => AppConfig.backendUrl;
  List<ConversationMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get userId => Supabase.instance.client.auth.currentUser?.id;
  Locale get locale => _locale;

  AppState() {
    _loadPreferences();
  }

  // Carregar preferencias salvas
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('selectedLanguage');
    if (langCode != null) {
      _locale = Locale(langCode);
    }
    // Sync backendUrl to shared UserDefaults for keyboard extension
    try {
      await _nativeChannel.invokeMethod('setBackendUrl', {'url': AppConfig.backendUrl});
    } catch (_) {}
    notifyListeners();
  }

  static const _nativeChannel = MethodChannel('com.desenrolaai/native');

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', locale.languageCode);
    try {
      await _nativeChannel.invokeMethod('setLanguage', {'language': locale.languageCode});
    } catch (_) {}
    notifyListeners();
  }

  // Adicionar mensagem ao historico
  void addMessage(ConversationMessage message) {
    _messages.insert(0, message);
    notifyListeners();
  }

  // Limpar historico
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Recarregar preferencias (util apos login)
  Future<void> reloadPreferences() async {
    await _loadPreferences();
  }
}

// Model para mensagens da conversa
class ConversationMessage {
  final String receivedMessage;
  final String aiSuggestion;
  final DateTime timestamp;

  ConversationMessage({
    required this.receivedMessage,
    required this.aiSuggestion,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'receivedMessage': receivedMessage,
      'aiSuggestion': aiSuggestion,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      receivedMessage: json['receivedMessage'],
      aiSuggestion: json['aiSuggestion'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
