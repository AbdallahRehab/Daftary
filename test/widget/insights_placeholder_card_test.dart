import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/dashboard/presentation/widgets/insights_placeholder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// SC-004: the Insights placeholder may only ever render its approved
/// title and copy. Golden strings are hardcoded on purpose — a future
/// "helpful" hardcoded insight must fail this test.
void main() {
  const golden = {
    'en': (
      title: 'Insights',
      placeholder: 'Insights will appear here once the AI Assistant is set up.',
    ),
    'ar': (
      title: 'رؤى',
      placeholder: 'ستظهر الرؤى هنا بعد إعداد المساعد الذكي.',
    ),
  };

  for (final entry in golden.entries) {
    testWidgets(
      'renders only the approved ${entry.key} title and placeholder copy',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildLightTheme(),
            locale: Locale(entry.key),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: InsightsPlaceholderCard()),
          ),
        );

        final card = find.byType(InsightsPlaceholderCard);
        final texts = tester
            .widgetList<Text>(
              find.descendant(of: card, matching: find.byType(Text)),
            )
            .map((text) => text.data)
            .toList();

        expect(texts, [entry.value.title, entry.value.placeholder]);
        // No text reaches the screen other than through those two widgets
        // (icons render their glyph via RichText too, so they're excluded).
        final allRichText = find
            .descendant(of: card, matching: find.byType(RichText))
            .evaluate()
            .length;
        final iconRichText = find
            .descendant(
              of: find.descendant(of: card, matching: find.byType(Icon)),
              matching: find.byType(RichText),
            )
            .evaluate()
            .length;
        expect(allRichText - iconRichText, 2);
      },
    );
  }
}
