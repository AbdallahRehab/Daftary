import 'package:daftary/core/design_system/currency_picker.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/add_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/edit_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_entry_form_cubit.dart';
import 'package:daftary/features/finance/presentation/pages/finance_entry_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/conversion_fakes.dart';

class _MockAddFinanceEntry extends Mock implements AddFinanceEntry {}

class _MockEditFinanceEntry extends Mock implements EditFinanceEntry {}

class _MockGetCategories extends Mock implements GetCategories {}

class _MockFinanceRepository extends Mock implements FinanceRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

/// 022 E3: changing the currency of an existing entry asks first.
void main() {
  final now = DateTime(2026, 1, 1);
  final groceries = Category(
    id: 'seed_groceries',
    name: 'Groceries',
    type: FinanceEntryType.expense,
    icon: 'groceries',
    isDefault: true,
    createdAt: now,
    updatedAt: now,
  );
  final entry = FinanceEntry(
    id: 'e1',
    idempotencyKey: 'k',
    categoryId: groceries.id,
    type: FinanceEntryType.expense,
    amount: const Money.egp(15050),
    date: now,
    createdAt: now,
  );

  late FinanceEntryFormCubit cubit;

  setUpAll(() => registerFallbackValue(FinanceEntryType.expense));

  setUp(() {
    final getCategories = _MockGetCategories();
    when(
      () => getCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => Right<Failure, List<Category>>([groceries]));
    final finance = _MockFinanceRepository();
    when(
      () => finance.getEntryById('e1'),
    ).thenAnswer((_) async => Right(entry));
    final categories = _MockCategoryRepository();
    when(
      () => categories.getCategoryById(groceries.id),
    ).thenAnswer((_) async => Right(groceries));
    getIt
      ..registerSingleton<FinanceRepository>(finance)
      ..registerSingleton<CategoryRepository>(categories)
      ..registerFactory<FinanceEntryFormCubit>(
        () => cubit = FinanceEntryFormCubit(
          _MockAddFinanceEntry(),
          _MockEditFinanceEntry(),
          getCategories,
          EgpFormatter(),
          FakeGetPrimaryCurrency(),
        ),
      );
  });
  tearDown(() => getIt.reset());

  for (final locale in ['en', 'ar']) {
    group(locale, () {
      Future<AppLocalizations> pump(
        WidgetTester tester, {
        bool edit = true,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildLightTheme(),
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FinanceEntryFormPage(editingEntryId: edit ? 'e1' : null),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        return AppLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        )!;
      }

      Future<void> pickUsd(WidgetTester tester) async {
        await tester.tap(find.byType(CurrencyPicker));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('${Currency.usd.displayName(locale)} (USD)').last,
        );
        await tester.pumpAndSettle();
      }

      testWidgets('editing: asks first, buttons are accessible, cancel '
          'keeps the original currency', (tester) async {
        final l10n = await pump(tester);

        await pickUsd(tester);

        expect(find.text(l10n.editCurrencyConfirmTitle), findsOneWidget);
        expect(
          find.text(l10n.editCurrencyConfirmMessage('150.50', 'EGP', 'USD')),
          findsOneWidget,
        );
        final dialog = find.byType(AlertDialog);
        for (final button in [
          find.descendant(of: dialog, matching: find.byType(TextButton)),
          find.descendant(of: dialog, matching: find.byType(FilledButton)),
        ]) {
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        }
        expect(
          tester
              .getSemantics(
                find.descendant(
                  of: dialog,
                  matching: find.text(l10n.commonConfirm),
                ),
              )
              .label,
          contains(l10n.commonConfirm),
        );
        expect(cubit.state.currency, Currency.egp);

        await tester.tap(find.text(l10n.commonCancel));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(cubit.state.currency, Currency.egp);
        expect(cubit.state.pendingCurrency, isNull);
      });

      testWidgets('editing: confirm applies the new currency', (tester) async {
        final l10n = await pump(tester);

        await pickUsd(tester);
        await tester.tap(find.text(l10n.commonConfirm));
        await tester.pumpAndSettle();

        expect(cubit.state.currency, Currency.usd);
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('create mode: applied with no dialog', (tester) async {
        await pump(tester, edit: false);

        await pickUsd(tester);

        expect(find.byType(AlertDialog), findsNothing);
        expect(cubit.state.currency, Currency.usd);
      });
    });
  }
}
