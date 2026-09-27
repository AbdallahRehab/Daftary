import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/balance_queries.dart';
import '../../../../core/database/watch_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../../../currency/domain/usecases/get_conversion_context.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/overview_summary.dart';
import '../../domain/entities/person_balance.dart';
import '../../domain/entities/transaction_audit_entry.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../../domain/services/person_balance_calculator.dart';
import '../datasources/transactions_dao.dart';
import '../models/transaction_mapper.dart';

@LazySingleton(as: TransactionsRepository)
class TransactionsRepositoryImpl implements TransactionsRepository {
  /// [getConversionContext] supplies the primary currency + exchange rates
  /// every balance/overview aggregate converts into (018). It is always
  /// injected in the app; when omitted (single-currency tests only) the
  /// EGP-only context is used, under which any non-EGP amount is reported
  /// as blocked — never converted at 1:1.
  TransactionsRepositoryImpl(
    this._dao,
    this._db, {
    GetConversionContext? getConversionContext,
  }) : _getConversionContext = getConversionContext;

  final TransactionsDao _dao;
  final db.AppDatabase _db;
  final GetConversionContext? _getConversionContext;
  static const _uuid = Uuid();
  static const _calculator = PersonBalanceCalculator();

  Future<Either<Failure, ConversionContext>> _conversionContext() async {
    final getContext = _getConversionContext;
    if (getContext == null) return const Right(ConversionContext.egpOnly);
    return getContext();
  }

