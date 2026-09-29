import 'dart:convert';

import 'package:daftary/core/database/app_database.dart' as schema;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/get_primary_currency.dart';
import 'package:daftary/features/savings/data/repositories/savings_repository_impl.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal_detail.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:drift/native.dart';

import '../../../helpers/test_daos.dart';

/// A settable clock: "today" for every savings rule under test.
class SettableClock implements AppClock {
  SettableClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

/// A real in-memory database behind a real [SavingsRepositoryImpl], with
/// 018's real currency repository on the same database (EGP primary and no
/// rates until a test sets them) and a fixed clock — so every rule under
/// test (validation, idempotency, conversion, the balance aggregate, audit
/// and outbox rows) is exercised exactly as in the app.
class SavingsHarness {
  SavingsHarness._(this.db, this.currency, this.clock, this.repository);

  /// 2026-09-15, mid-month, so day-of-month cases are unambiguous.
  static final DateTime defaultToday = DateTime(2026, 9, 15, 10, 30);

  static Future<SavingsHarness> open({DateTime? today}) async {
    final database = schema.AppDatabase.forTesting(NativeDatabase.memory());
    final clock = SettableClock(today ?? defaultToday);
    final currency = CurrencyRepositoryImpl(testCurrencyDao(database), clock);
    final repository = SavingsRepositoryImpl(
      testSavingsDao(database),
      database,
      GetConversionContext(currency),
      const CurrencyConverterImpl(),
      const DefaultSavingsCalculator(),
      clock,
    );
    return SavingsHarness._(database, currency, clock, repository);
  }

  final schema.AppDatabase db;
  final CurrencyRepositoryImpl currency;
  final SettableClock clock;
  final SavingsRepositoryImpl repository;

  GetPrimaryCurrency get getPrimaryCurrency => GetPrimaryCurrency(currency);

  var _keySeq = 0;
  String nextKey() => 'key-${_keySeq++}';

  Future<void> close() => db.close();

  DateTime get today =>
      DateTime(clock.current.year, clock.current.month, clock.current.day);

  Future<SavingsGoal> createGoal({
    String name = 'Emergency Fund',
    Currency currency = Currency.egp,
    int target = 10000000,
    int? starting,
    int? monthly,
    DateTime? targetDate,
    String? type,
  }) async {
    final result = await repository.createSavingsGoal(
      idempotencyKey: nextKey(),
      name: name,
      type: type,
      currency: currency,
      targetAmountMinorUnits: target,
      startingAmountMinorUnits: starting,
      monthlyContributionMinorUnits: monthly,
      targetDate: targetDate,
    );
    return result.getOrElse((f) => throw StateError(f.message));
  }

  Future<SavingsContribution> contribute(
    String goalId,
    int minorUnits, {
    Currency currency = Currency.egp,
    DateTime? date,
  }) async {
    final result = await repository.logContribution(
      idempotencyKey: nextKey(),
      goalId: goalId,
      amount: Money.fromMinorUnits(minorUnits, currency),
      date: date ?? today,
    );
    return result.getOrElse((f) => throw StateError(f.message));
  }

  Future<SavingsContribution> withdraw(
    String goalId,
    int minorUnits, {
    Currency currency = Currency.egp,
    DateTime? date,
  }) async {
    final result = await repository.logWithdrawal(
      idempotencyKey: nextKey(),
      goalId: goalId,
      amount: Money.fromMinorUnits(minorUnits, currency),
      date: date ?? today,
    );
    return result.getOrElse((f) => throw StateError(f.message));
  }

  Future<SavingsGoalDetail> detail(String goalId) async =>
      (await repository.getGoalDetail(
        goalId,
      )).getOrElse((f) => throw StateError(f.message));

  /// "1 [from] = [rate] [to]", through 018's repository.
  Future<void> setRate(Currency from, double rate, {Currency? to}) async {
    final result = await currency.setExchangeRate(
      currencyCode: from.code,
      relativeToCurrencyCode: (to ?? Currency.egp).code,
      rate: rate,
    );
    result.getOrElse((f) => throw StateError(f.message));
  }

  Future<void> setPrimary(Currency primary) async {
    final result = await currency.setPrimaryCurrency(primary.code);
    result.getOrElse((f) => throw StateError(f.message));
  }

  Future<List<schema.SavingsGoal>> goalRows() =>
      db.select(db.savingsGoals).get();

  Future<List<schema.SavingsContribution>> contributionRows() =>
      db.select(db.savingsContributions).get();

  Future<List<schema.SavingsContributionAudit>> auditRows() =>
      db.select(db.savingsContributionAudits).get();

  /// The decoded prior values of every audit row of [contributionId].
  Future<List<Map<String, Object?>>> auditValuesFor(
    String contributionId,
  ) async => [
    for (final row in await auditRows())
      if (row.contributionId == contributionId)
        jsonDecode(row.previousValuesJson) as Map<String, Object?>,
  ];

  /// Outbox rows queued for [type] (and, when given, one [entityId]).
  Future<int> outboxCount(SyncEntityType type, {String? entityId}) async {
    final rows = await db.select(db.syncOutboxEntries).get();
    return rows
        .where(
          (r) =>
              r.entityType == type.wire &&
              (entityId == null || r.entityId == entityId),
        )
        .length;
  }

  /// Archives [goalId] through the real repository (US4's
  /// `archiveSavingsGoal`), failing the test if it is refused.
  Future<void> archiveDirectly(String goalId) async {
    final result = await repository.archiveSavingsGoal(goalId);
    result.getOrElse((f) => throw StateError(f.message));
  }

  /// The payload of the most recently queued outbox row for [entityId] —
  /// what the next sync will upload for it.
  Future<Map<String, Object?>> lastOutboxPayload(String entityId) async {
    final rows = [
      for (final r in await db.select(db.syncOutboxEntries).get())
        if (r.entityId == entityId) r,
    ];
    return jsonDecode(rows.last.payloadJson) as Map<String, Object?>;
  }

  /// Every outbox op type queued for [type] — only ever `upsert` here.
  Future<Set<String>> outboxOpTypes(SyncEntityType type) async => {
    for (final r in await db.select(db.syncOutboxEntries).get())
      if (r.entityType == type.wire) r.opType,
  };
}
