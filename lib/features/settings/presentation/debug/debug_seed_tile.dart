import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Either;

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../budgets/domain/entities/budget.dart';
import '../../../budgets/domain/entities/budget_failures.dart';
import '../../../budgets/domain/entities/budget_month.dart';
import '../../../budgets/domain/repositories/budgets_repository.dart';
import '../../../finance/domain/entities/category.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/repositories/category_repository.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../../occasions/domain/entities/occasion_type.dart';
import '../../../occasions/domain/repositories/occasions_repository.dart';
import '../../../people/domain/entities/people_failures.dart';
import '../../../people/domain/entities/person.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/repositories/transactions_repository.dart';

/// Debug builds only: a Settings tile that fills the app with realistic
/// data through the real repositories, so every record goes through the
/// DAO + outbox path and syncs to Supabase like a user-entered one.
///
/// Idempotency keys are fixed, so tapping it twice adds nothing new.
class DebugSeedTile extends StatefulWidget {
  const DebugSeedTile({super.key});

  @override
  State<DebugSeedTile> createState() => _DebugSeedTileState();
}

class _DebugSeedTileState extends State<DebugSeedTile> {
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final report = await DebugSeeder().seed();
      messenger.showSnackBar(SnackBar(content: Text(report)));
    } catch (e, st) {
      debugPrint('DebugSeeder failed: $e\n$st');
      messenger.showSnackBar(SnackBar(content: Text('Seed failed: $e')));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.science_outlined),
      title: const Text('Seed test data (debug)'),
      subtitle: const Text('People, transactions, occasion, finance, budget'),
      trailing: _running
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow),
      onTap: _running ? null : _run,
    );
  }
}

class DebugSeeder {
  final _people = getIt<PeopleRepository>();
  final _transactions = getIt<TransactionsRepository>();
  final _occasions = getIt<OccasionsRepository>();
  final _categories = getIt<CategoryRepository>();
  final _finance = getIt<FinanceRepository>();
  final _budgets = getIt<BudgetsRepository>();

  static const _k = 'debug-seed-v1';

  final _log = <String>[];

  Future<String> seed() async {
    final now = DateTime.now();
    DateTime daysAgo(int d) => now.subtract(Duration(days: d));

    // People.
    final ahmed = await _person('أحمد مصطفى', '01001234567', 'friend');
    final mona = await _person('منى عبد الرحمن', '01112345678', 'family');
    final karim = await _person('كريم حسن', '01223456789', 'colleague');
    final yasmin = await _person('ياسمين فاروق', null, 'neighbor');
    final omar = await _person('عمر الشريف', '01098765432', 'friend');

    // Transactions (loans given / received, plus repayments).
    await _tx(
      'ahmed-1',
      ahmed,
      150000,
      TransactionDirection.given,
      daysAgo(40),
      'سلفة إيجار',
    );
    await _tx(
      'ahmed-2',
      ahmed,
      50000,
      TransactionDirection.given,
      daysAgo(20),
      'مصاريف عربية',
    );
    await _repay('ahmed-r1', ahmed, 80000, daysAgo(5), 'رجّع جزء');
    await _tx(
      'mona-1',
      mona,
      200000,
      TransactionDirection.received,
      daysAgo(30),
      'استلفت منها للجمعية',
    );
    await _tx(
      'karim-1',
      karim,
      7500,
      TransactionDirection.given,
      daysAgo(12),
      'غدا الشغل',
    );
    await _tx(
      'karim-2',
      karim,
      10000,
      TransactionDirection.received,
      daysAgo(3),
      null,
      currency: Currency.usd,
    );
    await _tx(
      'yasmin-1',
      yasmin,
      30000,
      TransactionDirection.given,
      daysAgo(8),
      'فاتورة كهربا',
    );
    await _repay('yasmin-r1', yasmin, 30000, daysAgo(1), 'سددت كله');

    // Occasion with contributions.
    final wedding = await _run(
      'occasion',
      _occasions.createOccasion(
        idempotencyKey: '$_k-occ-wedding',
        name: 'فرح أحمد',
        date: daysAgo(15),
        type: OccasionType.wedding,
        notes: 'قاعة الماسة',
      ),
    );
    if (wedding != null) {
      await _contribution(
        'occ-omar',
        wedding.id,
        omar,
        100000,
        TransactionDirection.given,
        daysAgo(15),
      );
      await _contribution(
        'occ-karim',
        wedding.id,
        karim,
        50000,
        TransactionDirection.given,
        daysAgo(15),
      );
      await _contribution(
        'occ-mona',
        wedding.id,
        mona,
        75000,
        TransactionDirection.received,
        daysAgo(14),
      );
    }

    // Finance entries on the seeded categories.
    final income = await _categoryList(FinanceEntryType.income);
    final expense = await _categoryList(FinanceEntryType.expense);
    if (income.isNotEmpty) {
      await _entry(
        'salary',
        income.first,
        FinanceEntryType.income,
        2500000,
        DateTime(now.year, now.month, 1),
        'مرتب الشهر',
      );
      if (income.length > 1) {
        await _entry(
          'freelance',
          income[1],
          FinanceEntryType.income,
          600000,
          daysAgo(6),
          'مشروع فري لانس',
        );
      }
    }
    final expenseAmounts = [185000, 42000, 95000, 30000, 120000, 64000];
    for (var i = 0; i < expense.length && i < expenseAmounts.length; i++) {
      await _entry(
        'exp-$i',
        expense[i],
        FinanceEntryType.expense,
        expenseAmounts[i],
        daysAgo(i * 3 + 1),
        null,
      );
    }

    // Budget for the current month.
    final month = BudgetMonth.current();
    final budget = await _budget(month, 2500000);
    if (budget != null) {
      final planned = [300000, 150000, 200000];
      for (var i = 0; i < expense.length && i < planned.length; i++) {
        await _run(
          'allocation',
          _budgets.addBudgetCategoryAllocation(
            idempotencyKey: '$_k-alloc-$month-$i',
            budgetId: budget.id,
            categoryId: expense[i].id,
            plannedAmountMinorUnits: planned[i],
          ),
          ignore: (f) => f is DuplicateBudgetAllocationFailure,
        );
      }
    }

    final summary = _log.isEmpty
        ? 'Seed done — sync will upload it'
        : 'Seed done with ${_log.length} issue(s): ${_log.first}';
    debugPrint('DebugSeeder: $summary\n${_log.join('\n')}');
    return summary;
  }

