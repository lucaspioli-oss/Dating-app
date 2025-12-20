import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';

class AppState extends ChangeNotifier {
  // Backend URL - uses production URL by default
  String _backendUrl = AppConfig.productionBackendUrl;

  // Tom selecionado
  String _selectedTone = 'casual';

  // Histórico de conversas
  List<ConversationMessage> _messages = [];

  // Loading state
  bool _isLoading = false;

  // Getters
  String get backendUrl => _getEffectiveBackendUrl();
  String get selectedTone => _selectedTone;
  List<ConversationMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  AppState() {
    _loadPreferences();
  }

  // Verificar se usuário atual é desenvolvedor
  bool get isDeveloper {
    final user = FirebaseAuth.instance.currentUser;
    return AppConfig.isDeveloper(user?.email);
  }

  // URL efetiva: desenvolvedores podem escolher, outros sempre Railway
  String _getEffectiveBackendUrl() {
    if (isDeveloper) {
      return _backendUrl;
    }
    // Usuários normais SEMPRE usam Railway
    return AppConfig.productionBackendUrl;
  }

  // Carregar preferências salvas
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backendUrl = prefs.getString('backend_url') ?? AppConfig.productionBackendUrl;
      _selectedTone = prefs.getString('selected_tone') ?? 'casual';
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar preferências: $e');
    }
  }

  // Salvar URL do backend (só funciona para desenvolvedores)
  Future<void> setBackendUrl(String url) async {
    if (!isDeveloper) {
      debugPrint('Tentativa de mudar backend por não-desenvolvedor ignorada');
      return;
    }

    _backendUrl = url;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backend_url', url);
    } catch (e) {
      debugPrint('Erro ao salvar URL: $e');
    }
  }

  // Selecionar tom
  Future<void> setSelectedTone(String tone) async {
    _selectedTone = tone;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_tone', tone);
    } catch (e) {
      debugPrint('Erro ao salvar tom: $e');
    }
  }

  // Adicionar mensagem ao histórico
  void addMessage(ConversationMessage message) {
    _messages.insert(0, message);
    notifyListeners();
  }

  // Limpar histórico
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Recarregar preferências (útil após login)
  Future<void> reloadPreferences() async {
    await _loadPreferences();
  }
}

// Model para mensagens da conversa
class ConversationMessage {
  final String receivedMessage;
  final String aiSuggestion;
  final String tone;
  final DateTime timestamp;

  ConversationMessage({
    required this.receivedMessage,
    required this.aiSuggestion,
    required this.tone,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'receivedMessage': receivedMessage,
      'aiSuggestion': aiSuggestion,
      'tone': tone,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      receivedMessage: json['receivedMessage'],
      aiSuggestion: json['aiSuggestion'],
      tone: json['tone'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
