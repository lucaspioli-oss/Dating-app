import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desenrola_ai_keyboard/widgets/app_error_state.dart';
import 'package:desenrola_ai_keyboard/config/app_theme.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('AppErrorState', () {
    testWidgets('renders error icon and message', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppErrorState(message: 'Algo deu errado'),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Algo deu errado'), findsOneWidget);
    });

    testWidgets('does not show retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppErrorState(message: 'Erro'),
      ));

      expect(find.text('Tentar novamente'), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        AppErrorState(message: 'Erro', onRetry: () {}),
      ));

      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('retry button triggers callback', (tester) async {
      var retryCount = 0;
      await tester.pumpWidget(buildTestWidget(
        AppErrorState(message: 'Erro', onRetry: () => retryCount++),
      ));

      await tester.tap(find.text('Tentar novamente'));
      expect(retryCount, 1);
    });
  });
}
