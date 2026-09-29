import 'package:daftary/core/design_system/currency_picker.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/l10n/failure_message.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/edit_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:daftary/features/savings/domain/usecases/log_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/log_withdrawal.dart';
import 'package:daftary/features/savings/presentation/cubit/contribution_form_cubit.dart';
import 'package:daftary/features/savings/presentation/pages/contribution_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../features/savings/helpers/savings_harness.dart';
import '../features/savings/helpers/savings_test_data.dart';

/// T036 — `ContributionFormPage`: the currency picker (defaulting to the
/// goal's), the conversion hint, the missing-rate message naming the rate,
/// the type toggle on new entries only, and the archived-goal block.
void main() {
  late MockSavingsRepository repository;
  late ContributionFormCubit cubit;
  final en = lookupAppLocalizations(const Locale('en'));

  setUpAll(() {
    registerFallbackValue(Money.egp(0));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockSavingsRepository();
    when(() => repository.getGoalDetail('g1')).thenAnswer(
      (_) async =>
          Right(testDetail(testGoal(), history: [testEntry(amount: 250000)])),
    );
    cubit = ContributionFormCubit(
      GetGoalDetail(repository),
      LogContribution(repository),
      LogWithdrawal(repository),
      EditContribution(repository),
      SettableClock(testToday),
    );
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(900, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const ContributionFormView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterAmount(WidgetTester tester, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('savingsEntryAmountField')),
        matching: find.byType(TextField),
      ),
      text,
    );
    await tester.pump();
  }

  testWidgets('a new entry offers the type toggle and a currency picker on '
      'the goal currency; no conversion hint', (tester) async {
    await cubit.initialize(goalId: 'g1');
    await pump(tester);

    expect(find.text(en.savingsContributionFormAddTitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('savingsEntryTypeToggle')),
      findsOneWidget,
    );
    expect(find.byKey(CurrencyPicker.fieldKey), findsOneWidget);
    expect(find.textContaining('(EGP)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('savingsEntryConversionHint')),
      findsNothing,
    );
  });

  testWidgets('another currency shows the conversion hint (FR-028)', (
    tester,
  ) async {
    await cubit.initialize(goalId: 'g1');
    cubit.currencyChanged(Currency.usd);
    await pump(tester);

    expect(
      find.text(en.savingsContributionConversionHint('EGP')),
      findsOneWidget,
    );
  });

  testWidgets('a missing rate is explained inline, naming the rate '
      '(US2 AS-9)', (tester) async {
    when(
      () => repository.logContribution(
        idempotencyKey: any(named: 'idempotencyKey'),
        goalId: any(named: 'goalId'),
        amount: any(named: 'amount'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Left(RatesMissingFailure(const [Currency.usd])));
    await cubit.initialize(goalId: 'g1');
    cubit.currencyChanged(Currency.usd);
    await pump(tester);

    await enterAmount(tester, '100');
    await tester.tap(find.byKey(const ValueKey('savingsEntrySubmit')));
    await tester.pumpAndSettle();

    final message = en.messageFor(RatesMissingFailure(const [Currency.usd]));
    expect(message, contains('USD'));
    expect(find.text(message), findsOneWidget);
  });

  testWidgets('the withdrawal form says how much is available', (tester) async {
    await cubit.initialize(goalId: 'g1', type: ContributionType.withdrawal);
    await pump(tester);

    expect(find.text(en.savingsContributionFormWithdrawTitle), findsOneWidget);
    expect(
      find.text(en.savingsWithdrawalAvailableHint('2,500.00 EGP')),
      findsOneWidget,
    );
  });

  testWidgets('an invalid amount is flagged', (tester) async {
    await cubit.initialize(goalId: 'g1');
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('savingsEntrySubmit')));
    await tester.pump();

    expect(find.text(en.savingsContributionAmountInvalidError), findsOneWidget);
  });

  testWidgets('editing hides the type toggle (the type is fixed)', (
    tester,
  ) async {
    await cubit.initialize(goalId: 'g1', contributionId: 'c1');
    await pump(tester);

    expect(find.text(en.savingsContributionFormEditTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('savingsEntryTypeToggle')), findsNothing);
    expect(find.text('2,500.00'), findsOneWidget);
  });

  testWidgets('a new entry on an archived goal is blocked with an '
      'explanation (FR-020)', (tester) async {
    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(testDetail(testGoal(isArchived: true))));
    await cubit.initialize(goalId: 'g1');
    await pump(tester);

    expect(find.text(en.savingsGoalArchivedNotice), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('savingsEntrySubmit')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
