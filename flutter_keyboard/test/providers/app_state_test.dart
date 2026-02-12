import 'package:flutter_test/flutter_test.dart';
import 'package:desenrola_ai_keyboard/providers/app_state.dart';

void main() {
  group('AppState', () {
    late AppState state;

    setUp(() {
      state = AppState();
    });

    test('initial state has empty messages and not loading', () {
      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('addMessage inserts at the beginning', () {
      final msg1 = ConversationMessage(
        receivedMessage: 'First',
        aiSuggestion: 'Reply 1',
        timestamp: DateTime(2025, 1, 1),
      );
      final msg2 = ConversationMessage(
        receivedMessage: 'Second',
        aiSuggestion: 'Reply 2',
        timestamp: DateTime(2025, 1, 2),
      );

      state.addMessage(msg1);
      state.addMessage(msg2);

      expect(state.messages.length, 2);
      expect(state.messages[0].receivedMessage, 'Second');
      expect(state.messages[1].receivedMessage, 'First');
    });

    test('clearMessages removes all messages', () {
      state.addMessage(ConversationMessage(
        receivedMessage: 'test',
        aiSuggestion: 'test',
        timestamp: DateTime.now(),
      ));
      expect(state.messages, isNotEmpty);

      state.clearMessages();
      expect(state.messages, isEmpty);
    });

    test('setLoading updates loading state', () {
      expect(state.isLoading, isFalse);

      state.setLoading(true);
      expect(state.isLoading, isTrue);

      state.setLoading(false);
      expect(state.isLoading, isFalse);
    });

    test('addMessage notifies listeners', () {
      var notified = false;
      state.addListener(() => notified = true);

      state.addMessage(ConversationMessage(
        receivedMessage: 'test',
        aiSuggestion: 'test',
        timestamp: DateTime.now(),
      ));

      expect(notified, isTrue);
    });

    test('clearMessages notifies listeners', () {
      state.addMessage(ConversationMessage(
        receivedMessage: 'test',
        aiSuggestion: 'test',
        timestamp: DateTime.now(),
      ));

      var notified = false;
      state.addListener(() => notified = true);
      state.clearMessages();

      expect(notified, isTrue);
    });

    test('setLoading notifies listeners', () {
      var notified = false;
      state.addListener(() => notified = true);
      state.setLoading(true);

      expect(notified, isTrue);
    });
  });
}
