import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MoneyTransaction buildTransaction({required TransactionDirection direction}) {
    return MoneyTransaction(
      id: 't1',
      idempotencyKey: 'k1',
      personId: 'p1',
      amount: const Money.fromMinorUnits(1000),
      direction: direction,
      kind: TransactionKind.initialExchange,
      date: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Widget wrap(ThemeData theme, MoneyTransaction transaction) {
    return MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: TransactionListTile(transaction: transaction)),
    );
  }

  for (final theme in {
    'Light': buildLightTheme(),
    'Dark': buildDarkTheme(),
  }.entries) {
    group('under ${theme.key} theme', () {
      testWidgets(
        'a given transaction always shows the direction icon alongside the '
        'amount color',
        (tester) async {
          await tester.pumpWidget(
            wrap(
              theme.value,
              buildTransaction(direction: TransactionDirection.given),
            ),
          );

          expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
        },
      );

      testWidgets(
        'a received transaction always shows the direction icon alongside '
        'the amount color',
        (tester) async {
          await tester.pumpWidget(
            wrap(
              theme.value,
              buildTransaction(direction: TransactionDirection.received),
            ),
          );

          expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
        },
      );
    });
  }
}
