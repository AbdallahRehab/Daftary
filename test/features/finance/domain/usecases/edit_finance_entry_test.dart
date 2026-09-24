import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/edit_finance_entry.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockFinanceRepository extends Mock implements FinanceRepository {}

/// T064 — `EditFinanceEntry` (FR-019).
///
/// The property worth proving is that `type` is *re-derived* from the
/// category rather than accepted from the caller: the use case exposes no
/// `type` parameter at all, so moving an entry to an income category is the
/// only way to make it an income entry, and the two can never disagree.
void main() {
  group('delegation', () {
    late MockFinanceRepository repository;
    late EditFinanceEntry editFinanceEntry;

    final date = DateTime(2026, 3, 4);
    final edited = FinanceEntry(
      id: 'e1',
      idempotencyKey: 'k1',
      categoryId: 'seed_rent',
      type: FinanceEntryType.expense,
      amount: const Money.egp(120000),
      date: date,
      createdAt: DateTime(2026, 3, 1),
      editedAt: DateTime(2026, 3, 4),
    );

    setUp(() {
      repository = MockFinanceRepository();
      editFinanceEntry = EditFinanceEntry(repository);
    });

    test('passes amount/category/date/note straight through', () async {
      when(
        () => repository.editEntry(
          entryId: 'e1',
          categoryId: 'seed_rent',
          amount: Money.egp(120000),
          date: date,
          note: 'March rent',
        ),
      ).thenAnswer((_) async => Right<Failure, FinanceEntry>(edited));

      final result = await editFinanceEntry(
        entryId: 'e1',
        categoryId: 'seed_rent',
        amount: Money.egp(120000),
        date: date,
        note: 'March rent',
      );

      expect(result, Right<Failure, FinanceEntry>(edited));
    });

    test('surfaces a ValidationFailure for a non-positive amount', () async {
      when(
        () => repository.editEntry(
          entryId: 'e1',
          categoryId: 'seed_rent',
          amount: Money.egp(0),
          date: date,
          note: null,
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, FinanceEntry>(
          ValidationFailure('Amount must be greater than zero'),
        ),
      );

      final result = await editFinanceEntry(
        entryId: 'e1',
        categoryId: 'seed_rent',
        amount: Money.egp(0),
        date: date,
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('against a real database', () {
    late AppDatabase db;
    late FinanceRepositoryImpl repository;
    late EditFinanceEntry editFinanceEntry;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = FinanceRepositoryImpl(FinanceDao(db));
      editFinanceEntry = EditFinanceEntry(repository);
    });

    tearDown(() => db.close());

    Future<FinanceEntry> seedExpense() async {
      final result = await repository.addEntry(
        idempotencyKey: 'k-edit',
        categoryId: 'seed_groceries',
        type: FinanceEntryType.expense,
        amount: Money.egp(5000),
        date: DateTime(2026, 3, 1),
      );
      return result.getOrElse((f) => throw StateError(f.message));
    }

    test(
      'updates amount, category, date, and note, and sets editedAt',
      () async {
        final entry = await seedExpense();
        expect(entry.editedAt, null);

        final result = await editFinanceEntry(
          entryId: entry.id,
          categoryId: 'seed_rent',
          amount: Money.egp(99900),
          date: DateTime(2026, 3, 15),
          note: 'moved to rent',
        );
        final edited = result.getOrElse((f) => throw StateError(f.message));

        expect(edited.amount.minorUnits, 99900);
        expect(edited.categoryId, 'seed_rent');
        expect(edited.date, DateTime(2026, 3, 15));
        expect(edited.note, 'moved to rent');
        expect(edited.editedAt != null, isTrue);
        expect(edited.isEdited, isTrue);
      },
    );

    test('moving an expense entry to an income category re-derives its type '
        '(FR-019) — the use case never accepts a type', () async {
      final entry = await seedExpense();
      expect(entry.type, FinanceEntryType.expense);

      final result = await editFinanceEntry(
        entryId: entry.id,
        categoryId: 'seed_salary',
        amount: Money.egp(5000),
        date: entry.date,
      );
      final edited = result.getOrElse((f) => throw StateError(f.message));

      expect(
        edited.type,
        FinanceEntryType.income,
        reason: 'the category it now points at is what decides the type',
      );
    });

    test(
      'rejects a non-positive amount, leaving the stored entry alone',
      () async {
        final entry = await seedExpense();

        final result = await editFinanceEntry(
          entryId: entry.id,
          categoryId: 'seed_groceries',
          amount: Money.egp(0),
          date: entry.date,
        );
        expect(result.isLeft(), isTrue);

        final reread = await repository.getEntryById(entry.id);
        final stored = reread.getOrElse((f) => throw StateError(f.message));
        expect(stored.amount.minorUnits, 5000);
        expect(stored.editedAt, null);
      },
    );

    test('an unknown entry id is a NotFoundFailure', () async {
      final result = await editFinanceEntry(
        entryId: 'does-not-exist',
        categoryId: 'seed_groceries',
        amount: Money.egp(1000),
        date: DateTime(2026, 3, 1),
      );
      expect(result.isLeft(), isTrue);
    });
  });
}
