import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_detail.dart';
import 'package:daftary/features/savings/domain/usecases/archive_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/delete_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/delete_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/restore_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/watch_goal_detail.dart';
import 'package:daftary/features/savings/presentation/cubit/goal_detail_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/savings_goal_actions_cubit.dart';
import 'package:daftary/features/savings/presentation/pages/goal_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../features/savings/helpers/savings_test_data.dart';
import '../helpers/watch_stubs.dart';

/// US4 on the goal page: its options menu archives, restores and deletes
/// the goal (FR-020/FR-021), with the same delete-blocked → archive offer
/// as the overview.
void main() {
  late MockSavingsRepository repository;
  late FakeTableChanges changes;
  late GoalDetailCubit detailCubit;
  late SavingsGoalActionsCubit actions;
  final en = lookupAppLocalizations(const Locale('en'));

  setUp(() {
    repository = MockSavingsRepository();
    changes = FakeTableChanges();
    stubSavingsWatches(repository, changes);
    detailCubit = GoalDetailCubit(
      WatchGoalDetail(repository),
      DeleteContribution(repository),
    );
    actions = SavingsGoalActionsCubit(
      ArchiveSavingsGoal(repository),
      RestoreSavingsGoal(repository),
      DeleteSavingsGoal(repository),
    );
  });

  tearDown(() async {
    await detailCubit.close();
    await actions.close();
    await changes.close();
  });

  Future<void> pump(WidgetTester tester, SavingsGoalDetail detail) async {
    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(detail));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: detailCubit..subscribe('g1')),
            BlocProvider.value(value: actions),
          ],
          child: const GoalDetailView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('savingsGoalMenu-g1')));
    await tester.pumpAndSettle();
  }

  testWidgets('an active goal offers archive and delete; delete blocked by '
      'history offers archiving instead', (tester) async {
    when(
      () => repository.deleteSavingsGoal('g1'),
    ).thenAnswer((_) async => const Left(GoalHasHistoryFailure('history')));
    when(
      () => repository.archiveSavingsGoal('g1'),
    ).thenAnswer((_) async => const Right(unit));
    await pump(tester, testDetail(testGoal(), history: [testEntry()]));

    await openMenu(tester);
    expect(find.text(en.savingsArchiveAction), findsOneWidget);
    expect(find.text(en.savingsArchiveRestoreAction), findsNothing);
    await tester.tap(find.text(en.savingsDeleteAction));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.savingsDeleteAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.savingsDeleteBlockedArchiveAction));
    await tester.pumpAndSettle();

    verify(() => repository.archiveSavingsGoal('g1')).called(1);
  });

  testWidgets('an archived goal keeps its notice and offers restore', (
    tester,
  ) async {
    when(
      () => repository.restoreSavingsGoal('g1'),
    ).thenAnswer((_) async => const Right(unit));
    await pump(tester, testDetail(testGoal(isArchived: true)));

    expect(find.byKey(const ValueKey('savingsArchivedNotice')), findsOneWidget);
    expect(find.byKey(const ValueKey('savingsLogContribution')), findsNothing);
    await openMenu(tester);
    await tester.tap(find.text(en.savingsArchiveRestoreAction));
    await tester.pumpAndSettle();

    verify(() => repository.restoreSavingsGoal('g1')).called(1);
    expect(find.text(en.savingsArchiveRestoredMessage), findsOneWidget);
  });
}
