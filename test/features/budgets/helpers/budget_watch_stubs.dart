import 'package:daftary/core/database/watch_tables.dart';
import 'package:daftary/features/budgets/domain/repositories/budgets_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/watch_stubs.dart';

/// 021: answers `watchBudgetForMonth`/`watchBudgetTrend` by re-running the
/// test's `getBudgetForMonth`/`getBudgetTrend` stubs — once on listen, then
/// on every [FakeTableChanges.notify], exactly like the real `watchEither`.
void stubBudgetsWatches(
  BudgetsRepository repository,
  FakeTableChanges changes,
) {
  when(() => repository.watchBudgetForMonth(any())).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getBudgetForMonth(
        invocation.positionalArguments.first as String,
      ),
    ),
  );
  when(
    () => repository.watchBudgetTrend(
      categoryId: any(named: 'categoryId'),
      monthsBack: any(named: 'monthsBack'),
      endMonth: any(named: 'endMonth'),
    ),
  ).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getBudgetTrend(
        categoryId: invocation.namedArguments[#categoryId] as String?,
        monthsBack: invocation.namedArguments[#monthsBack] as int,
        endMonth: invocation.namedArguments[#endMonth] as String?,
      ),
    ),
  );
}
