import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/category_breakdown_item.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_history_filter.dart';
import '../../domain/entities/finance_summary.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_dao.dart';
import '../models/finance_entry_mapper.dart';

@LazySingleton(as: FinanceRepository)
class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl(this._dao);

  final FinanceDao _dao;
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, FinanceEntry>> addEntry({
    required String idempotencyKey,
    required String categoryId,
    required FinanceEntryType type,
    required int amountMinorUnits,
    required DateTime date,
    String? note,
  }) async {
    if (amountMinorUnits <= 0) {
      return const Left(ValidationFailure('Amount must be greater than zero'));
    }
    if (categoryId.trim().isEmpty) {
      return const Left(ValidationFailure('A category must be selected'));
    }
    try {
      final mismatch = await _validateCategoryMatches(categoryId, type);
      if (mismatch != null) return Left(mismatch);

      final companion = db.FinanceEntriesCompanion.insert(
        id: _uuid.v4(),
        idempotencyKey: idempotencyKey,
        categoryId: categoryId,
        type: type.dbValue,
        amountMinorUnits: amountMinorUnits,
        date: dateOnlyMillis(date),
        note: db.Value(note),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final row = await _dao.insertEntryIdempotent(companion);
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to record entry: $e'));
    }
  }

  @override
  Future<Either<Failure, FinanceEntry>> editEntry({
    required String entryId,
    required String categoryId,
    required int amountMinorUnits,
    required DateTime date,
    String? note,
  }) async {
    if (amountMinorUnits <= 0) {
      return const Left(ValidationFailure('Amount must be greater than zero'));
    }
    if (categoryId.trim().isEmpty) {
      return const Left(ValidationFailure('A category must be selected'));
    }
    try {
      final existing = await _dao.getEntryById(entryId);
      if (existing == null || existing.deletedAt != null) {
        return const Left(NotFoundFailure('Entry not found'));
      }
      final category = await _dao.getCategoryById(categoryId);
      if (category == null) {
        return const Left(NotFoundFailure('Category not found'));
      }

      final companion = db.FinanceEntriesCompanion(
        categoryId: db.Value(categoryId),
        // Re-derived from the category rather than accepted from the
        // caller (contract note in finance_repository.md): moving an entry
        // to an income category *is* what makes it an income entry, so
        // there is no way for the two to disagree after an edit.
        type: db.Value(category.type),
        amountMinorUnits: db.Value(amountMinorUnits),
        date: db.Value(dateOnlyMillis(date)),
        note: db.Value(note),
        editedAt: db.Value(DateTime.now().millisecondsSinceEpoch),
      );
      final updated = await _dao.updateEntry(entryId, companion);
      return Right(updated.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to edit entry: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteEntry(String entryId) async {
    try {
      final existing = await _dao.getEntryById(entryId);
      if (existing == null || existing.deletedAt != null) {
        return const Left(NotFoundFailure('Entry not found'));
      }
      await _dao.softDeleteEntry(entryId, DateTime.now());
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to delete entry: $e'));
    }
  }

  @override
  Future<Either<Failure, FinanceEntry>> restoreEntry(String entryId) async {
    try {
      final existing = await _dao.getEntryById(entryId);
      if (existing == null) {
        return const Left(NotFoundFailure('Entry not found'));
      }
      // Already active: a second undo tap (or one arriving after the window
      // closed and the list reloaded) succeeds quietly rather than erroring
      // at a user who did nothing wrong.
      if (existing.deletedAt == null) {
        return Right(existing.toDomain());
      }
      await _dao.restoreEntry(entryId);
      final restored = await _dao.getEntryById(entryId);
      return Right(restored!.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to restore entry: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FinanceEntry>>> getHistory({
    FinanceHistoryFilter? filter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final rows = await _dao.getHistory(
        filter: filter,
        limit: limit,
        offset: offset,
      );
      return Right([for (final row in rows) row.toDomain()]);
    } catch (e) {
      return Left(CacheFailure('Failed to load history: $e'));
    }
  }

  @override
  Future<Either<Failure, FinanceSummary>> getSummary(DateRange period) async {
    try {
      final totals = await _dao.getSummaryTotals(period);
      return Right(
        FinanceSummary(
          totalIncome: Money.fromMinorUnits(
            totals[FinanceEntryType.income.dbValue] ?? 0,
          ),
          totalExpense: Money.fromMinorUnits(
            totals[FinanceEntryType.expense.dbValue] ?? 0,
          ),
          period: period,
        ),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to compute summary: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CategoryBreakdownItem>>> getCategoryBreakdown(
    DateRange period, {
    FinanceEntryType? type,
  }) async {
    try {
      final rows = await _dao.getCategoryBreakdown(period, type: type);
      final periodTotal = rows.fold<int>(
        0,
        (sum, row) => sum + row.totalMinorUnits,
      );
      return Right([
        for (final row in rows)
          CategoryBreakdownItem(
            categoryId: row.categoryId,
            categoryName: row.categoryName,
            icon: row.icon,
            total: Money.fromMinorUnits(row.totalMinorUnits),
            // Zero rather than a division by zero when the period is empty
            // — which can only happen if every row summed to 0.
            shareOfPeriod: periodTotal == 0
                ? 0
                : row.totalMinorUnits / periodTotal,
          ),
      ]);
    } catch (e) {
      return Left(CacheFailure('Failed to compute category breakdown: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasAnyEntry() async {
    try {
      return Right(await _dao.hasAnyEntry());
    } catch (e) {
      return Left(CacheFailure('Failed to check for existing entries: $e'));
    }
  }

  /// An income entry pointing at an expense category (or vice versa) is
  /// rejected here, not left to the schema: the `type` columns are plain
  /// text on both tables, so nothing in SQLite would catch the mismatch.
  Future<Failure?> _validateCategoryMatches(
    String categoryId,
    FinanceEntryType type,
  ) async {
    final category = await _dao.getCategoryById(categoryId);
    if (category == null) {
      return const NotFoundFailure('Category not found');
    }
    if (category.type != type.dbValue) {
      return ValidationFailure(
        'Category "${category.name}" is a ${category.type} category and '
        'cannot be used for a ${type.dbValue} entry',
      );
    }
    return null;
  }
}
