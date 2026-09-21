import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/balance_queries.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/overview_summary.dart';
import '../../domain/entities/person_balance.dart';
import '../../domain/entities/transaction_audit_entry.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../datasources/transactions_dao.dart';
import '../models/transaction_mapper.dart';

@LazySingleton(as: TransactionsRepository)
class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl(this._dao, this._db);

  final TransactionsDao _dao;
  final db.AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, MoneyTransaction>> addTransaction({
    required String idempotencyKey,
    required String personId,
    required Money amount,
    required TransactionDirection direction,
    required DateTime date,
    String? note,
  }) async {
    final validation = _validateAmountAndPerson(amount, personId);
    if (validation != null) return Left(validation);
    try {
      final companion = db.MoneyTransactionsCompanion.insert(
        id: _uuid.v4(),
        idempotencyKey: idempotencyKey,
        personId: personId,
        amountMinorUnits: amount.minorUnits,
        direction: direction.dbValue,
        kind: TransactionKind.initialExchange.dbValue,
        date: _dateOnlyMillis(date),
        note: db.Value(note),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final row = await _dao.insertTransactionIdempotent(companion);
      await _writeCreatedAuditEntry(row.id);
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to record transaction: $e'));
    }
  }

  @override
  Future<Either<Failure, MoneyTransaction>> recordRepayment({
    required String idempotencyKey,
    required String personId,
    required Money amount,
    required DateTime date,
    String? note,
  }) async {
    final validation = _validateAmountAndPerson(amount, personId);
    if (validation != null) return Left(validation);
    try {
      final currentNet = await _dao.netBalanceMinorUnits(personId);
      final direction = currentNet > 0
          ? TransactionDirection.received
          : TransactionDirection.given;
      final companion = db.MoneyTransactionsCompanion.insert(
        id: _uuid.v4(),
        idempotencyKey: idempotencyKey,
        personId: personId,
        amountMinorUnits: amount.minorUnits,
        direction: direction.dbValue,
        kind: TransactionKind.repayment.dbValue,
        date: _dateOnlyMillis(date),
        note: db.Value(note),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final row = await _dao.insertTransactionIdempotent(companion);
      await _writeCreatedAuditEntry(row.id);
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to record repayment: $e'));
    }
  }

  @override
  Future<Either<Failure, MoneyTransaction>> editTransaction({
    required String transactionId,
    required Money amount,
    required TransactionDirection direction,
    required DateTime date,
    String? note,
  }) async {
    if (!amount.isPositive) {
      return const Left(ValidationFailure('Amount must be greater than zero'));
    }
    try {
      final existing = await _dao.getById(transactionId);
      if (existing == null || existing.deletedAt != null) {
        return const Left(NotFoundFailure('Transaction not found'));
      }
      final previousValuesJson = jsonEncode({
        'amountMinorUnits': existing.amountMinorUnits,
        'direction': existing.direction,
        'date': existing.date,
        'note': existing.note,
      });
      final now = DateTime.now();
      final companion = db.MoneyTransactionsCompanion(
        amountMinorUnits: db.Value(amount.minorUnits),
        direction: db.Value(direction.dbValue),
        date: db.Value(_dateOnlyMillis(date)),
        note: db.Value(note),
        editedAt: db.Value(now.millisecondsSinceEpoch),
      );
      final updated = await _dao.updateTransaction(transactionId, companion);
      await _dao.insertAuditEntry(
        db.TransactionAuditEntriesCompanion.insert(
          id: _uuid.v4(),
          transactionId: transactionId,
          changeType: AuditChangeType.edited.dbValue,
          previousValuesJson: db.Value(previousValuesJson),
          changedAt: now.millisecondsSinceEpoch,
        ),
      );
      return Right(updated.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to edit transaction: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTransaction(String transactionId) async {
    try {
      final existing = await _dao.getById(transactionId);
      if (existing == null || existing.deletedAt != null) {
        return const Left(NotFoundFailure('Transaction not found'));
      }
      final previousValuesJson = jsonEncode({
        'amountMinorUnits': existing.amountMinorUnits,
        'direction': existing.direction,
        'date': existing.date,
        'note': existing.note,
      });
      final now = DateTime.now();
      await _dao.softDelete(transactionId, now);
      await _dao.insertAuditEntry(
        db.TransactionAuditEntriesCompanion.insert(
          id: _uuid.v4(),
          transactionId: transactionId,
          changeType: AuditChangeType.deleted.dbValue,
          previousValuesJson: db.Value(previousValuesJson),
          changedAt: now.millisecondsSinceEpoch,
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to delete transaction: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MoneyTransaction>>> getPersonHistory(
    String personId,
  ) async {
    try {
      final rows = await _dao.getHistoryForPerson(personId);
      return Right(rows.map((row) => row.toDomain()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to load history: $e'));
    }
  }

  @override
  Future<Either<Failure, PersonBalance>> getPersonBalance(
    String personId,
  ) async {
    try {
      final net = await _dao.netBalanceMinorUnits(personId);
      return Right(
        PersonBalance(personId: personId, net: Money.fromMinorUnits(net)),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to compute balance: $e'));
    }
  }

  @override
  Future<Either<Failure, OverviewSummary>> getOverview() async {
    try {
      final balances = await _dao.netBalanceMinorUnitsForAllPeople();
      final lastActivity = await _db.lastActivityMillisForAllPeople();
      final peopleRows = await _db.select(_db.people).get();

      final theyOweYou = <PersonSummary>[];
      final youOweThem = <PersonSummary>[];
      var settledCount = 0;
      var totalOwed = 0;
      var totalOwes = 0;

      for (final row in peopleRows) {
        final net = balances[row.id] ?? 0;
        if (net > 0) {
          totalOwed += net;
          theyOweYou.add(
            PersonSummary(
              personId: row.id,
              name: row.name,
              net: Money.fromMinorUnits(net),
              isArchived: row.isArchived,
            ),
          );
        } else if (net < 0) {
          totalOwes += -net;
          youOweThem.add(
            PersonSummary(
              personId: row.id,
              name: row.name,
              net: Money.fromMinorUnits(net),
              isArchived: row.isArchived,
            ),
          );
        } else {
          settledCount++;
        }
      }

      int activityOf(PersonSummary summary) =>
          lastActivity[summary.personId] ?? 0;
      theyOweYou.sort((a, b) => activityOf(b).compareTo(activityOf(a)));
      youOweThem.sort((a, b) => activityOf(b).compareTo(activityOf(a)));

      return Right(
        OverviewSummary(
          totalOwedToUser: Money.fromMinorUnits(totalOwed),
          totalUserOwes: Money.fromMinorUnits(totalOwes),
          peopleTheyOweYou: theyOweYou,
          peopleYouOweThem: youOweThem,
          settledCount: settledCount,
        ),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to compute overview: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasAnyTransaction() async {
    try {
      return Right(await _dao.hasAnyTransaction());
    } catch (e) {
      return Left(
        CacheFailure('Failed to check for existing transactions: $e'),
      );
    }
  }

  Future<void> _writeCreatedAuditEntry(String transactionId) {
    return _dao.insertAuditEntry(
      db.TransactionAuditEntriesCompanion.insert(
        id: _uuid.v4(),
        transactionId: transactionId,
        changeType: AuditChangeType.created.dbValue,
        changedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Every transaction must belong to a distinct, already-selected `Person`
  /// — this app has no separate "self" Person record to compare against
  /// (single-user, no account), so "no distinct counterparty selected"
  /// (Edge Cases) surfaces as a blank `personId`, which this rejects.
  ValidationFailure? _validateAmountAndPerson(Money amount, String personId) {
    if (!amount.isPositive) {
      return const ValidationFailure('Amount must be greater than zero');
    }
    if (personId.trim().isEmpty) {
      return const ValidationFailure('A person must be selected');
    }
    return null;
  }

  int _dateOnlyMillis(DateTime date) =>
      DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
}
