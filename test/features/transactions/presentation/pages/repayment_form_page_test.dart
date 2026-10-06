import 'dart:async';

import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/conversion_context.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/presentation/cubit/repayment_form_cubit.dart';
import 'package:daftary/features/transactions/presentation/pages/repayment_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/currency_test_doubles.dart';
import '../../helpers/repayment_form_test_doubles.dart';

/// 022 A2 (CHK026, CHK028, CHK168): the repayment form shows what is
/// outstanding, previews the result and asks before reversing the balance.
void main() {
  late MockRecordRepayment record;
  final now = DateTime(2026, 1, 1);
  final saved = MoneyTransaction(
    id: 't1',
    idempotencyKey: 'k',
    personId: 'p1',
    amount: const Money.egp(1),
    direction: TransactionDirection.received,
    kind: TransactionKind.repayment,
    date: now,
    createdAt: now,
  );
  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(const Money.egp(0));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    record = MockRecordRepayment();
    when(
      () => record(
        idempotencyKey: any(named: 'idempotencyKey'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Right(saved));
  });
  tearDown(() => getIt.reset());

  void register({
    required int balanceMinor,
    List<ExchangeRate> rates = const [],
  }) {
    getIt.registerFactoryParam<RepaymentFormCubit, String, void>(
      (personId, _) => repaymentCubitWith(
        recordRepayment: record,
        personId: personId,
        balance: Stream<Either<Failure, PersonBalance>>.value(
          Right(PersonBalance(personId: 'p1', net: Money.egp(balanceMinor))),
        ),
        context: Stream<Either<Failure, ConversionContext>>.value(
          Right(ConversionContext(primary: Currency.egp, rates: rates)),
        ),
        person: Stream<Either<Failure, Person>>.value(Right(ahmed)),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, {String locale = 'en'}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RepaymentFormPage(personId: 'p1'),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> enterAmount(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump();
  }

  void expectRecordCalls(int times) {
    Future<Object?> call() => record(
      idempotencyKey: any(named: 'idempotencyKey'),
      personId: any(named: 'personId'),
      amount: any(named: 'amount'),
      date: any(named: 'date'),
      note: any(named: 'note'),
    );
    if (times == 0) {
      verifyNever(call);
    } else {
      verify(call).called(times);
    }
  }

  testWidgets('shows the outstanding amount', (tester) async {
    register(balanceMinor: 100000);
    await pump(tester);

    expect(find.textContaining('Remaining:'), findsOneWidget);
    expect(find.textContaining('1,000.00'), findsOneWidget);
  });

  testWidgets('400 against 1,000 previews 600 and saves without a dialog', (
    tester,
  ) async {
    register(balanceMinor: 100000);
    await pump(tester);

    await enterAmount(tester, '400');
    expect(find.textContaining('Ahmed owes you 600.00'), findsOneWidget);
    await save(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expectRecordCalls(1);
  });

  testWidgets('1,500 against 1,000 asks first: cancel saves nothing, '
      'confirm saves once', (tester) async {
    register(balanceMinor: 100000);
    await pump(tester);
    await enterAmount(tester, '1500');

    await save(tester);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('You will owe Ahmed 500.00 EGP'), findsOneWidget);

    // Buttons: >= 48dp and labelled for screen readers.
    for (final label in ['Cancel', 'Save']) {
      final button = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(tester.getSemantics(button).label, contains(label));
    }

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();
    expectRecordCalls(0);

    await save(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Save'),
      ),
    );
    await tester.pump();
    await tester.pump();
    expectRecordCalls(1);
  });

  testWidgets('you owe them 1,000 and overpay 1,500: they will owe you 500', (
    tester,
  ) async {
    register(balanceMinor: -100000);
    await pump(tester);
    await enterAmount(tester, '1500');

    await save(tester);
    await tester.pumpAndSettle();

    expect(find.text('Ahmed will owe you 500.00 EGP'), findsOneWidget);
    expectRecordCalls(0);
  });

  testWidgets('Save is disabled until the balance has loaded', (tester) async {
    getIt.registerFactoryParam<RepaymentFormCubit, String, void>(
      (personId, _) =>
          repaymentCubitWith(recordRepayment: record, personId: personId),
    );
    await pump(tester);
    await enterAmount(tester, '400');

    await tester.tap(find.text('Save'), warnIfMissed: false);
    await tester.pump();

    expectRecordCalls(0);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('USD at 48.50 against 10,000.00 EGP previews 5,150.00', (
    tester,
  ) async {
    register(
      balanceMinor: 1000000,
      rates: [rate(Currency.usd, Currency.egp, 48.5)],
    );
    await pump(tester);
    final cubit = BlocProvider.of<RepaymentFormCubit>(
      tester.element(find.byType(TextField).first),
    );

    cubit.currencyChanged(Currency.usd);
    cubit.amountChanged('100');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('5,150.00'), findsOneWidget);
  });

  testWidgets('GBP with no rate shows no number', (tester) async {
    register(balanceMinor: 1000000);
    await pump(tester);
    final cubit = BlocProvider.of<RepaymentFormCubit>(
      tester.element(find.byType(TextField).first),
    );

    cubit.currencyChanged(Currency.gbp);
    cubit.amountChanged('50');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.textContaining('Unavailable until an exchange rate is set'),
      findsOneWidget,
    );
    expect(find.textContaining('owes you'), findsNothing);
  });

  testWidgets('Arabic renders right-to-left without overflow', (tester) async {
    register(balanceMinor: 100000);
    await pump(tester, locale: 'ar');
    await enterAmount(tester, '400');

    expect(find.textContaining('المتبقي'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(TextField).first)),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
