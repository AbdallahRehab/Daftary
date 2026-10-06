import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/presentation/widgets/balance_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(ThemeData theme, RelationshipStatus status, {Locale? locale}) {
    return MaterialApp(
      locale: locale,
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: BalanceStatusBadge(status: status)),
    );
  }

  for (final theme in {
    'Light': buildLightTheme(),
    'Dark': buildDarkTheme(),
  }.entries) {
    group('under ${theme.key} theme', () {
      testWidgets(
        'theyOweYou renders the down arrow icon and label alongside color',
        (tester) async {
          await tester.pumpWidget(
            wrap(theme.value, RelationshipStatus.theyOweYou),
          );

          expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
          expect(find.text('They owe you'), findsOneWidget);
        },
      );

      testWidgets(
        'youOweThem renders the up arrow icon and label alongside color',
        (tester) async {
          await tester.pumpWidget(
            wrap(theme.value, RelationshipStatus.youOweThem),
          );

          expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
          expect(find.text('You owe them'), findsOneWidget);
        },
      );

      testWidgets('settled renders the check icon and label alongside color', (
        tester,
      ) async {
        await tester.pumpWidget(wrap(theme.value, RelationshipStatus.settled));

        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        expect(find.text('Settled'), findsOneWidget);
      });
    });
  }

  testWidgets('Arabic: each status renders its Arabic label, right-to-left '
      '(RTL-09)', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('ar'));
    final expected = {
      RelationshipStatus.theyOweYou: l10n.filterTheyOweYou,
      RelationshipStatus.youOweThem: l10n.filterYouOweThem,
      RelationshipStatus.settled: l10n.filterSettled,
    };

    for (final entry in expected.entries) {
      await tester.pumpWidget(
        wrap(buildLightTheme(), entry.key, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(BalanceStatusBadge))),
        TextDirection.rtl,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
