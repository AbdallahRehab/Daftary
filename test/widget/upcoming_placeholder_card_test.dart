import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/dashboard/presentation/widgets/upcoming_placeholder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// SC-004: the Upcoming placeholder may only ever render its approved
/// title and copy (golden strings hardcoded on purpose), and that copy must
/// stay distinct from the Financial Snapshot's figures (US3 AC3).
void main() {
  const golden = {
    'en': (
      title: 'Upcoming',
      placeholder:
          'Savings goals with a target date will appear here. Upcoming bills '
          'will follow once reminders are available.',
    ),
    'ar': (
      title: 'القادم',
      placeholder:
          'ستظهر هنا أهداف الادخار التي لها تاريخ مستهدف، وستتبعها الفواتير '
          'القادمة بعد توفر التذكيرات.',
    ),
  };

  for (final entry in golden.entries) {
    testWidgets(
      'renders only the approved ${entry.key} title and placeholder copy, '
      'distinct from the Financial Snapshot wording',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildLightTheme(),
            locale: Locale(entry.key),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: UpcomingPlaceholderCard()),
          ),
        );

        final card = find.byType(UpcomingPlaceholderCard);
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

        final l10n = AppLocalizations.of(tester.element(card))!;
        final snapshotCopy = [
          l10n.overviewTotalOwedToYou,
          l10n.overviewTotalYouOwe,
          l10n.homeFinanceThisMonthTitle,
          l10n.homeFinanceIncome,
          l10n.homeFinanceExpenses,
          l10n.homeFinanceNet,
        ];
        for (final text in texts) {
          for (final snapshot in snapshotCopy) {
            expect(text, isNot(snapshot));
            expect(text, isNot(contains(snapshot)));
          }
        }
      },
    );
  }
}
