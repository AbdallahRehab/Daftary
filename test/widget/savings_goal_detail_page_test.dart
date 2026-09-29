import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_detail.dart';
import 'package:daftary/features/savings/domain/usecases/delete_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/watch_goal_detail.dart';
import 'package:daftary/features/savings/presentation/cubit/goal_detail_cubit.dart';
import 'package:daftary/features/savings/presentation/pages/goal_detail_page.dart';
import 'package:daftary/features/savings/presentation/widgets/achieved_goal_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../features/savings/helpers/savings_test_data.dart';
import '../helpers/watch_stubs.dart';

/// T036 — `GoalDetailPage`: the achieved state is celebratory (not the
/// warning vocabulary), FR-012's shortfall line, the no-estimate prompt,
/// history rows showing entered and converted amounts, and the archived
/// state.
void main() {
  late MockSavingsRepository repository;
  late FakeTableChanges changes;
  late GoalDetailCubit cubit;
  final en = lookupAppLocalizations(const Locale('en'));

  setUp(() {
    repository = MockSavingsRepository();
    changes = FakeTableChanges();
    stubSavingsWatches(repository, changes);
    cubit = GoalDetailCubit(
      WatchGoalDetail(repository),
      DeleteContribution(repository),
    );
  });

  tearDown(() async {
    await cubit.close();
    await changes.close();
  });

  Future<void> pump(
    WidgetTester tester,
    SavingsGoalDetail detail, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    tester.view
      ..physicalSize = const Size(900, 2600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(detail));
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit..subscribe('g1'),
          child: const GoalDetailView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an achieved goal shows the celebratory badge in success '
      'colours, never warning vocabulary (FR-017)', (tester) async {
    final goal = testGoal(target: 100000, monthly: 10000);
    await pump(tester, testDetail(goal, history: [testEntry(amount: 120000)]));

    expect(find.byType(AchievedGoalBadge), findsOneWidget);
    expect(find.text(en.savingsGoalAchievedBadge), findsOneWidget);
    expect(find.textContaining('100% saved'), findsOneWidget);
    // Nothing reads as a problem: no over/exceeded/warning wording, and the
    // badge is painted in the success role.
    expect(
      find.textContaining(RegExp('over|exceed|warning', caseSensitive: false)),
      findsNothing,
    );
    final context = tester.element(find.byType(AchievedGoalBadge));
    final box = tester.widget<Container>(
      find.byKey(const ValueKey('savingsAchievedBadge')),
    );
    expect(
      (box.decoration! as BoxDecoration).color,
      context.financeColors.successSurface,
    );
    // No estimate once achieved.
    expect(find.byKey(const ValueKey('savingsEstimateLine')), findsNothing);
  });

  testWidgets('FR-012: a contribution too low for the target date shows '
      'both figures and the shortfall in months', (tester) async {
    final goal = testGoal(
      target: 1000000,
      monthly: 50000,
      targetDate: DateTime(2027, 7, 15),
    );
    await pump(tester, testDetail(goal));

    expect(find.byKey(const ValueKey('savingsEstimateLine')), findsOneWidget);
    expect(find.byKey(const ValueKey('savingsRequiredLine')), findsOneWidget);
    expect(find.text(en.savingsEstimateShortfall('10 months')), findsOneWidget);
  });

  testWidgets('a goal with no plan prompts to set one (US1 AS-6)', (
    tester,
  ) async {
    await pump(tester, testDetail(testGoal()));

    expect(find.text(en.savingsNoEstimatePrompt), findsOneWidget);
    expect(find.text(en.savingsGoalHistoryEmptyTitle), findsOneWidget);
  });

  testWidgets('history rows show type, entered amount and, when converted, '
      'the counted amount (FR-008/FR-028)', (tester) async {
    final goal = testGoal(target: 10000000);
    await pump(
      tester,
      testDetail(
        goal,
        history: [
          testEntry(
            id: 's',
            amount: 3500000,
            note: SavingsContribution.startingAmountNote,
          ),
          testEntry(
            id: 'u',
            amount: 483500,
            entered: 10000,
            enteredCurrency: Currency.usd,
          ),
          testEntry(
            id: 'w',
            type: ContributionType.withdrawal,
            amount: 300000,
            note: 'Car repair',
            editedAt: testToday,
          ),
        ],
      ),
    );

    expect(find.text('+35,000.00 EGP'), findsOneWidget);
    expect(find.textContaining(en.savingsEntryStartingAmount), findsOneWidget);
    expect(find.text('+100.00 USD'), findsOneWidget);
    expect(
      find.text(en.savingsEntryConvertedAmount('4,835.00 EGP')),
      findsOneWidget,
    );
    expect(find.text('−3,000.00 EGP'), findsOneWidget);
    expect(find.text(en.savingsEntryWithdrawal), findsOneWidget);
    expect(find.text(en.savingsEntryContribution), findsNWidgets(2));
    expect(find.textContaining('Car repair'), findsOneWidget);
    expect(find.textContaining(en.savingsEntryEditedLabel), findsOneWidget);
    // Only a converted row carries the "counted as" line.
    expect(find.textContaining('Counted as'), findsOneWidget);
  });

  testWidgets('the log actions are offered on an active goal', (tester) async {
    await pump(tester, testDetail(testGoal()));

    expect(
      find.byKey(const ValueKey('savingsLogContribution')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('savingsLogWithdrawal')), findsOneWidget);
    expect(find.byKey(const ValueKey('savingsArchivedNotice')), findsNothing);
  });

  testWidgets('an archived goal hides the log actions and explains why '
      '(FR-020)', (tester) async {
    await pump(tester, testDetail(testGoal(isArchived: true)));

    expect(find.byKey(const ValueKey('savingsLogContribution')), findsNothing);
    expect(find.byKey(const ValueKey('savingsLogWithdrawal')), findsNothing);
    expect(find.text(en.savingsGoalArchivedNotice), findsOneWidget);
  });

  testWidgets('deleting an entry asks first, then deletes it', (tester) async {
    when(
      () => repository.deleteContribution('c1'),
    ).thenAnswer((_) async => const Right(unit));
    await pump(tester, testDetail(testGoal(), history: [testEntry()]));

    await tester.tap(find.byTooltip(en.savingsEntryActionsTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.savingsEntryDeleteAction).last);
    await tester.pumpAndSettle();
    expect(find.text(en.savingsEntryDeleteConfirmTitle), findsOneWidget);
    verifyNever(() => repository.deleteContribution(any()));

    await tester.tap(find.text(en.savingsEntryDeleteAction).last);
    await tester.pumpAndSettle();
    verify(() => repository.deleteContribution('c1')).called(1);
  });

  testWidgets('renders in Arabic and dark mode without layout errors', (
    tester,
  ) async {
    final goal = testGoal(
      target: 1000000,
      monthly: 50000,
      targetDate: DateTime(2027, 7, 15),
    );
    await pump(
      tester,
      testDetail(goal, history: [testEntry()]),
      locale: const Locale('ar'),
      theme: buildDarkTheme(),
    );

    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(find.text(ar.savingsGoalHistoryHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
