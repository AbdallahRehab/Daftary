import 'package:daftary/core/design_system/app_text_field.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'switching the ambient ThemeMode mid-edit preserves in-progress form '
    'text (FR-012)',
    (tester) async {
      final controller = TextEditingController();

      Widget buildApp(ThemeData theme) {
        return MaterialApp(
          theme: theme,
          home: Scaffold(
            body: AppTextField(label: 'Name', controller: controller),
          ),
        );
      }

      await tester.pumpWidget(buildApp(buildLightTheme()));
      await tester.enterText(find.byType(TextField), 'Ahmed');
      await tester.pump();

      expect(find.text('Ahmed'), findsOneWidget);

      // Rebuild the same widget tree with the dark theme — mirrors
      // MaterialApp.router live-switching `theme`/`darkTheme` with no
      // navigation or widget disposal in between.
      await tester.pumpWidget(buildApp(buildDarkTheme()));
      await tester.pump();

      expect(find.text('Ahmed'), findsOneWidget);
      expect(controller.text, 'Ahmed');
    },
  );
}
