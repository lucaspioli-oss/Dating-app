import 'package:flutter_test/flutter_test.dart';
import 'package:desenrola_ai_keyboard/providers/app_state.dart';

void main() {
  group('ConversationMessage', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final msg = ConversationMessage(
        receivedMessage: 'Oi, tudo bem?',
        aiSuggestion: 'Oi! Tudo ótimo e com você?',
        timestamp: now,
      );

      expect(msg.receivedMessage, 'Oi, tudo bem?');
      expect(msg.aiSuggestion, 'Oi! Tudo ótimo e com você?');
      expect(msg.timestamp, now);
    });

    group('toJson / fromJson', () {
      test('round-trip preserves all fields', () {
        final now = DateTime(2025, 3, 15, 14, 30, 0);
        final original = ConversationMessage(
          receivedMessage: 'Mensagem recebida',
          aiSuggestion: 'Sugestão da IA',
          timestamp: now,
        );

        final json = original.toJson();
        final restored = ConversationMessage.fromJson(json);

        expect(restored.receivedMessage, original.receivedMessage);
        expect(restored.aiSuggestion, original.aiSuggestion);
        expect(restored.timestamp, original.timestamp);
      });

      test('toJson includes timestamp as ISO 8601', () {
        final msg = ConversationMessage(
          receivedMessage: 'test',
          aiSuggestion: 'test',
          timestamp: DateTime(2025, 1, 1),
        );
        final json = msg.toJson();
        expect(json['timestamp'], isA<String>());
        expect(json['timestamp'], contains('2025'));
      });

      test('fromJson parses ISO 8601 timestamp', () {
        final json = {
          'receivedMessage': 'hello',
          'aiSuggestion': 'hi there',
          'timestamp': '2025-06-15T10:30:00.000',
        };
        final msg = ConversationMessage.fromJson(json);
        expect(msg.timestamp.year, 2025);
        expect(msg.timestamp.month, 6);
        expect(msg.timestamp.day, 15);
      });
    });
  });
}
