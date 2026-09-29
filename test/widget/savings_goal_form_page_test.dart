import 'package:daftary/core/design_system/currency_picker.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:daftary/features/savings/domain/usecases/create_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/edit_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:daftary/features/savings/presentation/cubit/goal_form_cubit.dart';
import 'package:daftary/features/savings/presentation/pages/goal_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../features/savings/helpers/savings_harness.dart';
import '../features/savings/helpers/savings_test_data.dart';
import '../features/transactions/helpers/currency_test_doubles.dart';

class MockCreateSavingsGoal extends Mock implements CreateSavingsGoal {}

class MockEditSavingsGoal extends Mock implements EditSavingsGoal {}

class MockGetGoalDetail extends Mock implements GetGoalDetail {}

/// T021 — `GoalFormPage`: the live estimate preview, validation messages,
/// the currency picker on create only, and the US1 AS-6 "set a plan to see
/// an estimate" prompt.
void main() {
  late GoalFormCubit cubit;
  late MockGetGoalDetail getDetail;
  final en = lookupAppLocalizations(const Locale('en'));

  setUp(() {
    getDetail = MockGetGoalDetail();
    cubit = GoalFormCubit(
      MockCreateSavingsGoal(),
      MockEditSavingsGoal(),
      getDetail,
      getPrimaryCurrencyReturning(),
      const DefaultSavingsCalculator(),
      SettableClock(testToday),
    );
  });

  tearDown(() => cubit.close());

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view
      ..physicalSize = const Size(900, 2600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(value: cubit, child: const GoalFormView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(TextField),
      ),
      text,
    );
    await tester.pump();
  }

  testWidgets('the live preview updates as the plan is typed (US1 AS-1/2)', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('savingsGoalPreview')), findsNothing);

    await enter(tester, 'savingsGoalTargetField', '100000');
    await enter(tester, 'savingsGoalMonthlyField', '5000');
    expect(find.byKey(const ValueKey('savingsGoalPreview')), findsOneWidget);
    expect(find.textContaining('20 months'), findsOneWidget);

    await enter(tester, 'savingsGoalStartingField', '35000');
    expect(find.textContaining('13 months'), findsOneWidget);
    expect(find.text('65,000.00 EGP'), findsOneWidget);
  });

  testWidgets('a target date alone previews the required monthly amount '
      '(US1 AS-4)', (tester) async {
    await pump(tester);
    await enter(tester, 'savingsGoalTargetField', '65000');
    cubit.targetDateChanged(DateTime(2027, 7, 15));
    await tester.pump();

    expect(find.byKey(const ValueKey('savingsRequiredLine')), findsOneWidget);
    expect(find.textContaining('6,500.00 EGP a month'), findsOneWidget);
  });

  testWidgets('with neither a monthly contribution nor a target date the '
      'preview prompts for one (US1 AS-6)', (tester) async {
    await pump(tester);
    await enter(tester, 'savingsGoalTargetField', '1000');

    expect(
      find.byKey(const ValueKey('savingsNoEstimatePrompt')),
      findsOneWidget,
    );
    expect(find.text(en.savingsNoEstimatePrompt), findsOneWidget);
  });

  testWidgets('submitting an invalid form shows each localized message', (
    tester,
  ) async {
    await pump(tester);
    await enter(tester, 'savingsGoalTargetField', '0');
    await enter(tester, 'savingsGoalMonthlyField', 'x');
    await tester.tap(find.byKey(const ValueKey('savingsGoalSubmit')));
    await tester.pump();

    expect(find.text(en.savingsGoalNameRequiredError), findsOneWidget);
    expect(find.text(en.savingsGoalTargetInvalidError), findsOneWidget);
    expect(find.text(en.savingsGoalMonthlyInvalidError), findsOneWidget);
  });

  testWidgets('the currency picker is shown on create', (tester) async {
    await pump(tester);
    expect(find.byKey(CurrencyPicker.fieldKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey('savingsGoalCurrencyFixed')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('savingsGoalStartingField')),
      findsOneWidget,
    );
  });

  testWidgets('on edit the currency picker and starting amount are hidden; '
      'the fixed currency is explained (FR-027)', (tester) async {
    when(() => getDetail('g1')).thenAnswer(
      (_) async => Right(
        testDetail(
          testGoal(currency: Currency.usd, target: 500000, monthly: 25000),
        ),
      ),
    );
    await cubit.loadForEdit('g1');
    await pump(tester);

    expect(find.byKey(CurrencyPicker.fieldKey), findsNothing);
    expect(
      find.byKey(const ValueKey('savingsGoalStartingField')),
      findsNothing,
    );
    expect(find.text(en.savingsGoalCurrencyFixedHint('USD')), findsOneWidget);
    expect(find.text(en.savingsGoalUpdateAction), findsOneWidget);
    // Prefilled from the goal.
    expect(find.text('Emergency Fund'), findsOneWidget);
    expect(find.text('5,000.00'), findsOneWidget);
  });

  testWidgets('renders in Arabic (RTL) without layout errors', (tester) async {
    await pump(tester, locale: const Locale('ar'));
    await enter(tester, 'savingsGoalTargetField', '100000');
    await enter(tester, 'savingsGoalMonthlyField', '5000');

    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(find.text(ar.savingsGoalFormCreateTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('savingsGoalPreview')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
