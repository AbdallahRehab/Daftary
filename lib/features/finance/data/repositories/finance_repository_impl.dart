import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/watch_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/sync/sync_mapper_registry.dart' show SyncWire;
import '../../domain/entities/category_breakdown_item.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/entities/finance_entry_audit.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_history_filter.dart';
import '../../domain/entities/finance_summary.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_dao.dart';
import '../models/finance_entry_audit_mapper.dart';
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
    required Money amount,
    required DateTime date,
    String? note,
  }) async {
    if (!amount.isPositive) {
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
        amountMinorUnits: amount.minorUnits,
        currencyCode: db.Value(amount.currency.code),
        date: dateOnlyMillis(date),
        note: db.Value(note),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final row = await _dao.insertEntryIdempotent(
        companion,
        audit: _audit(FinanceAuditChange.created),
      );
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to record entry: $e'));
    }
  }

  @override
  Future<Either<Failure, FinanceEntry>> editEntry({
    required String entryId,
    required String categoryId,
    required Money amount,
    required DateTime date,
    String? note,
  }) async {
    if (!amount.isPositive) {
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
        amountMinorUnits: db.Value(amount.minorUnits),
        currencyCode: db.Value(amount.currency.code),
        date: db.Value(dateOnlyMillis(date)),
        note: db.Value(note),
        editedAt: db.Value(DateTime.now().millisecondsSinceEpoch),
      );
      final updated = await _dao.updateEntry(
        entryId,
        companion,
        // Built from the row as the transaction reads it, so the history
        // can never hold values a concurrent write already replaced.
        audit: (previous) => _audit(
          FinanceAuditChange.edited,
          // Type and category make a switch between income and expense
          // traceable (RF-08). The date is a calendar day, so it reads the
          // same in every time zone.
          previousValues: {
            'amountMinorUnits': previous.amountMinorUnits,
            'currencyCode': previous.currencyCode,
            'type': previous.type,
            'categoryId': previous.categoryId,
            'date': SyncWire.localDay(
              DateTime.fromMillisecondsSinceEpoch(previous.date),
            ),
            'note': previous.note,
          },
        ),
      );
      if (updated == null) {
        return const Left(NotFoundFailure('Entry not found'));
      }
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
      final deleted = await _dao.softDeleteEntry(
        entryId,
        DateTime.now(),
        audit: _audit(FinanceAuditChange.deleted),
      );
      if (!deleted) return const Left(NotFoundFailure('Entry not found'));
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
      await _dao.restoreEntry(
        entryId,
        audit: _audit(FinanceAuditChange.restored),
      );
      final restored = await _dao.getEntryById(entryId);
      return Right(restored!.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to restore entry: $e'));
    }
  }

  @override
  Future<Either<Failure, FinanceEntry>> getEntryById(String entryId) async {
    try {
      final row = await _dao.getEntryById(entryId);
      if (row == null) {
        return const Left(NotFoundFailure('Entry not found'));
      }
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to load entry: $e'));
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
  Future<Either<Failure, FinancePeriodTotals>> getSummaryTotals(
    DateRange period,
  ) async {
    try {
      final rows = await _dao.getSummaryTotals(period);
      final income = <Money>[];
      final expense = <Money>[];
      for (final row in rows) {
        final amount = Money.fromMinorUnits(
          row.totalMinorUnits,
          Currency.fromCode(row.currencyCode),
        );
        if (row.type == FinanceEntryType.income.dbValue) {
          income.add(amount);
        } else if (row.type == FinanceEntryType.expense.dbValue) {
          expense.add(amount);
        }
      }
      return Right(FinancePeriodTotals(income: income, expense: expense));
    } catch (e) {
      return Left(CacheFailure('Failed to compute summary: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CategoryCurrencyTotals>>> getCategoryTotals(
    DateRange period, {
    FinanceEntryType? type,
  }) async {
    try {
      final rows = await _dao.getCategoryBreakdown(period, type: type);
      // Rows arrive ordered by their single-currency SUM descending; folding
      // them by category in first-seen order keeps that order for the
      // single-currency (EGP-only) case exactly as before 018.
      final byCategory = <String, CategoryCurrencyTotals>{};
      for (final row in rows) {
        final amount = Money.fromMinorUnits(
          row.totalMinorUnits,
          Currency.fromCode(row.currencyCode),
        );
        final existing = byCategory[row.categoryId];
        byCategory[row.categoryId] = CategoryCurrencyTotals(
          categoryId: row.categoryId,
          categoryName: row.categoryName,
          icon: row.icon,
          totals: [...?existing?.totals, amount],
        );
      }
      return Right(byCategory.values.toList());
    } catch (e) {
      return Left(CacheFailure('Failed to compute category breakdown: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<FinanceEntry>>> watchHistory({
    FinanceHistoryFilter? filter,
    required int limit,
  }) => _dao.entriesChanged().reRead(
    () => getHistory(filter: filter, limit: limit),
  );

  @override
  Stream<Either<Failure, FinancePeriodTotals>> watchSummaryTotals(
    DateRange period,
  ) => _dao.entriesChanged().reRead(() => getSummaryTotals(period));

  @override
  Stream<Either<Failure, List<FinancePeriodTotals>>>
  watchSummaryTotalsForPeriods(List<DateRange> periods) =>
      _dao.entriesChanged().reRead(() async {
        final results = await Future.wait(periods.map(getSummaryTotals));
        final totals = <FinancePeriodTotals>[];
        for (final result in results) {
          final failure = result.getLeft().toNullable();
          if (failure != null) return Left(failure);
          totals.add(result.toNullable()!);
        }
        return Right(totals);
      });

  @override
  Stream<Either<Failure, List<CategoryCurrencyTotals>>> watchCategoryTotals(
    DateRange period, {
    FinanceEntryType? type,
  }) => _dao.categoryTotalsChanged().reRead(
    () => getCategoryTotals(period, type: type),
  );

  @override
  Stream<Either<Failure, bool>> watchHasAnyEntry() =>
      _dao.entriesChanged().reRead(hasAnyEntry);

  @override
  Future<Either<Failure, bool>> hasAnyEntry() async {
    try {
      return Right(await _dao.hasAnyEntry());
    } catch (e) {
      return Left(CacheFailure('Failed to check for existing entries: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<FinanceEntryAudit>>> watchEntryAuditHistory(
    String entryId,
  ) => _dao.entryAuditsChanged().reRead(() async {
    try {
      final rows = await _dao.getAuditsForEntry(entryId);
      return Right<Failure, List<FinanceEntryAudit>>(
        rows.map((r) => r.toDomain()).toList(),
      );
    } catch (e) {
      return Left<Failure, List<FinanceEntryAudit>>(
        CacheFailure('Failed to load change history: $e'),
      );
    }
  });

  /// 022 D1: every history row of every entry, oldest first; nothing is
  /// filtered out, so the history of a deleted entry is included.
  @override
  Future<Either<Failure, List<FinanceEntryAudit>>> getAllEntryAudits() async {
    try {
      final rows = await _dao.getAllAudits();
      return Right([for (final row in rows) row.toDomain()]);
    } catch (e) {
      return Left(CacheFailure('Failed to load change history: $e'));
    }
  }

  EntryAuditDraft _audit(
    FinanceAuditChange change, {
    Map<String, Object?>? previousValues,
  }) => EntryAuditDraft(
    id: _uuid.v4(),
    changeType: change.value,
    previousValuesJson: previousValues == null
        ? null
        : jsonEncode(previousValues),
    changedAt: DateTime.now().millisecondsSinceEpoch,
  );

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
