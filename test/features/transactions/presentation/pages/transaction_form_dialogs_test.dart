import 'package:daftary/core/design_system/currency_picker.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/add_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/edit_transaction.dart';
import 'package:daftary/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:daftary/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/currency_test_doubles.dart';
import '../../helpers/duplicate_test_doubles.dart';

class _MockPeopleRepository extends Mock implements PeopleRepository {}

class _MockCreatePerson extends Mock implements CreatePerson {}

class _MockAddTransaction extends Mock implements AddTransaction {}

class _MockEditTransaction extends Mock implements EditTransaction {}

/// 022 E3 (currency change confirmation while editing) and C4 (possible
/// duplicate confirmation while creating) on the transaction form.
void main() {
  final now = DateTime(2026, 1, 1);
  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
  final existing = MoneyTransaction(
    id: 't1',
    idempotencyKey: 'k',
    personId: 'p1',
    amount: const Money.egp(150000),
    direction: TransactionDirection.given,
    kind: TransactionKind.initialExchange,
    date: now,
    createdAt: now,
  );

  late _MockAddTransaction addTransaction;
  late MockFindPossibleDuplicate finder;
  late TransactionFormCubit cubit;

  setUpAll(() {
    registerFallbackValue(const Money.egp(0));
    registerFallbackValue(TransactionDirection.given);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    addTransaction = _MockAddTransaction();
    finder = findPossibleDuplicateReturning(existing);
    when(
      () => addTransaction(
        idempotencyKey: any(named: 'idempotencyKey'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        direction: any(named: 'direction'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Right(existing));
    getIt.registerFactory<TransactionFormCubit>(
      () => cubit = TransactionFormCubit(
        _MockPeopleRepository(),
        _MockCreatePerson(),
        addTransaction,
        _MockEditTransaction(),
        getPrimaryCurrencyReturning(),
        finder,
      ),
    );
  });
  tearDown(() => getIt.reset());

  Future<AppLocalizations> pump(
    WidgetTester tester,
    String locale, {
    bool edit = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: edit
            ? TransactionFormPage(
                editingTransaction: existing,
                editingPerson: ahmed,
              )
            : const TransactionFormPage(),
      ),
    );
    await tester.pump();
    return AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
  }

  void expectAccessibleDialogButtons(WidgetTester tester, String confirmText) {
    final dialog = find.byType(AlertDialog);
    for (final button in [
      find.descendant(of: dialog, matching: find.byType(TextButton)),
      find.descendant(of: dialog, matching: find.byType(FilledButton)),
    ]) {
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
    }
    expect(
      tester
          .getSemantics(
            find.descendant(of: dialog, matching: find.text(confirmText)),
          )
          .label,
      contains(confirmText),
    );
  }

  for (final locale in ['en', 'ar']) {
    group('E3 · $locale', () {
      Future<void> pickUsd(WidgetTester tester) async {
        await tester.tap(find.byKey(CurrencyPicker.fieldKey));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('${Currency.usd.displayName(locale)} (USD)').last,
        );
        await tester.pumpAndSettle();
      }

      testWidgets('picking a currency while editing asks first; cancel '
          'keeps the original', (tester) async {
        final l10n = await pump(tester, locale, edit: true);

        await pickUsd(tester);

        expect(find.text(l10n.editCurrencyConfirmTitle), findsOneWidget);
        expect(
          find.text(l10n.editCurrencyConfirmMessage('1,500.00', 'EGP', 'USD')),
          findsOneWidget,
        );
        expect(cubit.state.currency, Currency.egp);
        expectAccessibleDialogButtons(tester, l10n.commonConfirm);

        await tester.tap(find.text(l10n.commonCancel));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(cubit.state.currency, Currency.egp);
        expect(cubit.state.pendingCurrency, isNull);
        expect(
          tester.widget<CurrencyPicker>(find.byType(CurrencyPicker)).value,
          Currency.egp,
        );
      });

      testWidgets('confirm applies the new currency', (tester) async {
        final l10n = await pump(tester, locale, edit: true);

        await pickUsd(tester);
        await tester.tap(find.text(l10n.commonConfirm));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(cubit.state.currency, Currency.usd);
        expect(
          tester.widget<CurrencyPicker>(find.byType(CurrencyPicker)).value,
          Currency.usd,
        );
      });

      testWidgets('create mode applies the currency with no dialog', (
        tester,
      ) async {
        await pump(tester, locale);

        await pickUsd(tester);

        expect(find.byType(AlertDialog), findsNothing);
        expect(cubit.state.currency, Currency.usd);
      });
    });

    group('C4 · $locale', () {
      Future<AppLocalizations> pumpReady(WidgetTester tester) async {
        final l10n = await pump(tester, locale);
        cubit.selectExistingPerson(ahmed);
        await tester.enterText(find.byType(TextField).at(1), '200');
        await tester.pump();
        return l10n;
      }

      Future<void> tapSave(WidgetTester tester, AppLocalizations l10n) async {
        await tester.ensureVisible(find.text(l10n.commonSave));
        await tester.tap(find.text(l10n.commonSave));
        await tester.pumpAndSettle();
      }

      void verifyAdds(int times) {
        Future<Object?> call() => addTransaction(
          idempotencyKey: any(named: 'idempotencyKey'),
          personId: any(named: 'personId'),
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        );
        times == 0 ? verifyNever(call) : verify(call).called(times);
      }

      testWidgets('a duplicate asks first; cancel saves nothing', (
        tester,
      ) async {
        final l10n = await pumpReady(tester);

        await tapSave(tester, l10n);

        expect(find.text(l10n.transactionDuplicateTitle), findsOneWidget);
        expect(find.text(l10n.transactionDuplicateMessage), findsOneWidget);
        expectAccessibleDialogButtons(tester, l10n.commonSave);
        verifyAdds(0);

        await tester.tap(find.text(l10n.commonCancel));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        verifyAdds(0);
        expect(cubit.state.possibleDuplicate, isNull);
      });

      testWidgets('confirm saves exactly one row', (tester) async {
        final l10n = await pumpReady(tester);

        await tapSave(tester, l10n);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(l10n.commonSave),
          ),
        );
        await tester.pumpAndSettle();

        verifyAdds(1);
      });
    });
  }
}
