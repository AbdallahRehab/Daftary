import 'dart:io';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/transactions/data/datasources/transactions_dao.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:daftary/core/money/money.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// T075 / FR-023 — the boundary between this feature and the existing
/// person-to-person ledger.
///
/// The two features share one SQLite file, which is exactly why this needs a
/// permanent test rather than a code review: nothing in the schema stops a
/// future query from joining `finance_entries` to `people`, so the guarantee
/// is asserted behaviorally instead — recording, editing, and deleting
/// finance entries must leave every person's balance and the overview
/// totals bit-for-bit unchanged.
void main() {
  late AppDatabase db;
  late FinanceRepositoryImpl finance;
  late TransactionsRepositoryImpl transactions;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    finance = FinanceRepositoryImpl(FinanceDao(db));
    transactions = TransactionsRepositoryImpl(TransactionsDao(db), db);

    await db
        .into(db.people)
        .insert(
          PeopleCompanion.insert(
            id: 'p1',
            name: 'Ahmed',
            normalizedName: 'ahmed',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await db
        .into(db.people)
        .insert(
          PeopleCompanion.insert(
            id: 'p2',
            name: 'Mona',
            normalizedName: 'mona',
            createdAt: 1,
            updatedAt: 1,
          ),
        );

    await transactions.addTransaction(
      idempotencyKey: 'tx-1',
      personId: 'p1',
      amount: const Money.fromMinorUnits(50000),
      direction: TransactionDirection.given,
      date: DateTime(2026, 9, 1),
    );
    await transactions.addTransaction(
      idempotencyKey: 'tx-2',
      personId: 'p2',
      amount: const Money.fromMinorUnits(20000),
      direction: TransactionDirection.received,
      date: DateTime(2026, 9, 2),
    );
  });

  tearDown(() => db.close());

  Future<OverviewSummary> readOverview() async {
    final result = await transactions.getOverview();
    return result.getOrElse((failure) => throw StateError(failure.message));
  }

  Future<Map<String, int>> readBalances() async {
    final p1 = await transactions.getPersonBalance('p1');
    final p2 = await transactions.getPersonBalance('p2');
    return {
      'p1': p1.getOrElse((f) => throw StateError(f.message)).net.minorUnits,
      'p2': p2.getOrElse((f) => throw StateError(f.message)).net.minorUnits,
    };
  }

  test(
    'adding, editing, and deleting finance entries never moves a person '
    'balance or an overview total (FR-023)',
    () async {
      final balancesBefore = await readBalances();
      final overviewBefore = await readOverview();

      final added = await finance.addEntry(
        idempotencyKey: 'fin-1',
        categoryId: 'seed_groceries',
        type: FinanceEntryType.expense,
        amountMinorUnits: 75000,
        date: DateTime(2026, 9, 3),
      );
      final entry = added.getOrElse((f) => throw StateError(f.message));

      await finance.addEntry(
        idempotencyKey: 'fin-2',
        categoryId: 'seed_salary',
        type: FinanceEntryType.income,
        amountMinorUnits: 900000,
        date: DateTime(2026, 9, 4),
      );

      expect(await readBalances(), balancesBefore);
      expect(await readOverview(), overviewBefore);

      await finance.editEntry(
        entryId: entry.id,
        categoryId: 'seed_rent',
        amountMinorUnits: 120000,
        date: DateTime(2026, 9, 5),
      );
      expect(await readBalances(), balancesBefore);
      expect(await readOverview(), overviewBefore);

      await finance.deleteEntry(entry.id);
      expect(await readBalances(), balancesBefore);
      expect(await readOverview(), overviewBefore);

      await finance.restoreEntry(entry.id);
      expect(await readBalances(), balancesBefore);
      expect(await readOverview(), overviewBefore);
    },
  );

  test(
    'transaction activity never leaks into a finance summary or breakdown '
    '(FR-023, the same boundary from the other side)',
    () async {
      final period = DateRange(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
      );

      final emptySummary = await finance.getSummary(period);
      final summary = emptySummary.getOrElse(
        (f) => throw StateError(f.message),
      );
      expect(
        summary.totalExpense.minorUnits,
        0,
        reason: 'two MoneyTransactions exist, but no FinanceEntries do',
      );
      expect(summary.totalIncome.minorUnits, 0);

      final breakdown = await finance.getCategoryBreakdown(period);
      expect(breakdown.getOrElse((f) => throw StateError(f.message)), isEmpty);

      final history = await finance.getHistory();
      expect(history.getOrElse((f) => throw StateError(f.message)), isEmpty);
    },
  );

  test('no finance query names the people or money_transactions tables', () {
    // The behavioral assertions above prove the totals stay separate; this
    // one guards the mechanism, so a future join is caught at the point it
    // is written rather than only if it happens to shift a number.
    //
    // Comments are stripped first — the DAO's own doc comment says it never
    // joins against `people`, and scanning it raw would flag that sentence
    // as the very violation it is promising not to commit.
    String code(String path) => File(path)
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');

    final sources = [
      code('lib/features/finance/data/datasources/finance_dao.dart'),
      code('lib/features/finance/data/repositories/finance_repository_impl.dart'),
      code('lib/features/finance/data/repositories/category_repository_impl.dart'),
    ];

    for (final source in sources) {
      expect(source.contains('.people'), isFalse);
      expect(source.contains('moneyTransactions'), isFalse);
      expect(source.contains('money_transactions'), isFalse);
      expect(source.contains('transactionAuditEntries'), isFalse);
    }
  });
}
