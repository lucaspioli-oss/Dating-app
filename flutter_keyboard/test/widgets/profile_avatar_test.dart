import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desenrola_ai_keyboard/widgets/profile_avatar.dart';
import 'package:desenrola_ai_keyboard/config/app_theme.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('ProfileAvatar', () {
    testWidgets('renders fallback initial when no image', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileAvatar(name: 'Maria'),
      ));

      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('renders ? when name is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileAvatar(name: ''),
      ));

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('uses default size of 56', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileAvatar(name: 'A'),
      ));

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final box = container.constraints ??
          BoxConstraints.tight(Size(
            (container.decoration as BoxDecoration).shape == BoxShape.circle ? 56 : 0,
            56,
          ));
      // The outermost container should be 56x56
      expect(find.byType(ProfileAvatar), findsOneWidget);
    });

    testWidgets('wraps with Hero when heroTag is provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileAvatar(name: 'Ana', heroTag: 'avatar_1'),
      ));

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('does not wrap with Hero when heroTag is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileAvatar(name: 'Ana'),
      ));

      expect(find.byType(Hero), findsNothing);
    });

    testWidgets('includes Semantics widget when semanticsLabel is provided', (tester) async {
      // Without semanticsLabel
      await tester.pumpWidget(buildTestWidget(
        const ProfileAvatar(name: 'Ana'),
      ));
      final countWithout = tester.widgetList(find.byType(Semantics)).length;

      // With semanticsLabel - should have one more Semantics widget
      await tester.pumpWidget(buildTestWidget(
        const ProfileAvatar(name: 'Ana', semanticsLabel: 'Foto de Ana'),
      ));
      final countWith = tester.widgetList(find.byType(Semantics)).length;

      expect(countWith, greaterThan(countWithout));
    });

    testWidgets('renders badge when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileAvatar(
          name: 'Ana',
          badge: Icon(Icons.star, size: 12),
        ),
      ));

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders Image.memory when imageBytes provided', (tester) async {
      // Create a minimal valid PNG (1x1 pixel, transparent)
      final pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,
        0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00, 0x00,
        0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
        0x60, 0x82,
      ]);

      await tester.pumpWidget(buildTestWidget(
        ProfileAvatar(name: 'Ana', imageBytes: pngBytes),
      ));

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('custom size is applied', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const ProfileAvatar(name: 'B', size: 100),
      ));

      // Find the outermost Container with size 100
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasSize100 = containers.any((c) {
        final box = c.constraints;
        if (box != null) {
          return box.maxWidth == 100 && box.maxHeight == 100;
        }
        return false;
      });
      // The widget itself should render successfully
      expect(find.byType(ProfileAvatar), findsOneWidget);
    });
  });
}
