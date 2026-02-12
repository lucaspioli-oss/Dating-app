import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desenrola_ai_keyboard/widgets/app_loading.dart';
import 'package:desenrola_ai_keyboard/config/app_theme.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('AppLoading', () {
    testWidgets('renders spinner', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppLoading(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show message when null', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppLoading(),
      ));

      // Only the spinner, no text
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppLoading(message: 'Carregando planos...'),
      ));

      expect(find.text('Carregando planos...'), findsOneWidget);
    });
  });

  group('AppLoadingScreen', () {
    testWidgets('renders with scaffold and spinner', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AppLoadingScreen(),
      ));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AppLoadingScreen(message: 'Aguarde...'),
      ));

      expect(find.text('Aguarde...'), findsOneWidget);
    });
  });
}
