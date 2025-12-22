import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation.dart';

class ConversationService {
  final String baseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ConversationService({required this.baseUrl});

  /// Obter token de autenticação
  Future<String?> _getAuthToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// Headers padrão com autenticação
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Criar nova conversa
  Future<Conversation> createConversation({
    required String matchName,
    String? username,
    required String platform,
    String? bio,
    List<String>? photoDescriptions,
    String? age,
    List<String>? interests,
    String? firstMessage,
    String? tone,
    String? faceImageBase64,
    String? faceDescription,
  }) async {
    final url = Uri.parse('$baseUrl/conversations');
    final headers = await _getHeaders();

    final body = {
      'matchName': matchName,
      if (username != null) 'username': username,
      'platform': platform,
      if (bio != null) 'bio': bio,
      if (photoDescriptions != null) 'photoDescriptions': photoDescriptions,
      if (age != null) 'age': age,
      if (interests != null) 'interests': interests,
      if (firstMessage != null) 'firstMessage': firstMessage,
      if (tone != null) 'tone': tone,
      if (faceImageBase64 != null) 'faceImageBase64': faceImageBase64,
      if (faceDescription != null) 'faceDescription': faceDescription,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return Conversation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao criar conversa: ${response.body}');
    }
  }

  /// Listar conversas
  Future<List<ConversationListItem>> listConversations() async {
    final url = Uri.parse('$baseUrl/conversations');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ConversationListItem.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao listar conversas: ${response.body}');
    }
  }

  /// Obter conversa específica
  Future<Conversation> getConversation(String conversationId) async {
    final url = Uri.parse('$baseUrl/conversations/$conversationId');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Conversation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao obter conversa: ${response.body}');
    }
  }

  /// Adicionar mensagem
  Future<Conversation> addMessage({
    required String conversationId,
    required String role,
    required String content,
    bool? wasAiSuggestion,
    String? tone,
  }) async {
    final url = Uri.parse('$baseUrl/conversations/$conversationId/messages');
    final headers = await _getHeaders();

    final body = {
      'role': role,
      'content': content,
      if (wasAiSuggestion != null) 'wasAiSuggestion': wasAiSuggestion,
      if (tone != null) 'tone': tone,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return Conversation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao adicionar mensagem: ${response.body}');
    }
  }

  /// Gerar sugestões baseadas no histórico
  Future<List<String>> generateSuggestions({
    required String conversationId,
    required String receivedMessage,
    required String tone,
    Map<String, dynamic>? userContext,
  }) async {
    final url = Uri.parse('$baseUrl/conversations/$conversationId/suggestions');
    final headers = await _getHeaders();

    final body = {
      'receivedMessage': receivedMessage,
      'tone': tone,
      if (userContext != null) 'userContext': userContext,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        throw Exception('Request timeout');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final suggestionsText = data['suggestions'] as String;

      // Parse as sugestões
      final lines = suggestionsText.split('\n').where((line) => line.trim().isNotEmpty).toList();
      final parsedSuggestions = <String>[];

      for (var line in lines) {
        final cleaned = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (cleaned.isNotEmpty) {
          parsedSuggestions.add(cleaned);
        }
      }

      return parsedSuggestions;
    } else {
      throw Exception('Erro ao gerar sugestões: ${response.body}');
    }
  }

  /// Atualizar tom da conversa
  Future<void> updateTone(String conversationId, String tone) async {
    final url = Uri.parse('$baseUrl/conversations/$conversationId/tone');
    final headers = await _getHeaders();

    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode({'tone': tone}),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar tom: ${response.body}');
    }
  }

  /// Deletar conversa
  Future<void> deleteConversation(String conversationId) async {
    final url = Uri.parse('$baseUrl/conversations/$conversationId');
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Erro ao deletar conversa: ${response.body}');
    }
  }

  /// Submeter feedback sobre mensagem (contribui para inteligência coletiva)
  Future<void> submitFeedback({
    required String conversationId,
    required String messageId,
    required bool gotResponse,
    String? responseQuality, // 'cold', 'neutral', 'warm', 'hot'
  }) async {
    final url = Uri.parse('$baseUrl/conversations/$conversationId/feedback');
    final headers = await _getHeaders();

    final body = {
      'messageId': messageId,
      'gotResponse': gotResponse,
      if (responseQuality != null) 'responseQuality': responseQuality,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao submeter feedback: ${response.body}');
    }
  }
}
