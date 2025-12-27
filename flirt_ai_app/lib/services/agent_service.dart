import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';

class AgentService {
  final String baseUrl;

  AgentService({required this.baseUrl});

  /// Gerar primeira mensagem criativa (expert mode - calibra automaticamente)
  Future<AgentResponse> generateFirstMessage({
    required String matchName,
    required String matchBio,
    required String platform,
    String? photoDescription,
    String? specificDetail,
    UserProfile? userProfile,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/generate-first-message');

      final body = {
        'matchName': matchName,
        'matchBio': matchBio,
        'platform': platform,
        if (photoDescription != null) 'photoDescription': photoDescription,
        if (specificDetail != null) 'specificDetail': specificDetail,
        if (userProfile != null && userProfile.isComplete)
          'userContext': _userProfileToContext(userProfile),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = data['suggestions'] as String;

        // Parse as sugestões (assumindo que vêm numeradas)
        final lines = suggestions.split('\n').where((line) => line.trim().isNotEmpty).toList();
        final parsedSuggestions = <String>[];

        for (var line in lines) {
          // Remove numeração no início (1., 2., 3., etc)
          final cleaned = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
          if (cleaned.isNotEmpty) {
            parsedSuggestions.add(cleaned);
          }
        }

        return AgentResponse.success(suggestions: parsedSuggestions);
      } else {
        return AgentResponse.error(
          message: 'Erro ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return AgentResponse.error(
        message: 'Erro de conexão: ${e.toString()}',
      );
    }
  }

  /// Analisar perfil
  Future<AgentResponse> analyzeProfile({
    required String bio,
    required String platform,
    String? photoDescription,
    String? name,
    String? age,
    UserProfile? userProfile,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/analyze-profile');

      final body = {
        'bio': bio,
        'platform': platform,
        if (photoDescription != null) 'photoDescription': photoDescription,
        if (name != null) 'name': name,
        if (age != null) 'age': age,
        if (userProfile != null && userProfile.isComplete)
          'userContext': _userProfileToContext(userProfile),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AgentResponse.success(analysis: data['analysis']);
      } else {
        return AgentResponse.error(
          message: 'Erro ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return AgentResponse.error(
        message: 'Erro de conexão: ${e.toString()}',
      );
    }
  }

  /// Gerar abertura para Instagram (expert mode - calibra automaticamente)
  Future<AgentResponse> generateInstagramOpener({
    required String username,
    required String approachType,
    String? bio,
    List<String>? recentPosts,
    List<String>? stories,
    String? specificPost,
    UserProfile? userProfile,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/generate-instagram-opener');

      final body = {
        'username': username,
        'approachType': approachType,
        if (bio != null) 'bio': bio,
        if (recentPosts != null) 'recentPosts': recentPosts,
        if (stories != null) 'stories': stories,
        if (specificPost != null) 'specificPost': specificPost,
        if (userProfile != null && userProfile.isComplete)
          'userContext': _userProfileToContext(userProfile),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = data['suggestions'] as String;

        // Parse as sugestões
        final lines = suggestions.split('\n').where((line) => line.trim().isNotEmpty).toList();
        final parsedSuggestions = <String>[];

        for (var line in lines) {
          final cleaned = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
          if (cleaned.isNotEmpty) {
            parsedSuggestions.add(cleaned);
          }
        }

        return AgentResponse.success(suggestions: parsedSuggestions);
      } else {
        return AgentResponse.error(
          message: 'Erro ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return AgentResponse.error(
        message: 'Erro de conexão: ${e.toString()}',
      );
    }
  }

  /// Gerar resposta para mensagem recebida
  /// FOCO 100% na mensagem dela - NÃO envia perfil/bio/contexto
  Future<AgentResponse> generateReply({
    required String receivedMessage,
    String? matchName, // Ignorado
    String? platform, // Ignorado
    String? context, // Ignorado
    List<Map<String, String>>? conversationHistory,
    UserProfile? userProfile, // Ignorado
  }) async {
    try {
      final url = Uri.parse('$baseUrl/reply');

      // APENAS a mensagem e histórico - sem perfil/bio
      final body = {
        'receivedMessage': receivedMessage,
        if (conversationHistory != null) 'conversationHistory': conversationHistory,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = data['suggestions'] as String;

        // Parse as sugestoes
        final lines = suggestions.split('\n').where((line) => line.trim().isNotEmpty).toList();
        final parsedSuggestions = <String>[];

        for (var line in lines) {
          final cleaned = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
          if (cleaned.isNotEmpty) {
            parsedSuggestions.add(cleaned);
          }
        }

        return AgentResponse.success(suggestions: parsedSuggestions);
      } else {
        return AgentResponse.error(
          message: 'Erro ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return AgentResponse.error(
        message: 'Erro de conexao: ${e.toString()}',
      );
    }
  }

  /// Analisar imagem de perfil e extrair informações
  Future<ProfileImageResponse> analyzeProfileImage({
    required String imageBase64,
    String? platform,
    String imageMediaType = 'image/jpeg',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/analyze-profile-image');

      final body = {
        'imageBase64': imageBase64,
        'imageMediaType': imageMediaType,
        if (platform != null) 'platform': platform,
      };

      // Timeout maior para conexões móveis
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw TimeoutException('Conexão lenta. Tente com Wi-Fi ou imagem menor.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final extractedData = data['extractedData'] as Map<String, dynamic>;

        return ProfileImageResponse.success(
          name: extractedData['name'],
          username: extractedData['username'],
          age: extractedData['age'],
          bio: extractedData['bio'],
          photoDescriptions: extractedData['photoDescriptions'] != null
              ? List<String>.from(extractedData['photoDescriptions'])
              : null,
          location: extractedData['location'],
          occupation: extractedData['occupation'],
          interests: extractedData['interests'] != null
              ? List<String>.from(extractedData['interests'])
              : null,
          additionalInfo: extractedData['additionalInfo'],
          faceDescription: extractedData['faceDescription'],
        );
      } else {
        return ProfileImageResponse.error(
          message: 'Erro ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return ProfileImageResponse.error(
        message: 'Erro de conexão: ${e.toString()}',
      );
    }
  }

  /// Gerar resposta COM RACIOCÍNIO (para desenvolvedores)
  /// FOCO 100% na mensagem dela - NÃO envia perfil/bio/contexto
  Future<ReplyWithReasoningResponse> generateReplyWithReasoning({
    required String receivedMessage,
    String? matchName, // Ignorado
    String? platform, // Ignorado
    String? context, // Ignorado
    List<Map<String, String>>? conversationHistory,
    UserProfile? userProfile, // Ignorado
  }) async {
    try {
      final url = Uri.parse('$baseUrl/reply-with-reasoning');

      // APENAS a mensagem e histórico - sem perfil/bio
      final body = {
        'receivedMessage': receivedMessage,
        if (conversationHistory != null) 'conversationHistory': conversationHistory,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final analysisData = data['analysis'] as Map<String, dynamic>?;
        final suggestionsData = data['suggestions'] as List<dynamic>?;

        final analysis = analysisData != null
            ? ReplyAnalysis.fromJson(analysisData)
            : ReplyAnalysis(
                messageTemperature: 'warm',
                keyElements: [],
                detectedIntent: '',
                conversationPhase: 'inicial',
              );

        final suggestions = suggestionsData?.map((s) =>
          SuggestionWithReasoning.fromJson(s as Map<String, dynamic>)
        ).toList() ?? [];

        return ReplyWithReasoningResponse.success(
          analysis: analysis,
          suggestions: suggestions,
          rawResponse: data['rawResponse'],
        );
      } else {
        return ReplyWithReasoningResponse.error(
          message: 'Erro ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return ReplyWithReasoningResponse.error(
        message: 'Erro de conexao: ${e.toString()}',
      );
    }
  }

  /// Submeter feedback do desenvolvedor
  Future<bool> submitDeveloperFeedback({
    required Map<String, dynamic> inputData,
    required Map<String, dynamic>? analysis,
    required List<Map<String, dynamic>> suggestions,
    int? selectedIndex,
    required String feedbackType, // 'good' | 'bad' | 'partial'
    String? feedbackNote,
    String? correctedSuggestion,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/developer-feedback');

      final body = {
        'inputData': inputData,
        'analysis': analysis,
        'suggestions': suggestions,
        'selectedIndex': selectedIndex,
        'feedbackType': feedbackType,
        'feedbackNote': feedbackNote,
        'correctedSuggestion': correctedSuggestion,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 201;
    } catch (e) {
      print('Erro ao submeter feedback: $e');
      return false;
    }
  }

  /// Analisar screenshot de conversa para extrair mensagem (OCR)
  Future<ConversationImageResponse> analyzeConversationImage({
    required String imageBase64,
    String? platform,
    String imageMediaType = 'image/jpeg',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/analyze-conversation-image');

      final body = {
        'imageBase64': imageBase64,
        'imageMediaType': imageMediaType,
        if (platform != null) 'platform': platform,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Conexão lenta. Tente novamente.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final extractedData = data['extractedData'] as Map<String, dynamic>;

        return ConversationImageResponse.success(
          lastMessage: extractedData['lastMessage'],
          lastMessageSender: extractedData['lastMessageSender'],
          conversationContext: extractedData['conversationContext'] != null
              ? List<String>.from(extractedData['conversationContext'])
              : null,
          platform: extractedData['platform'],
        );
      } else {
        return ConversationImageResponse.error(
          message: 'Erro ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return ConversationImageResponse.error(
        message: 'Erro de conexão: ${e.toString()}',
      );
    }
  }

  /// Converter UserProfile para contexto da API
  Map<String, dynamic> _userProfileToContext(UserProfile profile) {
    return {
      if (profile.name.isNotEmpty) 'name': profile.name,
      if (profile.age >= 18) 'age': profile.age,
      'gender': profile.gender,
      if (profile.interests.isNotEmpty) 'interests': profile.interests,
      if (profile.dislikes.isNotEmpty) 'dislikes': profile.dislikes,
      'humorStyle': profile.humorStyle,
      'relationshipGoal': profile.relationshipGoal,
      if (profile.bio.isNotEmpty) 'bio': profile.bio,
    };
  }
}

/// Resposta da análise de imagem
class ProfileImageResponse {
  final bool success;
  final String? name;
  final String? username;           // Para Instagram
  final String? age;
  final String? bio;
  final List<String>? photoDescriptions;
  final String? location;
  final String? occupation;
  final List<String>? interests;
  final String? additionalInfo;
  final String? faceDescription;    // Descrição facial para identificação
  final String? errorMessage;

  ProfileImageResponse._({
    required this.success,
    this.name,
    this.username,
    this.age,
    this.bio,
    this.photoDescriptions,
    this.location,
    this.occupation,
    this.interests,
    this.additionalInfo,
    this.faceDescription,
    this.errorMessage,
  });

  factory ProfileImageResponse.success({
    String? name,
    String? username,
    String? age,
    String? bio,
    List<String>? photoDescriptions,
    String? location,
    String? occupation,
    List<String>? interests,
    String? additionalInfo,
    String? faceDescription,
  }) {
    return ProfileImageResponse._(
      success: true,
      name: name,
      username: username,
      age: age,
      bio: bio,
      photoDescriptions: photoDescriptions,
      location: location,
      occupation: occupation,
      interests: interests,
      additionalInfo: additionalInfo,
      faceDescription: faceDescription,
    );
  }

  factory ProfileImageResponse.error({required String message}) {
    return ProfileImageResponse._(
      success: false,
      errorMessage: message,
    );
  }
}

/// Resposta dos agentes
class AgentResponse {
  final bool success;
  final String? analysis;
  final List<String>? suggestions;
  final String? errorMessage;

  AgentResponse._({
    required this.success,
    this.analysis,
    this.suggestions,
    this.errorMessage,
  });

  factory AgentResponse.success({String? analysis, List<String>? suggestions}) {
    return AgentResponse._(
      success: true,
      analysis: analysis,
      suggestions: suggestions,
    );
  }

  factory AgentResponse.error({required String message}) {
    return AgentResponse._(
      success: false,
      errorMessage: message,
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

/// Análise de resposta com raciocínio (para desenvolvedores)
class ReplyAnalysis {
  final String messageTemperature; // 'hot' | 'warm' | 'cold'
  final List<String> keyElements;
  final String detectedIntent;
  final String conversationPhase;

  ReplyAnalysis({
    required this.messageTemperature,
    required this.keyElements,
    required this.detectedIntent,
    required this.conversationPhase,
  });

  factory ReplyAnalysis.fromJson(Map<String, dynamic> json) {
    return ReplyAnalysis(
      messageTemperature: json['messageTemperature'] ?? 'warm',
      keyElements: List<String>.from(json['keyElements'] ?? []),
      detectedIntent: json['detectedIntent'] ?? '',
      conversationPhase: json['conversationPhase'] ?? 'inicial',
    );
  }
}

/// Sugestão com raciocínio
class SuggestionWithReasoning {
  final String text;
  final String reasoning;
  final String strategy;

  SuggestionWithReasoning({
    required this.text,
    required this.reasoning,
    required this.strategy,
  });

  factory SuggestionWithReasoning.fromJson(Map<String, dynamic> json) {
    return SuggestionWithReasoning(
      text: json['text'] ?? '',
      reasoning: json['reasoning'] ?? '',
      strategy: json['strategy'] ?? '',
    );
  }
}

/// Resposta com raciocínio completo
class ReplyWithReasoningResponse {
  final bool success;
  final ReplyAnalysis? analysis;
  final List<SuggestionWithReasoning>? suggestions;
  final String? rawResponse;
  final String? errorMessage;

  ReplyWithReasoningResponse._({
    required this.success,
    this.analysis,
    this.suggestions,
    this.rawResponse,
    this.errorMessage,
  });

  factory ReplyWithReasoningResponse.success({
    required ReplyAnalysis analysis,
    required List<SuggestionWithReasoning> suggestions,
    String? rawResponse,
  }) {
    return ReplyWithReasoningResponse._(
      success: true,
      analysis: analysis,
      suggestions: suggestions,
      rawResponse: rawResponse,
    );
  }

  factory ReplyWithReasoningResponse.error({required String message}) {
    return ReplyWithReasoningResponse._(
      success: false,
      errorMessage: message,
    );
  }
}

/// Resposta da análise de screenshot de conversa (OCR)
class ConversationImageResponse {
  final bool success;
  final String? lastMessage;
  final String? lastMessageSender;
  final List<String>? conversationContext;
  final String? platform;
  final String? errorMessage;

  ConversationImageResponse._({
    required this.success,
    this.lastMessage,
    this.lastMessageSender,
    this.conversationContext,
    this.platform,
    this.errorMessage,
  });

  factory ConversationImageResponse.success({
    String? lastMessage,
    String? lastMessageSender,
    List<String>? conversationContext,
    String? platform,
  }) {
    return ConversationImageResponse._(
      success: true,
      lastMessage: lastMessage,
      lastMessageSender: lastMessageSender,
      conversationContext: conversationContext,
      platform: platform,
    );
  }

  factory ConversationImageResponse.error({required String message}) {
    return ConversationImageResponse._(
      success: false,
      errorMessage: message,
    );
  }
}
