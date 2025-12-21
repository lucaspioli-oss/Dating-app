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
        final extractedData = data['extractedData'] as Map<String, dynamic>;

        return ProfileImageResponse.success(
          name: extractedData['name'],
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
  final String? age;
  final String? bio;
  final List<String>? photoDescriptions;
  final String? location;
  final String? occupation;
  final List<String>? interests;
  final String? additionalInfo;
  final String? errorMessage;

  ProfileImageResponse._({
    required this.success,
    this.name,
    this.age,
    this.bio,
    this.photoDescriptions,
    this.location,
    this.occupation,
    this.interests,
    this.additionalInfo,
    this.errorMessage,
  });

  factory ProfileImageResponse.success({
    String? name,
    String? age,
    String? bio,
    List<String>? photoDescriptions,
    String? location,
    String? occupation,
    List<String>? interests,
    String? additionalInfo,
  }) {
    return ProfileImageResponse._(
      success: true,
      name: name,
      age: age,
      bio: bio,
      photoDescriptions: photoDescriptions,
      location: location,
      occupation: occupation,
      interests: interests,
      additionalInfo: additionalInfo,
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
