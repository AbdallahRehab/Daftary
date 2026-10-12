import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/provenance/import_provenance.dart';
import '../../domain/entities/pending_sms_import.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_value_types.dart';
import '../../domain/repositories/sms_duplicate_lookup.dart';
import '../models/pending_import_mapper.dart';

/// Read-only duplicate queries over both aggregates (domain-interfaces
/// §3.3, FR-060), plus the tombstone and pending lookups the duplicate
/// rules need.
///
/// Saved records are read through the existing
/// `idx_transactions_date (date, deleted_at)` and
/// `idx_finance_entries_date (date, deleted_at)` indexes; the pending pair
/// through `idx_sms_pending_amount_pair`. No index is added. Deleted
/// records never match. Any source matches (manual, OCR, SMS).
///
/// Every failure is the fixed token [_lookupFailure]; no exception text is
/// kept.
@LazySingleton(as: SmsDuplicateLookup)
class SmsDuplicateDao implements SmsDuplicateLookup {
  SmsDuplicateDao(this._db);

  final db.AppDatabase _db;

  static const Failure _lookupFailure = CacheFailure(
    'sms_duplicate_lookup_failed',
  );

  /// The pending-pair window (FR-059 tier 1, branch 2).
  static const int pairWindowMinutes = 10;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } catch (_) {
      return const Left(_lookupFailure);
    }
  }

  /// `[day(from) - 1 day, day(to) + 2 days)` as local-midnight millis:
  /// calendar arithmetic (`DateTime(y, m, d - 1)`), never `Duration` math.
  static (int, int) _window(DateTime from, DateTime to) => (
    DateTime(from.year, from.month, from.day - 1).millisecondsSinceEpoch,
    DateTime(to.year, to.month, to.day + 2).millisecondsSinceEpoch,
  );

  static DateTime _day(int millis) {
    final at = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateTime(at.year, at.month, at.day);
  }

  static DuplicateRecordRef _fromTransaction(db.MoneyTransaction row) =>
      DuplicateRecordRef(
        id: row.id,
        recordType: SavedRecordType.moneyTransaction,
        type: row.direction == 'given'
            ? SuggestedRecordType.given
            : SuggestedRecordType.received,
        amount: Money.fromMinorUnits(
          row.amountMinorUnits,
          Currency.fromCode(row.currencyCode),
        ),
        date: _day(row.date),
        importProvenance: ImportProvenance.fromWire(row.importSource),
        note: row.note,
      );

  static DuplicateRecordRef _fromEntry(db.FinanceEntry row) =>
      DuplicateRecordRef(
        id: row.id,
        recordType: SavedRecordType.financeEntry,
        type: row.type == 'income'
            ? SuggestedRecordType.income
            : SuggestedRecordType.expense,
        amount: Money.fromMinorUnits(
          row.amountMinorUnits,
          Currency.fromCode(row.currencyCode),
        ),
        date: _day(row.date),
        importProvenance: ImportProvenance.fromWire(row.importSource),
        note: row.note,
      );

  /// Saved records dated in `[from - 1 day, to + 1 day]`, optionally of
  /// one amount and one direction group.
  Future<List<DuplicateRecordRef>> _savedIn(
    DateTime from,
    DateTime to, {
    Money? amount,
    bool? moneyOut,
  }) async {
    final (start, end) = _window(from, to);
    final transactions =
        await (_db.select(_db.moneyTransactions)..where((t) {
              var predicate =
                  t.date.isBiggerOrEqualValue(start) &
                  t.date.isSmallerThanValue(end) &
                  t.deletedAt.isNull();
              if (amount != null) {
                predicate =
                    predicate &
                    t.amountMinorUnits.equals(amount.minorUnits) &
                    t.currencyCode.equals(amount.currency.code);
              }
              if (moneyOut != null) {
                predicate =
                    predicate &
                    t.direction.equals(moneyOut ? 'given' : 'received');
              }
              return predicate;
            }))
            .get();
    final entries =
        await (_db.select(_db.financeEntries)..where((e) {
              var predicate =
                  e.date.isBiggerOrEqualValue(start) &
                  e.date.isSmallerThanValue(end) &
                  e.deletedAt.isNull();
              if (amount != null) {
                predicate =
                    predicate &
                    e.amountMinorUnits.equals(amount.minorUnits) &
                    e.currencyCode.equals(amount.currency.code);
              }
              if (moneyOut != null) {
                predicate =
                    predicate & e.type.equals(moneyOut ? 'expense' : 'income');
              }
              return predicate;
            }))
            .get();
    return [
      for (final row in transactions)
        if (Currency.tryFromCode(row.currencyCode) != null)
          _fromTransaction(row),
      for (final row in entries)
        if (Currency.tryFromCode(row.currencyCode) != null) _fromEntry(row),
    ];
  }

  @override
  Future<Either<Failure, List<DuplicateRecordRef>>> findSavedMatches({
    required Money amount,
    required DateTime date,
    required SuggestedRecordType type,
  }) async {
    if (!type.isSavable) return const Right([]);
    // Direction group: expense = given (money out), income = received.
    final moneyOut =
        type == SuggestedRecordType.expense ||
        type == SuggestedRecordType.given;
    return _guard(
      () => _savedIn(date, date, amount: amount, moneyOut: moneyOut),
    );
  }

  @override
  Future<Either<Failure, SavedRecordWindow>> loadWindow(
    DateTime minDate,
    DateTime maxDate,
  ) => _guard(() async => SavedRecordWindow(await _savedIn(minDate, maxDate)));

  @override
  Future<Either<Failure, PendingSmsImport?>> findPendingPair(
    PendingSmsImport item,
  ) async {
    final amount = item.amount;
    final last4 = item.cardLast4;
    final merchantKey = item.merchantKey;
    final minutes = _minuteOf(item.occurredOn, item.timeMinutes);
    if (amount == null ||
        last4 == null ||
        merchantKey == null ||
        minutes == null ||
        item.refHash != null) {
      return const Right(null);
    }
    return _guard(() async {
      final rows =
          await (_db.select(_db.pendingSmsImports)..where(
                (p) =>
                    p.amountMinorUnits.equals(amount.minorUnits) &
                    p.currencyCode.equals(amount.currency.code) &
                    p.status.equals(SmsImportStatus.pending.dbValue) &
                    p.id.equals(item.id).not() &
                    p.cardLast4.equals(last4) &
                    p.merchantKey.equals(merchantKey) &
                    p.refHash.isNull(),
              ))
              .get();
      PendingSmsImport? best;
      int? bestGap;
      for (final row in rows) {
        final other = row.toDomain();
        final otherMinutes = _minuteOf(other.occurredOn, other.timeMinutes);
        if (otherMinutes == null) continue;
        final gap = (otherMinutes - minutes).abs();
        if (gap > pairWindowMinutes) continue;
        if (bestGap == null || gap < bestGap) {
          best = other;
          bestGap = gap;
        }
      }
      return best;
    });
  }

  /// Minutes since the epoch day of [day] at [timeMinutes], on the local
  /// calendar (so a pair across midnight still compares correctly).
  static int? _minuteOf(DateTime? day, int? timeMinutes) {
    if (day == null || timeMinutes == null) return null;
    final dayNumber = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(1970)).inDays;
    return dayNumber * 1440 + timeMinutes;
  }

  @override
  Future<Either<Failure, String?>> refHashForSavedRecord(
    String savedRecordId,
  ) => _guard(() async {
    final rows = await (_db.select(
      _db.smsImportTombstones,
    )..where((t) => t.savedRecordId.equals(savedRecordId))).get();
    for (final row in rows) {
      if (row.refHash != null) return row.refHash;
    }
    return null;
  });

  @override
  Future<Either<Failure, String?>> bankForSavedRecord(String savedRecordId) =>
      _guard(() async {
        final rows = await (_db.select(
          _db.smsImportTombstones,
        )..where((t) => t.savedRecordId.equals(savedRecordId))).get();
        return rows.isEmpty ? null : rows.first.bankId;
      });

  @override
  Future<Either<Failure, List<ImportKeyMatch>>> findKeyMatches({
    required String excludeId,
    required String fingerprint,
    String? refAmountHash,
  }) => _guard(() async {
    final pending =
        await (_db.select(_db.pendingSmsImports)..where((p) {
              var keys = p.fingerprint.equals(fingerprint);
              if (refAmountHash != null) {
                keys = keys | p.refAmountHash.equals(refAmountHash);
              }
              return keys & p.id.equals(excludeId).not();
            }))
            .get();
    final tombstones =
        await (_db.select(_db.smsImportTombstones)..where((t) {
              var keys = t.fingerprint.equals(fingerprint);
              if (refAmountHash != null) {
                keys = keys | t.refAmountHash.equals(refAmountHash);
              }
              return keys;
            }))
            .get();
    return [
      for (final row in pending)
        ImportKeyMatch(
          pendingId: row.id,
          fingerprint: row.fingerprint,
          bankId: row.bankId,
          refHash: row.refHash,
          refAmountHash: row.refAmountHash,
          occurredOn: row.occurredOn == null ? null : _day(row.occurredOn!),
        ),
      for (final row in tombstones)
        ImportKeyMatch(
          fingerprint: row.fingerprint,
          bankId: row.bankId,
          refHash: row.refHash,
          refAmountHash: row.refAmountHash,
          outcome: TombstoneOutcome.fromDb(row.outcome),
          savedRecordId: row.savedRecordId,
          savedRecordType: SavedRecordType.fromDb(row.savedRecordType),
        ),
    ];
  });

  @override
  Future<Either<Failure, List<PendingSmsImport>>> findPendingWithAmount(
    Money amount, {
    required String excludeId,
  }) => _guard(() async {
    final rows =
        await (_db.select(_db.pendingSmsImports)..where(
              (p) =>
                  p.amountMinorUnits.equals(amount.minorUnits) &
                  p.currencyCode.equals(amount.currency.code) &
                  p.status.equals(SmsImportStatus.pending.dbValue) &
                  p.id.equals(excludeId).not(),
            ))
            .get();
    return [for (final row in rows) row.toDomain()];
  });

  @override
  Future<Either<Failure, List<DuplicateRecordRef>>> savedRecordsForRefHash(
    String refHash,
  ) => _guard(() async {
    final tombstones =
        await (_db.select(_db.smsImportTombstones)..where(
              (t) =>
                  t.refHash.equals(refHash) &
                  t.outcome.equals(TombstoneOutcome.added.dbValue) &
                  t.savedRecordId.isNotNull(),
            ))
            .get();
    final refs = <DuplicateRecordRef>[];
    for (final tombstone in tombstones) {
      final id = tombstone.savedRecordId!;
      final type = SavedRecordType.fromDb(tombstone.savedRecordType);
      if (type == SavedRecordType.moneyTransaction) {
        final row =
            await (_db.select(_db.moneyTransactions)
                  ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
                .getSingleOrNull();
        if (row != null && Currency.tryFromCode(row.currencyCode) != null) {
          refs.add(_fromTransaction(row));
        }
      } else if (type == SavedRecordType.financeEntry) {
        final row =
            await (_db.select(_db.financeEntries)
                  ..where((e) => e.id.equals(id) & e.deletedAt.isNull()))
                .getSingleOrNull();
        if (row != null && Currency.tryFromCode(row.currencyCode) != null) {
          refs.add(_fromEntry(row));
        }
      }
    }
    return refs;
  });
}
