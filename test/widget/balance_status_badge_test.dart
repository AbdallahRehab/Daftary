import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/presentation/widgets/balance_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(ThemeData theme, RelationshipStatus status) {
    return MaterialApp(
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
}
