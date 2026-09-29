import 'package:daftary/core/database/watch_tables.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/goal_progress.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_detail.dart';
import 'package:daftary/features/savings/domain/entities/savings_overview.dart';
import 'package:daftary/features/savings/domain/repositories/savings_repository.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/watch_stubs.dart';

class MockSavingsRepository extends Mock implements SavingsRepository {}

/// 021: answers `watchGoalDetail` by re-running the test's `getGoalDetail`
/// stub — once on listen, then on every [FakeTableChanges.notify], exactly
/// like the real `watchEither`.
void stubSavingsWatches(
  SavingsRepository repository,
  FakeTableChanges changes,
) {
  when(() => repository.watchGoalDetail(any())).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getGoalDetail(
        invocation.positionalArguments.first as String,
      ),
    ),
  );
  when(
    () => repository.watchSavingsOverview(
      includeArchived: any(named: 'includeArchived'),
    ),
  ).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getSavingsOverview(
        includeArchived:
            invocation.namedArguments[#includeArchived] as bool? ?? false,
      ),
    ),
  );
}

final DateTime testToday = DateTime(2026, 9, 15, 10);

SavingsGoal testGoal({
  String id = 'g1',
  String name = 'Emergency Fund',
  String? type,
  Currency currency = Currency.egp,
  int target = 10000000,
  int? monthly,
  DateTime? targetDate,
  bool isArchived = false,
}) => SavingsGoal(
  id: id,
  idempotencyKey: 'k-$id',
  name: name,
  type: type,
  currency: currency,
  targetAmountMinorUnits: target,
  monthlyContributionMinorUnits: monthly,
  targetDate: targetDate,
  isArchived: isArchived,
  createdAt: testToday,
  updatedAt: testToday,
);

SavingsContribution testEntry({
  String id = 'c1',
  String goalId = 'g1',
  ContributionType type = ContributionType.contribution,
  int amount = 100000,
  int? entered,
  Currency enteredCurrency = Currency.egp,
  DateTime? date,
  String? note,
  DateTime? editedAt,
}) => SavingsContribution(
  id: id,
  idempotencyKey: 'k-$id',
  goalId: goalId,
  type: type,
  amountMinorUnits: amount,
  enteredAmountMinorUnits: entered ?? amount,
  enteredCurrency: enteredCurrency,
  date: date ?? DateTime(2026, 9, 1),
  note: note,
  createdAt: testToday,
  editedAt: editedAt,
);

/// A detail whose progress comes from the real calculator, so a test can
/// never hand the UI figures the app itself would not produce.
SavingsGoalDetail testDetail(
  SavingsGoal goal, {
  List<SavingsContribution> history = const [],
}) {
  final current = history.fold<int>(
    0,
    (sum, e) => sum + e.signedAmountMinorUnits,
  );
  final GoalProgress progress = const DefaultSavingsCalculator().progressFor(
    goal,
    currentAmountMinorUnits: current,
    asOf: testToday,
  );
  return SavingsGoalDetail(goal: goal, progress: progress, history: history);
}

/// One overview line for [goal] with [saved] in its own currency. With
/// [converted] `null` (and [missing] set) the line is blocked, as when a
/// rate is missing (FR-019).
GoalOverviewLine testOverviewLine(
  SavingsGoal goal, {
  int saved = 0,
  int? converted,
  List<Currency> missing = const [],
}) => GoalOverviewLine(
  goal: goal,
  progress: const DefaultSavingsCalculator().progressFor(
    goal,
    currentAmountMinorUnits: saved,
    asOf: testToday,
  ),
  primaryCurrencyAmountMinorUnits: missing.isEmpty
      ? (converted ?? saved)
      : null,
  missingRatesFor: missing,
);