  Future<T?> _run<T>(
    String label,
    Future<Either<Failure, T>> call, {
    bool Function(Failure)? ignore,
  }) async {
    final result = await call;
    return result.fold((f) {
      if (ignore == null || !ignore(f)) _log.add('$label: ${f.message}');
      return null;
    }, (v) => v);
  }

  Future<Person?> _person(String name, String? phone, String tag) async {
    final result = await _people.createPerson(
      name: name,
      phoneNumber: phone,
      relationshipTag: tag,
    );
    return result.fold((f) async {
      if (f is PossibleDuplicateFailure) {
        for (final p in f.matches) {
          if (p.name == name) return p;
        }
        return _run(
          'person $name',
          _people.confirmCreateDespiteDuplicate(
            name: name,
            phoneNumber: phone,
            relationshipTag: tag,
          ),
        );
      }
      _log.add('person $name: ${f.message}');
      return null;
    }, (p) async => p);
  }

  Future<void> _tx(
    String key,
    Person? person,
    int minor,
    TransactionDirection direction,
    DateTime date,
    String? note, {
    Currency currency = Currency.egp,
  }) async {
    if (person == null) return;
    await _run(
      'tx $key',
      _transactions.addTransaction(
        idempotencyKey: '$_k-tx-$key',
        personId: person.id,
        amount: Money.fromMinorUnits(minor, currency),
        direction: direction,
        date: date,
        note: note,
      ),
    );
  }

  Future<void> _repay(
    String key,
    Person? person,
    int minor,
    DateTime date,
    String? note,
  ) async {
    if (person == null) return;
    await _run(
      'repay $key',
      _transactions.recordRepayment(
        idempotencyKey: '$_k-tx-$key',
        personId: person.id,
        amount: Money.egp(minor),
        date: date,
        note: note,
      ),
    );
  }

  Future<void> _contribution(
    String key,
    String occasionId,
    Person? person,
    int minor,
    TransactionDirection direction,
    DateTime date,
  ) async {
    if (person == null) return;
    await _run(
      'contribution $key',
      _occasions.addParticipantContribution(
        idempotencyKey: '$_k-$key',
        occasionId: occasionId,
        personId: person.id,
        amount: Money.egp(minor),
        direction: direction,
        date: date,
      ),
    );
  }

  Future<List<Category>> _categoryList(FinanceEntryType type) async =>
      await _run('categories', _categories.getCategories(type: type)) ??
      const [];

  Future<void> _entry(
    String key,
    Category category,
    FinanceEntryType type,
    int minor,
    DateTime date,
    String? note,
  ) async {
    await _run(
      'entry $key',
      _finance.addEntry(
        idempotencyKey: '$_k-entry-$key',
        categoryId: category.id,
        type: type,
        amount: Money.egp(minor),
        date: date,
        note: note,
      ),
    );
  }

  Future<Budget?> _budget(String month, int expectedIncome) async {
    final result = await _budgets.createBudget(
      idempotencyKey: '$_k-budget-$month',
      month: month,
      expectedIncomeMinorUnits: expectedIncome,
    );
    return result.fold((f) {
      if (f is BudgetAlreadyExistsForMonthFailure) return f.existing;
      _log.add('budget: ${f.message}');
      return null;
    }, (b) => b);
  }
}
