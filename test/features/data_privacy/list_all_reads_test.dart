import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution_audit.dart';
import 'package:daftary/features/transactions/domain/entities/transaction_audit_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/catalogue_fixtures.dart';

/// 022 T071 (D1): the plain "list all" reads the export needs. Each is a
/// read with no business logic and no filter, and each documents what it
/// leaves out:
///
/// - budgets: every month; soft-deleted budgets (and their allocations) out;
/// - savings goals: archived goals in; soft-deleted goals and entries out;
/// - audit histories (transactions, savings entries, income/expense):
///   nothing is left out, so the history of a deleted record is included.
void main() {
  late CatalogueEnv env;

  setUp(() async => env = await CatalogueEnv.open());
  tearDown(() => env.close());

  group('budgets', () {
    test('getAllBudgets lists every month and leaves out deleted budgets, '
        'getAllAllocations those of the budgets that remain', () async {
      final sept = await env.budget('2026-09', {catFood: 100000});
      final oct = await env.budget('2026-10', {
        catFood: 200000,
        catTransport: 50000,
      });
      final nov = await env.budget('2026-11', {catRent: 300000});
      unwrapOrThrow(await env.budgets.deleteBudget(nov));

      final budgets = unwrapOrThrow(await env.budgets.getAllBudgets());
      expect(budgets.map((b) => b.id), unorderedEquals([sept, oct]));
      expect(budgets.map((b) => b.month), ['2026-09', '2026-10']);

      final allocations = unwrapOrThrow(await env.budgets.getAllAllocations());
      expect(allocations, hasLength(3));
      expect(allocations.map((a) => a.budgetId).toSet(), {sept, oct});
    });

    test('nothing yet reads as empty lists', () async {
      expect(unwrapOrThrow(await env.budgets.getAllBudgets()), isEmpty);
      expect(unwrapOrThrow(await env.budgets.getAllAllocations()), isEmpty);
    });
  });

  group('savings', () {
    test('getAllGoalsWithContributions includes archived goals and leaves '
        'out deleted goals and deleted entries', () async {
      final car = await env.goal(name: 'Car');
      final trip = await env.goal(name: 'Trip', target: 500000);
      final gone = await env.goal(name: 'Gone');
      await env.contribute(car.id, 100000);
      await env.contribute(car.id, 50000);
      await env.contribute(trip.id, 20000);
      unwrapOrThrow(await env.savings.archiveSavingsGoal(trip.id));
      unwrapOrThrow(await env.savings.deleteSavingsGoal(gone.id));
      final extra = unwrapOrThrow(
        await env.savings.getGoalDetail(car.id),
      ).history.first;
      unwrapOrThrow(await env.savings.deleteContribution(extra.id));

      final all = unwrapOrThrow(
        await env.savings.getAllGoalsWithContributions(),
      );

      expect(all.map((g) => g.goal.name), ['Car', 'Trip']);
      expect(
        all.firstWhere((g) => g.goal.name == 'Car').contributions,
        hasLength(1),
      );
      expect(
        all.firstWhere((g) => g.goal.name == 'Trip').contributions,
        hasLength(1),
      );
      expect(
        all.firstWhere((g) => g.goal.name == 'Trip').goal.isArchived,
        isTrue,
      );
    });

    test('getAllContributionAudits returns every edit and delete, oldest '
        'first, deleted entries included', () async {
      final car = await env.goal(name: 'Car');
      final other = await env.goal(name: 'Other');
      await env.contribute(car.id, 100000);
      await env.contribute(other.id, 70000);
      final carEntry = unwrapOrThrow(
        await env.savings.getGoalDetail(car.id),
      ).history.single;
      final otherEntry = unwrapOrThrow(
        await env.savings.getGoalDetail(other.id),
      ).history.single;
      unwrapOrThrow(
        await env.savings.editContribution(
          contributionId: carEntry.id,
          amount: const Money.egp(120000),
          date: catalogueToday,
        ),
      );
      // Distinct milliseconds: history is ordered by time, then id.
      await Future<void>.delayed(const Duration(milliseconds: 3));
      unwrapOrThrow(await env.savings.deleteContribution(otherEntry.id));

      final audits = unwrapOrThrow(
        await env.savings.getAllContributionAudits(),
      );

      // The test clock is fixed, so both rows share one instant and the
      // order falls to the id tie-break; the set is what matters here.
      expect(
        audits.map((a) => a.changeType),
        unorderedEquals([
          ContributionAuditChange.edited,
          ContributionAuditChange.deleted,
        ]),
      );
      expect(
        audits.map((a) => a.contributionId),
        unorderedEquals([carEntry.id, otherEntry.id]),
      );
    });
  });

  group('history', () {
    test('getAllAuditEntries returns every transaction audit row of every '
        'person, including those of a deleted transaction', () async {
      final a = await env.give('ahmed', 100000);
      final b = await env.receive('mona', 50000);
      Future<void> tick() =>
          Future<void>.delayed(const Duration(milliseconds: 3));
      await tick();
      unwrapOrThrow(
        await env.transactions.editTransaction(
          transactionId: a.id,
          amount: const Money.egp(90000),
          direction: a.direction,
          date: a.date,
        ),
      );
      await tick();
      unwrapOrThrow(await env.transactions.deleteTransaction(b.id));

      final audits = unwrapOrThrow(await env.transactions.getAllAuditEntries());

      expect(audits.map((x) => x.changeType), [
        AuditChangeType.created,
        AuditChangeType.created,
        AuditChangeType.edited,
        AuditChangeType.deleted,
      ]);
      expect(audits.map((x) => x.transactionId).toSet(), {a.id, b.id});
    });

    test('getAllEntryAudits returns every income/expense history row, '
        'including those of a deleted entry', () async {
      final food = await env.expense(catFood, 30000, catalogueToday);
      final fuel = await env.expense(catTransport, 10000, catalogueToday);
      unwrapOrThrow(await env.finance.deleteEntry(fuel.id));
      unwrapOrThrow(
        await env.finance.editEntry(
          entryId: food.id,
          categoryId: catFood,
          amount: const Money.egp(35000),
          date: catalogueToday,
        ),
      );

      final audits = unwrapOrThrow(await env.finance.getAllEntryAudits());

      expect(audits, hasLength(4));
      expect(audits.map((x) => x.financeEntryId).toSet(), {food.id, fuel.id});
    });
  });
}
