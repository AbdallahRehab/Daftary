import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/ocr/domain/entities/field_confidence.dart';
import 'package:daftary/features/ocr/presentation/widgets/confidence_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T053 — the trust signals on the review screen (009 FR-013).
///
/// The assertions here are deliberately about *distinctness* rather than
/// about specific colours or glyphs. FR-013's requirement is that a
/// reviewer can tell the three read levels apart, and can tell any of them
/// from a value the app merely inferred; which icon carries that meaning is
/// a design decision that should be free to change without breaking a test.
void main() {
  Future<void> pumpIndicator(
    WidgetTester tester,
    FieldConfidence confidence, {
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        // The indicator reads `context.financeColors`, which only the app's
        // own theme registers.
        theme: theme ?? buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(child: ConfidenceIndicator(confidence: confidence)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The visual identity of a rendering: its glyph plus its label. Two
  /// variants that agree on both are indistinguishable to a user.
  Future<(IconData, String)> identityOf(
    WidgetTester tester,
    FieldConfidence confidence,
  ) async {
    await pumpIndicator(tester, confidence);
    final icon = tester.widget<Icon>(find.byType(Icon).first);
    final text = tester.widget<Text>(find.byType(Text).first);
    return (icon.icon!, text.data!);
  }

  testWidgets('each read level renders a distinct icon and label', (
    tester,
  ) async {
    final low = await identityOf(
      tester,
      FieldConfidence.read(FieldConfidenceLevel.low),
    );
    final medium = await identityOf(
      tester,
      FieldConfidence.read(FieldConfidenceLevel.medium),
    );
    final high = await identityOf(
      tester,
      FieldConfidence.read(FieldConfidenceLevel.high),
    );

    expect({low, medium, high}, hasLength(3));
    expect(
      {low.$1, medium.$1, high.$1},
      hasLength(3),
      reason: 'distinct icons',
    );
    expect(
      {low.$2, medium.$2, high.$2},
      hasLength(3),
      reason: 'distinct labels, so the signal survives greyscale',
    );
  });

  testWidgets('an inferred value is never shown as any level of read — the '
      'anti-goal FR-013 names explicitly', (tester) async {
    final inferred = await identityOf(tester, const FieldConfidence.inferred());

    for (final level in [
      FieldConfidenceLevel.low,
      FieldConfidenceLevel.medium,
      FieldConfidenceLevel.high,
    ]) {
      final read = await identityOf(tester, FieldConfidence.read(level));
      expect(
        inferred,
        isNot(read),
        reason: 'inferred must not be confusable with a $level read',
      );
    }
  });

  testWidgets('an inferred badge is a different shape, not just a quieter '
      'shade of the read badge', (tester) async {
    await pumpIndicator(tester, const FieldConfidence.inferred());
    final inferredBox =
        tester.widget<Container>(find.byType(Container).first).decoration!
            as BoxDecoration;

    await pumpIndicator(tester, FieldConfidence.read(FieldConfidenceLevel.low));
    final readBox =
        tester.widget<Container>(find.byType(Container).first).decoration!
            as BoxDecoration;

    expect(
      inferredBox.border,
      isNotNull,
      reason: 'the inferred badge is outlined',
    );
    expect(readBox.border, isNull, reason: 'a read badge is filled');
    expect(inferredBox.borderRadius, isNot(readBox.borderRadius));
  });

  testWidgets('no variant prints a fabricated percentage', (tester) async {
    for (final confidence in [
      const FieldConfidence.inferred(),
      FieldConfidence.read(FieldConfidenceLevel.low),
      FieldConfidence.read(FieldConfidenceLevel.medium),
      FieldConfidence.read(FieldConfidenceLevel.high),
    ]) {
      await pumpIndicator(tester, confidence);
      expect(
        find.textContaining('%'),
        findsNothing,
        reason: 'the recognizer exposes no score worth rendering as a number',
      );
    }
  });

  testWidgets('every variant carries a screen-reader label', (tester) async {
    for (final confidence in [
      const FieldConfidence.inferred(),
      FieldConfidence.read(FieldConfidenceLevel.low),
      FieldConfidence.read(FieldConfidenceLevel.high),
    ]) {
      await pumpIndicator(tester, confidence);
      // Scoped to the widget under test: the MaterialApp above it wraps the
      // tree in Semantics nodes of its own.
      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(ConfidenceIndicator),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.label, isNotNull);
      expect(semantics.properties.label, isNotEmpty);
    }
  });
}
