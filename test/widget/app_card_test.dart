import 'package:daftary/core/design_system/app_card.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(body: AppCard(child: const Text('content'))),
    );
  }

  Container findDecoratedContainer(WidgetTester tester) {
    return tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AppCard),
            matching: find.byType(Container),
          )
          .first,
    );
  }

  testWidgets('resolves its fill/border from colorScheme under Light theme', (
    tester,
  ) async {
    final theme = buildLightTheme();
    await tester.pumpWidget(wrap(theme));

    final container = findDecoratedContainer(tester);
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, theme.colorScheme.surface);
    expect(
      (decoration.border! as Border).top.color,
      theme.colorScheme.outlineVariant,
    );
  });

  testWidgets('resolves its fill/border from colorScheme under Dark theme', (
    tester,
  ) async {
    final theme = buildDarkTheme();
    await tester.pumpWidget(wrap(theme));

    final container = findDecoratedContainer(tester);
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, theme.colorScheme.surface);
    expect(
      (decoration.border! as Border).top.color,
      theme.colorScheme.outlineVariant,
    );
  });
}
