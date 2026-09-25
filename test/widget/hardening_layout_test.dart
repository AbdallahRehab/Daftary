import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/presentation/widgets/person_list_tile.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Worst-case inputs on the narrowest common phone at 2x system text, in
/// both languages: rows must lay out without overflow, keep the name
/// visible, and never drop digits from an amount.
void main() {
  final now = DateTime(2026);
  const longName =
      'Abdelrahman Mohamed Abdelaziz El-Sayed Hassanein Mahmoud 😀';
  final person = Person(
    id: 'p1',
    name: longName,
    relationshipTag: 'Colleague from the old office',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
  // The largest amount CurrencyFormatter.parse accepts.
  const huge = Money.egp(99999999999999);

  Widget harness(Widget child, String locale) => MaterialApp(
    theme: buildLightTheme(),
    locale: Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 640),
        textScaler: TextScaler.linear(2),
      ),
      child: Scaffold(body: ListView(children: [child])),
    ),
  );

  Future<void> setPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final locale in ['en', 'ar']) {
    testWidgets('person row with a long name and huge amount ($locale)', (
      tester,
    ) async {
      await setPhone(tester);
      await tester.pumpWidget(
        harness(
          PersonListTile(
            person: person,
            balance: const PersonBalance(personId: 'p1', net: huge),
            onArchive: () {},
          ),
          locale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Abdelrahman'), findsOneWidget);
      // Scaled to fit, never truncated: every digit is still rendered.
      expect(find.textContaining('999,999,999,999.99'), findsOneWidget);
    });

    testWidgets('blocked multi-currency person row ($locale)', (tester) async {
      await setPhone(tester);
      await tester.pumpWidget(
        harness(
          PersonListTile(
            person: person,
            balance: const PersonBalance.blocked(
              personId: 'p1',
              nativeNets: [
                Money.egp(99999999999999),
                Money.fromMinorUnits(99999999999999, Currency.usd),
                Money.fromMinorUnits(99999999999999, Currency.sar),
              ],
              missingRatesFor: [Currency.usd, Currency.sar],
            ),
            onArchive: () {},
          ),
          locale,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('transaction row with a foreign huge amount ($locale)', (
      tester,
    ) async {
      await setPhone(tester);
      await tester.pumpWidget(
        harness(
          TransactionListTile(
            transaction: MoneyTransaction(
              id: 't1',
              idempotencyKey: 'k1',
              personId: 'p1',
              amount: const Money.fromMinorUnits(99999999999999, Currency.usd),
              direction: TransactionDirection.given,
              kind: TransactionKind.repayment,
              date: now,
              note: 'A very long note ' * 20,
              createdAt: now,
              editedAt: now,
            ),
            onDelete: () {},
          ),
          locale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
