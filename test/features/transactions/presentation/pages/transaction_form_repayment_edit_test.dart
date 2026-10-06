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
import 'package:mocktail/mocktail.dart';

import '../../helpers/currency_test_doubles.dart';
import '../../helpers/duplicate_test_doubles.dart';

class _MockPeopleRepository extends Mock implements PeopleRepository {}

class _MockCreatePerson extends Mock implements CreatePerson {}

class _MockAddTransaction extends Mock implements AddTransaction {}

class _MockEditTransaction extends Mock implements EditTransaction {}

/// 022 A1: the direction of a repayment cannot be edited.
void main() {
  final now = DateTime(2026, 1, 1);
  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
  MoneyTransaction row(TransactionKind kind) => MoneyTransaction(
    id: 't1',
    idempotencyKey: 'k',
    personId: 'p1',
    amount: const Money.egp(40000),
    direction: TransactionDirection.received,
    kind: kind,
    date: now,
    createdAt: now,
  );

  setUp(() {
    getIt.registerFactory<TransactionFormCubit>(
      () => TransactionFormCubit(
        _MockPeopleRepository(),
        _MockCreatePerson(),
        _MockAddTransaction(),
        _MockEditTransaction(),
        getPrimaryCurrencyReturning(),
        findPossibleDuplicateReturning(),
      ),
    );
  });
  tearDown(() => getIt.reset());

  const locales = ['en', 'ar'];
  const themes = {'light': Brightness.light, 'dark': Brightness.dark};

  Future<AppLocalizations> pump(
    WidgetTester tester,
    MoneyTransaction transaction,
    String locale,
    Brightness brightness,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TransactionFormPage(
          editingTransaction: transaction,
          editingPerson: ahmed,
        ),
      ),
    );
    await tester.pump();
    return AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
  }

  for (final locale in locales) {
    for (final MapEntry(key: themeName, value: brightness) in themes.entries) {
      group('$locale · $themeName', () {
        testWidgets('a repayment has no enabled direction control, shows '
            'the direction and the locked hint', (tester) async {
          final l10n = await pump(
            tester,
            row(TransactionKind.repayment),
            locale,
            brightness,
          );

          final controls = tester
              .widgetList<SegmentedButton<TransactionDirection>>(
                find.byType(SegmentedButton<TransactionDirection>),
              )
              .where((c) => c.onSelectionChanged != null);
          expect(controls, isEmpty);
          expect(find.text(l10n.directionReceived), findsOneWidget);
          expect(find.text(l10n.repaymentDirectionLockedHint), findsOneWidget);
          expect(
            tester
                .getSemantics(find.text(l10n.repaymentDirectionLockedHint))
                .label,
            contains(l10n.repaymentDirectionLockedHint),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('an initial exchange keeps the direction control '
            'enabled', (tester) async {
          final l10n = await pump(
            tester,
            row(TransactionKind.initialExchange),
            locale,
            brightness,
          );

          final control = tester.widget<SegmentedButton<TransactionDirection>>(
            find.byType(SegmentedButton<TransactionDirection>),
          );
          expect(control.onSelectionChanged, isNotNull);
          expect(find.text(l10n.repaymentDirectionLockedHint), findsNothing);
        });
      });
    }
  }

  test('the cubit ignores direction changes while editing a repayment', () {
    final cubit = TransactionFormCubit(
      _MockPeopleRepository(),
      _MockCreatePerson(),
      _MockAddTransaction(),
      _MockEditTransaction(),
      getPrimaryCurrencyReturning(),
      findPossibleDuplicateReturning(),
    )..loadForEdit(row(TransactionKind.repayment), ahmed);

    cubit.directionChanged(TransactionDirection.given);

    expect(cubit.state.direction, TransactionDirection.received);
    cubit.close();
  });
}
