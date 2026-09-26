import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/currency/domain/entities/conversion_result.dart';
import 'package:daftary/features/currency/domain/repositories/currency_repository.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/presentation/pages/currency_settings_page.dart';
import 'package:daftary/features/currency/presentation/pages/exchange_rate_form_page.dart';
import 'package:daftary/features/currency/presentation/pages/exchange_rate_list_page.dart';
import 'package:daftary/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/main.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// T055 (currency part) — end-to-end coverage of US3 against the real app:
/// real DI, the real drift schema (on a fresh in-memory database, never the
/// device's own file), the real repository, use cases and screens —
/// following quickstart.md Scenario 3:
///  - set the primary currency (no records → no prompt);
///  - add / edit / remove an exchange rate through the UI;
///  - forced-rate-on-switch when records exist in the outgoing primary
///    (FR-012);
///  - removing a rate re-blocks a total that needed it (FR-009).
///
/// Zero network activity (FR-014, T054) is guaranteed structurally:
/// nothing under `lib/features/currency/` or `lib/core/money/` imports a
/// network package (`http`, `dio`, `dart:io` sockets, `HttpClient`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await configureDependencies();
    getIt
      ..unregister<db.AppDatabase>()
      ..registerSingleton<db.AppDatabase>(
        db.AppDatabase.forTesting(NativeDatabase.memory()),
      );
    // 019: the app shows the splash until startup (settings + onboarding
    // gate) is ready, so run it exactly like `main()` does. This file's
    // fresh in-memory database has no onboarding row, so mark onboarding
    // complete first — these flows never exercised the onboarding gate
    // before 019 and must keep landing on their own screens.
    await getIt<OnboardingRepository>().completeOnboarding();
    await getIt<AppStartupCubit>().start();
  });

  setUp(() async {
    final database = getIt<db.AppDatabase>();
    await database.delete(database.exchangeRates).go();
    await database.delete(database.primaryCurrencySettings).go();
    await database.delete(database.financeEntries).go();
    await database.delete(database.moneyTransactions).go();
  });

  CurrencyRepository repository() => getIt<CurrencyRepository>();

  Future<Currency> primary() async => (await repository().getPrimaryCurrency())
      .getOrElse((f) => fail('unexpected $f'))
      .currency;

  Future<void> open(WidgetTester tester, String location) async {
    appRouter.go(location);
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  Future<void> choosePrimary(WidgetTester tester, Currency currency) async {
    await tester.tap(find.byKey(CurrencySettingsView.changeButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(Key('primary_currency_option_${currency.code}')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> saveRateForm(WidgetTester tester, String rate) async {
    await tester.enterText(find.byKey(ExchangeRateFormView.rateFieldKey), rate);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ExchangeRateFormView.saveButtonKey));
    await tester.pumpAndSettle();
  }

  /// A live EGP finance entry, so EGP counts as "in use" for FR-012.
  Future<void> seedEgpRecord() async {
    final database = getIt<db.AppDatabase>();
    final category = await database
        .select(database.financeCategories)
        .get()
        .then((rows) => rows.first);
    await database
        .into(database.financeEntries)
        .insert(
          db.FinanceEntriesCompanion.insert(
            id: 'currency-flow-entry',
            idempotencyKey: 'currency-flow-entry',
            categoryId: category.id,
            type: category.type,
            amountMinorUnits: 10000,
            currencyCode: const Value('EGP'),
            date: DateTime(2026, 9).millisecondsSinceEpoch,
            createdAt: DateTime(2026, 9).millisecondsSinceEpoch,
          ),
        );
  }

  testWidgets('set primary currency with no records: switches immediately', (
    tester,
  ) async {
    await open(tester, CurrencyRoutes.settings);
    expect(find.text('Egyptian Pound (EGP)'), findsOneWidget);

    await choosePrimary(tester, Currency.usd);

    expect(find.byType(SwitchRateDialog), findsNothing);
    expect(find.text('US Dollar (USD)'), findsOneWidget);
    expect(await primary(), Currency.usd);
  });

  testWidgets('add, edit and remove an exchange rate', (tester) async {
    await open(tester, CurrencyRoutes.rates);
    expect(find.text('No exchange rates yet'), findsOneWidget);
    expect(find.byKey(ExchangeRateListView.disclosureKey), findsOneWidget);

    // Add: the picker defaults to the first non-primary currency (USD).
    await tester.tap(find.byKey(ExchangeRateListView.addButtonKey));
    await tester.pumpAndSettle();
    await saveRateForm(tester, '50.25');
    expect(find.text('1 USD = 50.25 EGP'), findsOneWidget);

    // Edit: prefilled, same row updated in place.
    await tester.tap(find.text('1 USD = 50.25 EGP'));
    await tester.pumpAndSettle();
    expect(find.text('50.25'), findsOneWidget);
    await saveRateForm(tester, '51');
    expect(find.text('1 USD = 51 EGP'), findsOneWidget);
    final rates = (await repository().getExchangeRates()).getOrElse(
      (f) => fail('unexpected $f'),
    );
    expect(rates, hasLength(1));

    // Remove, after confirming.
    await tester.tap(find.byKey(const Key('exchange_rate_remove_USD')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove rate'));
    await tester.pumpAndSettle();
    expect(find.text('No exchange rates yet'), findsOneWidget);
  });

  testWidgets('switching away from a primary that has records forces a rate '
      '(FR-012)', (tester) async {
    await seedEgpRecord();
    await open(tester, CurrencyRoutes.settings);

    await choosePrimary(tester, Currency.usd);
    expect(find.byType(SwitchRateDialog), findsOneWidget);
    expect(await primary(), Currency.egp, reason: 'not switched yet');

    // Cancelling keeps EGP.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await primary(), Currency.egp);

    // Retrying and entering the rate completes the switch.
    await choosePrimary(tester, Currency.usd);
    await tester.enterText(find.byKey(SwitchRateDialog.rateFieldKey), '0.02');
    await tester.tap(find.byKey(SwitchRateDialog.confirmKey));
    await tester.pumpAndSettle();

    expect(await primary(), Currency.usd);
    final rates = (await repository().getExchangeRates()).getOrElse(
      (f) => fail('unexpected $f'),
    );
    expect(rates.single.currency, Currency.egp);
    expect(rates.single.relativeTo, Currency.usd);
    expect(rates.single.rateMicros, 20000);
  });

  testWidgets('removing a rate re-blocks a total that needed it (FR-009)', (
    tester,
  ) async {
    await repository().setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 50,
    );
    final converter = getIt<CurrencyConverter>();
    final amounts = [
      Money.fromMinorUnits(10000, Currency.egp),
      Money.fromMinorUnits(200, Currency.usd),
    ];

    Future<SumResult> total() async {
      final context = (await getIt<GetConversionContext>()()).getOrElse(
        (f) => fail('unexpected $f'),
      );
      return converter.sumToTargetCurrency(
        amounts: amounts,
        targetCurrency: context.primary,
        rates: context.rates,
      );
    }

    expect(
      await total(),
      SumResult.total(Money.fromMinorUnits(20000, Currency.egp)),
    );

    await repository().removeExchangeRate('USD');

    expect(await total(), const SumResult.blocked([Currency.usd]));
  });
}
