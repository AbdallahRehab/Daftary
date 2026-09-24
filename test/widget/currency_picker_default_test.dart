import 'package:daftary/core/design_system/currency_picker.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/add_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/edit_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_entry_form_cubit.dart';
import 'package:daftary/features/finance/presentation/pages/finance_entry_form_page.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:daftary/features/transactions/domain/usecases/add_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/edit_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/record_repayment.dart';
import 'package:daftary/features/transactions/presentation/cubit/repayment_form_cubit.dart';
import 'package:daftary/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:daftary/features/transactions/presentation/pages/repayment_form_page.dart';
import 'package:daftary/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../features/transactions/helpers/currency_test_doubles.dart';

class _MockPeopleRepository extends Mock implements PeopleRepository {}

class _MockCreatePerson extends Mock implements CreatePerson {}

class _MockAddTransaction extends Mock implements AddTransaction {}

class _MockEditTransaction extends Mock implements EditTransaction {}

class _MockRecordRepayment extends Mock implements RecordRepayment {}

class _MockAddFinanceEntry extends Mock implements AddFinanceEntry {}

class _MockEditFinanceEntry extends Mock implements EditFinanceEntry {}

class _MockGetCategories extends Mock implements GetCategories {}

/// 018 T037 (+ T039 verification) — every amount-entry form's
/// `CurrencyPicker` defaults to the user's current primary currency, read
/// live through `GetPrimaryCurrency`, never a hardcoded EGP.
///
/// Each test pumps the REAL page (so the page's own `BlocProvider` wiring —
/// the call to `loadDefaultCurrency()` / `initialize()` — is what is under
/// test), with only the page's cubit registered in `getIt` over mocked use
/// cases. A primary currency other than EGP (USD, and EUR as a second
/// witness) is the only way to tell "comes from GetPrimaryCurrency" apart
/// from "hardcoded EGP", which is exactly the distinction T039 asks for.
///
/// Scope: the tasks list five affected forms, but only three exist in this
/// codebase — the transaction form and repayment form (feature 001) and the
/// finance entry form (feature 007). Occasions (008), Budgets (010) and
/// Savings goals (011) are not implemented, so they have no form to test.
void main() {
  final groceries = Category(
    id: 'seed_groceries',
    name: 'Groceries',
    type: CategoryType.expense,
    icon: 'groceries',
    isDefault: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUpAll(() => registerFallbackValue(FinanceEntryType.expense));

  late Currency primary;
  TransactionFormCubit? transactionCubit;
  RepaymentFormCubit? repaymentCubit;
  FinanceEntryFormCubit? financeCubit;

  setUp(() {
    primary = Currency.usd;
    transactionCubit = null;
    repaymentCubit = null;
    financeCubit = null;

    final getCategories = _MockGetCategories();
    when(
      () => getCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => Right<Failure, List<Category>>([groceries]));

    // Each factory reads `primary` lazily, so a test can set it before
    // pumping the page.
    getIt.registerFactory<TransactionFormCubit>(
      () => transactionCubit = TransactionFormCubit(
        _MockPeopleRepository(),
        _MockCreatePerson(),
        _MockAddTransaction(),
        _MockEditTransaction(),
        getPrimaryCurrencyReturning(primary),
      ),
    );
    getIt.registerFactoryParam<RepaymentFormCubit, String, void>(
      (personId, _) => repaymentCubit = RepaymentFormCubit(
        _MockRecordRepayment(),
        getPrimaryCurrencyReturning(primary),
        personId,
      ),
    );
    getIt.registerFactory<FinanceEntryFormCubit>(
      () => financeCubit = FinanceEntryFormCubit(
        _MockAddFinanceEntry(),
        _MockEditFinanceEntry(),
        getCategories,
        EgpFormatter(),
        getPrimaryCurrencyReturning(primary),
      ),
    );
  });

  // The pages' BlocProviders own (and close) the cubits.
  tearDown(() => getIt.reset());

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    );
    // Not pumpAndSettle: some forms show an indeterminate progress
    // indicator while loading, which never settles. A few frames are enough
    // for the mocked async default to arrive.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// The currency the rendered picker is actually showing.
  Currency shownCurrency(WidgetTester tester) {
    final picker = tester.widget<CurrencyPicker>(find.byType(CurrencyPicker));
    return picker.value;
  }

  String pickerLabel(Currency currency) =>
      '${currency.nameEn} (${currency.code})';

  final forms = <String, Widget Function()>{
    'transaction form (001)': () => const TransactionFormPage(),
    'repayment form (001)': () => const RepaymentFormPage(personId: 'p1'),
    'finance entry form, expense (007)': () =>
        const FinanceEntryFormPage(initialType: FinanceEntryType.expense),
    'finance entry form, income (007)': () =>
        const FinanceEntryFormPage(initialType: FinanceEntryType.income),
  };

  Currency cubitCurrency() =>
      transactionCubit?.state.currency ??
      repaymentCubit?.state.currency ??
      financeCubit!.state.currency;

  for (final MapEntry(key: name, value: build) in forms.entries) {
    group(name, () {
      testWidgets('defaults to USD when the primary currency is USD', (
        tester,
      ) async {
        primary = Currency.usd;
        await pumpPage(tester, build());

        expect(cubitCurrency(), Currency.usd);
        expect(shownCurrency(tester), Currency.usd);
        expect(find.text(pickerLabel(Currency.usd)), findsOneWidget);
        expect(find.text(pickerLabel(Currency.egp)), findsNothing);
      });

      testWidgets('defaults to EUR when the primary currency is EUR — the '
          'default tracks the setting rather than any fixed value', (
        tester,
      ) async {
        primary = Currency.eur;
        await pumpPage(tester, build());

        expect(cubitCurrency(), Currency.eur);
        expect(shownCurrency(tester), Currency.eur);
        expect(find.text(pickerLabel(Currency.eur)), findsOneWidget);
      });

      testWidgets('still defaults to EGP for an EGP-primary user (pre-018 '
          'behavior unchanged)', (tester) async {
        primary = Currency.egp;
        await pumpPage(tester, build());

        expect(cubitCurrency(), Currency.egp);
        expect(shownCurrency(tester), Currency.egp);
        expect(find.text(pickerLabel(Currency.egp)), findsOneWidget);
      });
    });
  }

  testWidgets('a currency the user picked is not overwritten by the '
      'primary-currency default (transaction form)', (tester) async {
    primary = Currency.usd;
    await pumpPage(tester, const TransactionFormPage());

    final cubit = BlocProvider.of<TransactionFormCubit>(
      tester.element(find.byType(CurrencyPicker)),
    );
    cubit.currencyChanged(Currency.gbp);
    await cubit.loadDefaultCurrency();
    await tester.pump();

    expect(cubit.state.currency, Currency.gbp);
    expect(shownCurrency(tester), Currency.gbp);
  });
}
