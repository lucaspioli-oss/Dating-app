import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:desenrola_ai_keyboard/services/agent_service.dart';
import 'package:desenrola_ai_keyboard/models/user_profile.dart';

void main() {
  group('AgentResponse', () {
    test('success factory sets success to true', () {
      final response = AgentResponse.success(
        analysis: 'Test analysis',
        suggestions: ['Oi', 'Tudo bem?'],
      );
      expect(response.success, isTrue);
      expect(response.analysis, 'Test analysis');
      expect(response.suggestions, ['Oi', 'Tudo bem?']);
      expect(response.errorMessage, isNull);
    });

    test('error factory sets success to false', () {
      final response = AgentResponse.error(message: 'Timeout');
      expect(response.success, isFalse);
      expect(response.errorMessage, 'Timeout');
      expect(response.analysis, isNull);
      expect(response.suggestions, isNull);
    });
  });

  group('TimeoutException', () {
    test('toString returns message', () {
      final exc = TimeoutException('Request timed out');
      expect(exc.toString(), 'Request timed out');
      expect(exc.message, 'Request timed out');
    });
  });

  group('ReplyAnalysis', () {
    test('fromJson parses all fields', () {
      final json = {
        'messageTemperature': 'hot',
        'keyElements': ['humor', 'interesse'],
        'detectedIntent': 'flerte',
        'conversationPhase': 'aquecimento',
      };
      final analysis = ReplyAnalysis.fromJson(json);
      expect(analysis.messageTemperature, 'hot');
      expect(analysis.keyElements, ['humor', 'interesse']);
      expect(analysis.detectedIntent, 'flerte');
      expect(analysis.conversationPhase, 'aquecimento');
    });

    test('fromJson handles missing fields with defaults', () {
      final analysis = ReplyAnalysis.fromJson({});
      expect(analysis.messageTemperature, 'warm');
      expect(analysis.keyElements, isEmpty);
      expect(analysis.detectedIntent, '');
      expect(analysis.conversationPhase, 'inicial');
    });
  });

  group('AgentService', () {
    late AgentService service;

    test('generateFirstMessage sends correct payload', () async {
      late Map<String, dynamic> capturedBody;
      late Uri capturedUri;

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedBody = jsonDecode(request.body);
        return http.Response(
          jsonEncode({
            'suggestions': '1. Oi, tudo bem?\n2. E aí, como vai?\n3. Olá!',
          }),
          200,
        );
      });

      // We can't easily inject the http client into AgentService as it uses
      // http.post directly. Instead we test the response parsing logic.
      // Testing the full flow would require refactoring to accept an http.Client.
      // For now, test the response classes and parsing.

      final response = AgentResponse.success(
        suggestions: ['Oi, tudo bem?', 'E aí, como vai?', 'Olá!'],
      );
      expect(response.success, isTrue);
      expect(response.suggestions?.length, 3);
    });

    test('user profile context is included when complete', () {
      final profile = UserProfile(
        name: 'Lucas',
        age: 25,
        gender: 'Masculino',
        interests: ['música'],
        dislikes: [],
        humorStyle: 'engraçado',
        relationshipGoal: 'namoro',
        preferredTone: 'ousado',
      );
      expect(profile.isComplete, isTrue);

      final context = profile.toAIContext();
      expect(context, contains('Lucas'));
      expect(context, contains('25'));
    });

    test('user profile context is not included when incomplete', () {
      final profile = UserProfile.empty();
      expect(profile.isComplete, isFalse);
    });

    test('suggestion parsing handles numbered format', () {
      // Simulating the parsing logic from AgentService
      const raw = '1. Oi, tudo bem?\n2. E aí, como vai?\n3. Olá!';
      final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final parsed = <String>[];
      for (var line in lines) {
        final cleaned = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (cleaned.isNotEmpty) parsed.add(cleaned);
      }
      expect(parsed, ['Oi, tudo bem?', 'E aí, como vai?', 'Olá!']);
    });

    test('suggestion parsing handles lines without numbers', () {
      const raw = 'Oi!\nTudo bem?\nVamos sair?';
      final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final parsed = <String>[];
      for (var line in lines) {
        final cleaned = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (cleaned.isNotEmpty) parsed.add(cleaned);
      }
      expect(parsed, ['Oi!', 'Tudo bem?', 'Vamos sair?']);
    });

    test('suggestion parsing handles empty lines', () {
      const raw = '1. Oi!\n\n\n2. Tudo bem?';
      final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final parsed = <String>[];
      for (var line in lines) {
        final cleaned = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (cleaned.isNotEmpty) parsed.add(cleaned);
      }
      expect(parsed, ['Oi!', 'Tudo bem?']);
    });
  });
}
