import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/usecases/delete_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/restore_finance_entry.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversion_fakes.dart';
import '../../../../helpers/test_daos.dart';

/// T065 — `DeleteFinanceEntry` / `RestoreFinanceEntry` (FR-020).
///
/// The delete commits immediately rather than being held pending for the
/// undo window (research.md Decision 8): if the app dies mid-window the
/// data is already consistent, whereas a deferred delete would leave a
/// half-state nothing is left running to resolve. These tests assert that
/// commit-now behavior directly, and that a stale or repeated undo tap is a
/// quiet success rather than an error shown to someone who did nothing
/// wrong.
void main() {
  late AppDatabase db;
  late FinanceRepositoryImpl repository;
  late DeleteFinanceEntry deleteFinanceEntry;
  late RestoreFinanceEntry restoreFinanceEntry;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinanceRepositoryImpl(testFinanceDao(db));
    deleteFinanceEntry = DeleteFinanceEntry(repository);
    restoreFinanceEntry = RestoreFinanceEntry(repository);
  });

  tearDown(() => db.close());

  final period = DateRange(
    start: DateTime(2026, 4, 1),
    end: DateTime(2026, 4, 30),
  );

  Future<FinanceEntry> seedExpense({int amount = 25000}) async {
    final result = await repository.addEntry(
      idempotencyKey: 'k-${DateTime.now().microsecondsSinceEpoch}',
      categoryId: 'seed_groceries',
      type: FinanceEntryType.expense,
      amount: Money.egp(amount),
      date: DateTime(2026, 4, 10),
    );
    return result.getOrElse((f) => throw StateError(f.message));
  }

  Future<int> expenseTotal() async {
    final summary = await summaryUseCase(repository)(period);
    return summary
        .getOrElse((f) => throw StateError(f.message))
        .totalExpense!
        .minorUnits;
  }

  test('delete sets deletedAt immediately and commits', () async {
    final entry = await seedExpense();
    expect(await expenseTotal(), 25000);

    final result = await deleteFinanceEntry(entry.id);
    expect(result.isRight(), isTrue);

    // Read back through a fresh query: the tombstone is persisted, not held
    // in memory pending the undo window.
    final reread = await repository.getEntryById(entry.id);
    final stored = reread.getOrElse((f) => throw StateError(f.message));
    expect(stored.deletedAt != null, isTrue);
    expect(stored.isDeleted, isTrue);
  });

  test('a deleted entry drops out of history and totals at once', () async {
    final entry = await seedExpense();
    await deleteFinanceEntry(entry.id);

    final history = await repository.getHistory();
    expect(
      history.getOrElse((_) => const []).where((e) => e.id == entry.id),
      isEmpty,
    );
    expect(await expenseTotal(), 0);
  });

  test('restore un-sets deletedAt and brings the entry back intact', () async {
    final entry = await seedExpense();
    await deleteFinanceEntry(entry.id);

    final result = await restoreFinanceEntry(entry.id);
    final restored = result.getOrElse((f) => throw StateError(f.message));

    expect(restored.deletedAt, null);
    expect(restored.isDeleted, isFalse);
    expect(restored.amount.minorUnits, 25000);
    expect(restored.categoryId, entry.categoryId);
    expect(restored.date, entry.date);
    expect(await expenseTotal(), 25000);
  });

  test('restoring an entry that is not deleted is a no-op success, not an '
      'error (a stale or repeated undo tap)', () async {
    final entry = await seedExpense();

    // Never deleted at all.
    final first = await restoreFinanceEntry(entry.id);
    expect(first.isRight(), isTrue);
    expect(first.getOrElse((f) => throw StateError(f.message)).deletedAt, null);

    // Deleted, restored, then restored a second time.
    await deleteFinanceEntry(entry.id);
    await restoreFinanceEntry(entry.id);
    final second = await restoreFinanceEntry(entry.id);
    expect(second.isRight(), isTrue);
    expect(await expenseTotal(), 25000);
  });

  test('deleting an already-deleted entry reports NotFound', () async {
    final entry = await seedExpense();
    await deleteFinanceEntry(entry.id);

    final again = await deleteFinanceEntry(entry.id);
    expect(again.isLeft(), isTrue);
  });

  test('deleting an unknown id reports NotFound', () async {
    final result = await deleteFinanceEntry('does-not-exist');
    expect(result.isLeft(), isTrue);
  });

  test('restoring an unknown id reports NotFound', () async {
    final result = await restoreFinanceEntry('does-not-exist');
    expect(result.isLeft(), isTrue);
  });

  test('deleting one entry leaves the others untouched', () async {
    final first = await seedExpense();
    final second = await seedExpense(amount: 10000);

    await deleteFinanceEntry(first.id);

    expect(await expenseTotal(), 10000);
    final survivor = await repository.getEntryById(second.id);
    expect(
      survivor.getOrElse((f) => throw StateError(f.message)).deletedAt,
      null,
    );
  });
}
