import 'package:daftary/core/design_system/currency_indicator_chip.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MoneyTransaction buildTransaction({
    required TransactionDirection direction,
    TransactionKind kind = TransactionKind.initialExchange,
    String? occasionId,
  }) {
    return MoneyTransaction(
      id: 't1',
      idempotencyKey: 'k1',
      personId: 'p1',
      amount: const Money.egp(1000),
      direction: direction,
      kind: kind,
      date: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      occasionId: occasionId,
    );
  }

  Widget wrap(
    ThemeData theme,
    MoneyTransaction transaction, {
    String? occasionName,
  }) {
    return MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TransactionListTile(
          transaction: transaction,
          occasionName: occasionName,
        ),
      ),
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

      testWidgets(
        'an occasion contribution shows the occasion name and not the '
        'repayment label (008 US2 Acceptance Scenario 4)',
        (tester) async {
          await tester.pumpWidget(
            wrap(
              theme.value,
              buildTransaction(
                direction: TransactionDirection.received,
                kind: TransactionKind.occasionContribution,
                occasionId: 'o1',
              ),
              occasionName: "Ahmed's wedding",
            ),
          );

          final l10n = await AppLocalizations.delegate.load(const Locale('en'));
          expect(find.text("Ahmed's wedding"), findsOneWidget);
          expect(find.text(l10n.repaymentLabel), findsNothing);
        },
      );

      testWidgets('a repayment keeps its own label and shows no occasion '
          'name', (tester) async {
        await tester.pumpWidget(
          wrap(
            theme.value,
            buildTransaction(
              direction: TransactionDirection.received,
              kind: TransactionKind.repayment,
            ),
            occasionName: "Ahmed's wedding",
          ),
        );

        final l10n = await AppLocalizations.delegate.load(const Locale('en'));
        expect(find.text(l10n.repaymentLabel), findsOneWidget);
        expect(find.text("Ahmed's wedding"), findsNothing);
      });

      testWidgets(
        'an ordinary transaction never renders an occasion name, even if one '
        'is supplied',
        (tester) async {
          await tester.pumpWidget(
            wrap(
              theme.value,
              buildTransaction(direction: TransactionDirection.given),
              occasionName: "Ahmed's wedding",
            ),
          );

          expect(find.text("Ahmed's wedding"), findsNothing);
        },
      );

      testWidgets(
        'a contribution whose occasion name is unresolved renders no badge '
        'rather than an empty one',
        (tester) async {
          await tester.pumpWidget(
            wrap(
              theme.value,
              buildTransaction(
                direction: TransactionDirection.received,
                kind: TransactionKind.occasionContribution,
                occasionId: 'o1',
              ),
            ),
          );

          final l10n = await AppLocalizations.delegate.load(const Locale('en'));
          expect(find.text(l10n.directionReceived), findsOneWidget);
          expect(find.text(''), findsNothing);
        },
      );
    });
  }

  group('currency indicator (018 FR-010)', () {
    Widget tile(Money amount, {Currency primary = Currency.egp}) => MaterialApp(
      theme: buildLightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TransactionListTile(
          primaryCurrency: primary,
          transaction: MoneyTransaction(
            id: 't1',
            idempotencyKey: 'k1',
            personId: 'p1',
            amount: amount,
            direction: TransactionDirection.given,
            kind: TransactionKind.initialExchange,
            date: DateTime(2026, 1, 1),
            createdAt: DateTime(2026, 1, 1),
          ),
        ),
      ),
    );

    testWidgets('a primary-currency record shows no chip (EGP-only UI '
        'unchanged)', (tester) async {
      await tester.pumpWidget(tile(const Money.egp(1000)));

      expect(find.byType(CurrencyIndicatorChip), findsNothing);
      expect(find.text('10.00 EGP'), findsOneWidget);
    });

    testWidgets('a non-primary record shows its own currency chip and '
        'amount', (tester) async {
      await tester.pumpWidget(
        tile(const Money.fromMinorUnits(1050, Currency.usd)),
      );

      expect(find.byKey(const Key('currency_chip_USD')), findsOneWidget);
      expect(find.text('10.50 USD'), findsOneWidget);
    });

    testWidgets('an EGP record under a USD primary shows the EGP chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        tile(const Money.egp(1000), primary: Currency.usd),
      );

      expect(find.byKey(const Key('currency_chip_EGP')), findsOneWidget);
    });
  });

  testWidgets('Arabic: direction label, amount with its currency and '
      'right-to-left direction (RTL-09)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TransactionListTile(
            transaction: buildTransaction(
              direction: TransactionDirection.received,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('ar'));
    final amount = EgpFormatter(
      locale: 'ar',
    ).formatWithSymbol(const Money.egp(1000));
    expect(amount, contains('EGP'));
    expect(find.text(l10n.directionReceived), findsOneWidget);
    expect(find.text(amount), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(TransactionListTile))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
