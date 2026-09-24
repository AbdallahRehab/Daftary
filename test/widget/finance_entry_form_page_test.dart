import 'package:daftary/core/design_system/currency_picker.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/add_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/edit_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_entry_form_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_entry_form_state.dart';
import 'package:daftary/features/finance/presentation/widgets/category_picker_field.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../features/finance/helpers/conversion_fakes.dart';

class MockAddFinanceEntry extends Mock implements AddFinanceEntry {}

class MockEditFinanceEntry extends Mock implements EditFinanceEntry {}

class MockGetCategories extends Mock implements GetCategories {}

/// T076 — the entry form's two locale-sensitive promises: an amount typed
/// in Arabic-Indic digits must reach the use case as the same integer
/// piastres as its Western equivalent (FR-024), and the validation messages
/// must render in both `ar` and `en` rather than only the template locale.
void main() {
  late MockAddFinanceEntry addFinanceEntry;
  late MockEditFinanceEntry editFinanceEntry;
  late MockGetCategories getCategories;
  late FakeGetPrimaryCurrency getPrimaryCurrency;

  final groceries = Category(
    id: 'seed_groceries',
    name: 'Groceries',
    type: CategoryType.expense,
    icon: 'groceries',
    isDefault: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(const Money.egp(0));
    // `any(named: 'type')` / `any(named: 'date')` need a concrete fallback
    // for each non-nullable matched type.
    registerFallbackValue(FinanceEntryType.expense);
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  setUp(() {
    addFinanceEntry = MockAddFinanceEntry();
    editFinanceEntry = MockEditFinanceEntry();
    getCategories = MockGetCategories();
    getPrimaryCurrency = FakeGetPrimaryCurrency();

    when(
      () => getCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => Right<Failure, List<Category>>([groceries]));
  });

  FinanceEntryFormCubit buildCubit() => FinanceEntryFormCubit(
    addFinanceEntry,
    editFinanceEntry,
    getCategories,
    EgpFormatter(),
    getPrimaryCurrency,
  );

  /// The form's own widget tree, driven by a real cubit over mocked use
  /// cases — the page itself resolves collaborators from `getIt`, which a
  /// widget test has no business bootstrapping.
  Widget wrap(FinanceEntryFormCubit cubit, {required Locale locale}) {
    return MaterialApp(
      // The app's real theme, not Flutter's default: the category chips
      // read `context.financeColors`, which only the app theme registers.
      theme: buildLightTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider.value(
        value: cubit,
        child: const Scaffold(body: _FormHarness()),
      ),
    );
  }

  group('Arabic-Indic numeral input (FR-024)', () {
    testWidgets(
      'an amount typed in Arabic-Indic digits saves the same piastres as '
      'its Western equivalent',
      (tester) async {
        when(
          () => addFinanceEntry(
            idempotencyKey: any(named: 'idempotencyKey'),
            categoryId: any(named: 'categoryId'),
            type: any(named: 'type'),
            amount: any(named: 'amount'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, FinanceEntry>(
            FinanceEntry(
              id: 'e1',
              idempotencyKey: 'k1',
              categoryId: groceries.id,
              type: FinanceEntryType.expense,
              amount: const Money.egp(15050),
              date: DateTime(2026, 1, 1),
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        );

        final cubit = buildCubit();
        addTearDown(cubit.close);
        await cubit.initialize(type: FinanceEntryType.expense);
        await tester.pumpWidget(wrap(cubit, locale: const Locale('ar')));
        await tester.pumpAndSettle();

        cubit.categorySelected(groceries.id);
        // ١٥٠٫٥٠ — Arabic-Indic digits with the Arabic decimal separator.
        cubit.amountChanged('١٥٠٫٥٠');
        await cubit.submit();

        final captured = verify(
          () => addFinanceEntry(
            idempotencyKey: any(named: 'idempotencyKey'),
            categoryId: any(named: 'categoryId'),
            type: any(named: 'type'),
            amount: captureAny(named: 'amount'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        ).captured.single;

        expect(
          captured,
          const Money.egp(15050),
          reason: '١٥٠٫٥٠ EGP is 15050 piastres, exactly as "150.50" would be',
        );
      },
    );

    testWidgets('Western digits parse to the identical amount', (tester) async {
      when(
        () => addFinanceEntry(
          idempotencyKey: any(named: 'idempotencyKey'),
          categoryId: any(named: 'categoryId'),
          type: any(named: 'type'),
          amount: any(named: 'amount'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, FinanceEntry>(
          FinanceEntry(
            id: 'e1',
            idempotencyKey: 'k1',
            categoryId: groceries.id,
            type: FinanceEntryType.expense,
            amount: const Money.egp(15050),
            date: DateTime(2026, 1, 1),
            createdAt: DateTime(2026, 1, 1),
          ),
        ),
      );

      final cubit = buildCubit();
      addTearDown(cubit.close);
      await cubit.initialize(type: FinanceEntryType.expense);
      await tester.pumpWidget(wrap(cubit, locale: const Locale('en')));
      await tester.pumpAndSettle();

      cubit.categorySelected(groceries.id);
      cubit.amountChanged('150.50');
      await cubit.submit();

      final captured = verify(
        () => addFinanceEntry(
          idempotencyKey: any(named: 'idempotencyKey'),
          categoryId: any(named: 'categoryId'),
          type: any(named: 'type'),
          amount: captureAny(named: 'amount'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).captured.single;

      expect(captured, const Money.egp(15050));
    });
  });

  group('currency picker (018)', () {
    testWidgets('a new entry opens on the primary currency, and a picked '
        'currency is what the amount is saved in', (tester) async {
      getPrimaryCurrency.currency = Currency.usd;
      final cubit = buildCubit();
      addTearDown(cubit.close);
      await cubit.initialize(type: FinanceEntryType.expense);
      await tester.pumpWidget(wrap(cubit, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byKey(CurrencyPicker.fieldKey), findsOneWidget);
      expect(find.text('US Dollar (USD)'), findsOneWidget);

      await tester.tap(find.byKey(CurrencyPicker.fieldKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Euro (EUR)').last);
      await tester.pumpAndSettle();

      expect(cubit.state.currency, Currency.eur);
      expect(find.text('Euro (EUR)'), findsOneWidget);
    });
  });

  group('validation messages render in both locales', () {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('a zero amount shows the localized amount error in '
          '${locale.languageCode}', (tester) async {
        final cubit = buildCubit();
        addTearDown(cubit.close);
        await cubit.initialize(type: FinanceEntryType.expense);
        await tester.pumpWidget(wrap(cubit, locale: locale));
        await tester.pumpAndSettle();

        cubit.categorySelected(groceries.id);
        cubit.amountChanged('0');
        await cubit.submit();
        await tester.pumpAndSettle();

        expect(cubit.state.amountInvalid, isTrue);
        verifyNever(
          () => addFinanceEntry(
            idempotencyKey: any(named: 'idempotencyKey'),
            categoryId: any(named: 'categoryId'),
            type: any(named: 'type'),
            amount: any(named: 'amount'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        );

        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.amountInvalidError), findsOneWidget);
      });

      testWidgets('a missing category shows the localized category error in '
          '${locale.languageCode}', (tester) async {
        final cubit = buildCubit();
        addTearDown(cubit.close);
        await cubit.initialize(type: FinanceEntryType.expense);
        await tester.pumpWidget(wrap(cubit, locale: locale));
        await tester.pumpAndSettle();

        cubit.amountChanged('100');
        await cubit.submit();
        await tester.pumpAndSettle();

        expect(cubit.state.categorySelectionRequired, isTrue);

        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.financeCategoryRequiredError), findsOneWidget);
      });
    }

    testWidgets('a rejected amount does not discard entered fields (FR-003)', (
      tester,
    ) async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      await cubit.initialize(type: FinanceEntryType.expense);
      await tester.pumpWidget(wrap(cubit, locale: const Locale('en')));
      await tester.pumpAndSettle();

      cubit.categorySelected(groceries.id);
      cubit.noteChanged('weekly shop');
      cubit.amountChanged('0');
      await cubit.submit();
      await tester.pumpAndSettle();

      expect(cubit.state.amountInvalid, isTrue);
      expect(cubit.state.note, 'weekly shop');
      expect(cubit.state.selectedCategoryId, groceries.id);
      expect(cubit.state.amountInput, '0');
    });
  });
}

/// Renders just the pieces under test — the amount field's error text, the
/// category picker's error text — against the shared cubit, so the test does
/// not depend on the page's `getIt` wiring.
class _FormHarness extends StatelessWidget {
  const _FormHarness();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<FinanceEntryFormCubit, FinanceEntryFormState>(
      builder: (context, state) {
        return Column(
          children: [
            if (state.amountInvalid) Text(l10n.amountInvalidError),
            // Mirrors the page's picker wiring (018 FR-003).
            CurrencyPicker(
              key: ValueKey('finance_entry_currency_${state.currency.code}'),
              value: state.currency,
              onChanged: context.read<FinanceEntryFormCubit>().currencyChanged,
            ),
            CategoryPickerField(
              categories: state.categories,
              type: state.type,
              onManageCategories: () {},
              selectedCategoryId: state.selectedCategoryId,
              isLoading: state.isLoadingCategories,
              errorText: state.categorySelectionRequired
                  ? l10n.financeCategoryRequiredError
                  : null,
              onCategorySelected: context
                  .read<FinanceEntryFormCubit>()
                  .categorySelected,
            ),
          ],
        );
      },
    );
  }
}
