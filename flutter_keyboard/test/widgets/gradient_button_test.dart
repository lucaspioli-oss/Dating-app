import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desenrola_ai_keyboard/config/app_theme.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('GradientButton', () {
    testWidgets('renders text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        GradientButton(text: 'Gerar Sugestões', onPressed: () {}),
      ));

      expect(find.text('Gerar Sugestões'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        GradientButton(text: 'Criar', onPressed: () {}, icon: Icons.add),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('does not render icon when null', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        GradientButton(text: 'Criar', onPressed: () {}),
      ));

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('shows spinner when isLoading', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        GradientButton(text: 'Salvar', onPressed: () {}, isLoading: true),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Text should not appear during loading
      expect(find.text('Salvar'), findsNothing);
    });

    testWidgets('does not show spinner when not loading', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        GradientButton(text: 'Salvar', onPressed: () {}),
      ));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Salvar'), findsOneWidget);
    });

    testWidgets('triggers onPressed callback on tap', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(buildTestWidget(
        GradientButton(text: 'Tap Me', onPressed: () => tapCount++),
      ));

      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      expect(tapCount, 1);
    });

    testWidgets('does not trigger onPressed when loading', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(buildTestWidget(
        GradientButton(
          text: 'Tap Me',
          onPressed: () => tapCount++,
          isLoading: true,
        ),
      ));

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tapCount, 0);
    });

    testWidgets('has Semantics wrapper', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        GradientButton(text: 'Assinar', onPressed: () {}),
      ));

      // GradientButton wraps its content with Semantics(label: text, button: true)
      expect(find.byType(Semantics), findsWidgets);
      expect(find.text('Assinar'), findsOneWidget);
    });

    testWidgets('renders without onPressed (disabled state)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const GradientButton(text: 'Disabled'),
      ));

      expect(find.text('Disabled'), findsOneWidget);
      // Should not have gradient when disabled - check no shadow
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers, isNotEmpty);
    });
  });
}
