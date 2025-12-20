import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AppState extends ChangeNotifier {
  // Tom selecionado
  String _selectedTone = 'casual';

  // Histórico de conversas
  List<ConversationMessage> _messages = [];

  // Loading state
  bool _isLoading = false;

  // Getters
  String get backendUrl => AppConfig.backendUrl;
  String get selectedTone => _selectedTone;
  List<ConversationMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  AppState() {
    _loadPreferences();
  }

  // Carregar preferências salvas
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedTone = prefs.getString('selected_tone') ?? 'casual';
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar preferências: $e');
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
