import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desenrola_ai_keyboard/widgets/app_empty_state.dart';
import 'package:desenrola_ai_keyboard/config/app_theme.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('AppEmptyState', () {
    testWidgets('renders icon, title, and description', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppEmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Nenhuma conversa',
          description: 'Comece uma conversa para ver aqui',
        ),
      ));

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.text('Nenhuma conversa'), findsOneWidget);
      expect(find.text('Comece uma conversa para ver aqui'), findsOneWidget);
    });

    testWidgets('does not show CTA when ctaText is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppEmptyState(
          icon: Icons.info,
          title: 'Title',
          description: 'Desc',
        ),
      ));

      expect(find.byType(GradientButton), findsNothing);
    });

    testWidgets('shows CTA button when ctaText and onCta are provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestWidget(
        AppEmptyState(
          icon: Icons.add,
          title: 'Title',
          description: 'Desc',
          ctaText: 'Criar',
          onCta: () => tapped = true,
        ),
      ));

      expect(find.byType(GradientButton), findsOneWidget);
      expect(find.text('Criar'), findsOneWidget);
    });

    testWidgets('does not show CTA when only ctaText is provided (no onCta)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppEmptyState(
          icon: Icons.add,
          title: 'Title',
          description: 'Desc',
          ctaText: 'Criar',
        ),
      ));

      expect(find.byType(GradientButton), findsNothing);
    });
  });
}