  Future<PersonBalance> _balanceFor(
    String personId,
    ConversionContext context,
  ) async {
    final nativeNets = await _dao.netBalanceMinorUnitsByCurrency(personId);
    return _calculator.calculate(
      personId: personId,
      nativeNetsByCode: nativeNets,
      context: context,
    );
  }

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
        currencyCode: db.Value(amount.currency.code),
        direction: direction.dbValue,
        kind: TransactionKind.initialExchange.dbValue,
        date: _dateOnlyMillis(date),
        note: db.Value(note),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final row = await _insertWithCreatedAudit(companion);
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
    final contextResult = await _conversionContext();
    return contextResult.fold(left, (context) async {
      try {
        final direction = await _repaymentDirection(
          personId,
          amount.currency,
          context,
        );
        final companion = db.MoneyTransactionsCompanion.insert(
          id: _uuid.v4(),
          idempotencyKey: idempotencyKey,
          personId: personId,
          amountMinorUnits: amount.minorUnits,
          currencyCode: db.Value(amount.currency.code),
          direction: direction.dbValue,
          kind: TransactionKind.repayment.dbValue,
          date: _dateOnlyMillis(date),
          note: db.Value(note),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        final row = await _insertWithCreatedAudit(companion);
        return Right(row.toDomain());
      } catch (e) {
        return Left(CacheFailure('Failed to record repayment: $e'));
      }
    });
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
        'currencyCode': existing.currencyCode,
        'direction': existing.direction,
        'date': existing.date,
        'note': existing.note,
      });
      final now = DateTime.now();
      final companion = db.MoneyTransactionsCompanion(
        amountMinorUnits: db.Value(amount.minorUnits),
        currencyCode: db.Value(amount.currency.code),
        direction: db.Value(direction.dbValue),
        date: db.Value(_dateOnlyMillis(date)),
        note: db.Value(note),
        editedAt: db.Value(now.millisecondsSinceEpoch),
      );
      // The edit, its audit entry and both outbox rows commit together.
      final updated = await _db.transaction(() async {
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
        return updated;
      });
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
        'currencyCode': existing.currencyCode,
        'direction': existing.direction,
        'date': existing.date,
        'note': existing.note,
      });
      final now = DateTime.now();
      // The soft delete, its audit entry and both outbox rows commit
      // together.
      await _db.transaction(() async {
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
      });
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
    final context = await _conversionContext();
    return context.fold(left, (context) async {
      try {
        return Right(await _balanceFor(personId, context));
      } catch (e) {
        return Left(CacheFailure('Failed to compute balance: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, Map<String, PersonBalance>>> getPersonBalances(
    List<String> personIds,
  ) async {
    final context = await _conversionContext();
    return context.fold(left, (context) async {
      try {
        final nets = await _dao.netBalanceMinorUnitsByCurrencyForAllPeople();
        return Right({
          for (final personId in personIds)
            personId: _calculator.calculate(
              personId: personId,
              nativeNetsByCode: nets[personId] ?? const {},
              context: context,
            ),
        });
      } catch (e) {
        return Left(CacheFailure('Failed to compute balances: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, OverviewSummary>> getOverview() async {
    final context = await _conversionContext();
    return context.fold(left, (context) async {
      try {
        return Right(await _computeOverview(context));
      } catch (e) {
        return Left(CacheFailure('Failed to compute overview: $e'));
      }
    });
  }

  Future<OverviewSummary> _computeOverview(ConversionContext context) async {
    final balances = await _dao.netBalanceMinorUnitsByCurrencyForAllPeople();
    final lastActivity = await _db.lastActivityMillisForAllPeople();
    final peopleRows = await _db.select(_db.people).get();

    final theyOweYou = <PersonSummary>[];
    final youOweThem = <PersonSummary>[];
    final rateNeeded = <PersonSummary>[];
    final missing = <Currency>[];
    var settledCount = 0;
    var totalOwed = 0;
    var totalOwes = 0;
    var owedBlocked = false;
    var owesBlocked = false;

    for (final row in peopleRows) {
      final balance = _calculator.calculate(
        personId: row.id,
        nativeNetsByCode: balances[row.id] ?? const {},
        context: context,
      );
      final summary = PersonSummary(
        personId: row.id,
        name: row.name,
        net: balance.net,
        isArchived: row.isArchived,
        nativeNets: balance.nativeNets,
        missingRatesFor: balance.missingRatesFor,
      );
      for (final currency in balance.missingRatesFor) {
        if (!missing.contains(currency)) missing.add(currency);
      }
      final net = balance.net;
      switch (balance.status) {
        case RelationshipStatus.theyOweYou:
          if (net == null) {
            owedBlocked = true;
          } else {
            totalOwed += net.minorUnits;
          }
          theyOweYou.add(summary);
        case RelationshipStatus.youOweThem:
          if (net == null) {
            owesBlocked = true;
          } else {
            totalOwes += -net.minorUnits;
          }
          youOweThem.add(summary);
        case RelationshipStatus.settled:
          settledCount++;
        case null:
          // Opposite-direction per-currency nets with a missing rate: the
          // direction itself is unknown, so both totals are incomplete.
          owedBlocked = true;
          owesBlocked = true;
          rateNeeded.add(summary);
      }
    }

    int activityOf(PersonSummary summary) =>
        lastActivity[summary.personId] ?? 0;
    theyOweYou.sort((a, b) => activityOf(b).compareTo(activityOf(a)));
    youOweThem.sort((a, b) => activityOf(b).compareTo(activityOf(a)));
    rateNeeded.sort((a, b) => activityOf(b).compareTo(activityOf(a)));

    return OverviewSummary(
      totalOwedToUser: owedBlocked
          ? null
          : Money.fromMinorUnits(totalOwed, context.primary),
      totalUserOwes: owesBlocked
          ? null
          : Money.fromMinorUnits(totalOwes, context.primary),
      peopleTheyOweYou: theyOweYou,
      peopleYouOweThem: youOweThem,
      peopleRateNeeded: rateNeeded,
      settledCount: settledCount,
      missingRatesFor: missing,
    );
  }

  /// A repayment settles (part of) the current balance, so its direction is
  /// the opposite of whoever currently owes: they owe you ⇒ you *receive*,
  /// otherwise you *give* (FR-011). When the converted balance is blocked
  /// and its direction unknown (opposite-direction currencies), the sign of
  /// the balance in the repayment's own [currency] decides instead.
  Future<TransactionDirection> _repaymentDirection(
    String personId,
    Currency currency,
    ConversionContext context,
  ) async {
    final balance = await _balanceFor(personId, context);
    final status =
        balance.status ??
        (balance.nativeNets
                .where((m) => m.currency == currency)
                .any((m) => m.isPositive)
            ? RelationshipStatus.theyOweYou
            : RelationshipStatus.youOweThem);
    return status == RelationshipStatus.theyOweYou
        ? TransactionDirection.received
        : TransactionDirection.given;
  }

  /// Every table a converted balance depends on: amounts, the people they
  /// belong to, and the conversion inputs (018).
  Set<db.TableInfo<db.Table, Object?>> get _balanceTables => {
    _db.moneyTransactions,
    _db.people,
    _db.exchangeRates,
    _db.primaryCurrencySettings,
  };

  @override
  Stream<Either<Failure, List<MoneyTransaction>>> watchPersonHistory(
    String personId,
  ) => _db.watchEither({
    _db.moneyTransactions,
  }, () => getPersonHistory(personId));

  @override
  Stream<Either<Failure, PersonBalance>> watchPersonBalance(String personId) =>
      _db.watchEither(_balanceTables, () => getPersonBalance(personId));

  @override
  Stream<Either<Failure, Map<String, PersonBalance>>> watchPersonBalances(
    List<String> personIds,
  ) => _db.watchEither(_balanceTables, () => getPersonBalances(personIds));

  @override
  Stream<Either<Failure, OverviewSummary>> watchOverview() =>
      _db.watchEither(_balanceTables, getOverview);

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

  /// Inserts idempotently and writes the `created` audit entry in one
  /// transaction, so both rows and their outbox entries commit together.
  Future<db.MoneyTransaction> _insertWithCreatedAudit(
    db.MoneyTransactionsCompanion companion,
  ) {
    return _db.transaction(() async {
      final row = await _dao.insertTransactionIdempotent(companion);
      await _writeCreatedAuditEntry(row.id);
      return row;
    });
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
