import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/watch_tables.dart';
import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../currency/domain/entities/conversion_result.dart';
import '../../../currency/domain/entities/exchange_rate.dart';
import '../../../currency/domain/services/currency_converter.dart';
import '../../../currency/domain/usecases/get_conversion_context.dart';
import '../../domain/entities/savings_contribution.dart';
import '../../domain/entities/savings_contribution_audit.dart';
import '../../domain/entities/savings_failures.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/entities/savings_goal_detail.dart';
import '../../domain/entities/savings_goal_with_contributions.dart';
import '../../domain/entities/savings_overview.dart';
import '../../domain/repositories/savings_repository.dart';
import '../../domain/services/savings_calculator.dart';
import '../datasources/savings_dao.dart';
import '../models/savings_contribution_audit_mapper.dart';
import '../models/savings_contribution_mapper.dart';
import '../models/savings_goal_mapper.dart';

/// Offline-first [SavingsRepository] over this feature's own three tables.
/// Owns every savings validation rule, so each caller — form, assistant
/// tool, notification source — gets the same answers.
///
/// 018: a goal has one currency. An entry typed in another currency is
/// converted into it here, once, at log (or edit) time through
/// [CurrencyConverter] with the current conversion context; a missing rate
/// is a `RatesMissingFailure` and nothing is written (FR-028).
///
/// Every completion figure comes from [SavingsCalculator]; this class only
/// sums entries (one SQL aggregate) and hands the result over.
///
/// "Today" — for target-date validation, a starting amount's date and every
/// estimate — comes from the injected [AppClock].
@LazySingleton(as: SavingsRepository)
class SavingsRepositoryImpl implements SavingsRepository {
  SavingsRepositoryImpl(
    this._dao,
    this._db,
    this._getConversionContext,
    this._converter,
    this._calculator,
    this._clock,
  );

  final SavingsDao _dao;
  final db.AppDatabase _db;
  final GetConversionContext _getConversionContext;
  final CurrencyConverter _converter;
  final SavingsCalculator _calculator;
  final AppClock _clock;

  static const _uuid = Uuid();

  // ------------------------------------------------------------------ goals

  @override
  Future<Either<Failure, SavingsGoal>> createSavingsGoal({
    required String idempotencyKey,
    required String name,
    String? type,
    required Currency currency,
    required int targetAmountMinorUnits,
    int? startingAmountMinorUnits,
    int? monthlyContributionMinorUnits,
    DateTime? targetDate,
  }) async {
    final validation =
        _validatePlan(
          name: name,
          targetAmountMinorUnits: targetAmountMinorUnits,
          monthlyContributionMinorUnits: monthlyContributionMinorUnits,
        ) ??
        _validateStartingAmount(startingAmountMinorUnits) ??
        _validateNewTargetDate(targetDate);
    if (validation != null) return Left(validation);
    try {
      // A retried save returns the goal it already created (FR-022).
      final retried = await _dao.getGoalByIdempotencyKey(idempotencyKey);
      if (retried != null) return Right(retried.toDomain());

      final now = _clock.now();
      final nowMillis = now.millisecondsSinceEpoch;
      final goalId = _uuid.v4();
      final starting = startingAmountMinorUnits ?? 0;
      final row = await _dao.insertGoalIdempotent(
        db.SavingsGoalsCompanion.insert(
          id: goalId,
          idempotencyKey: idempotencyKey,
          name: name.trim(),
          type: db.Value(_normalizedType(type)),
          currencyCode: db.Value(currency.code),
          targetAmountMinorUnits: targetAmountMinorUnits,
          monthlyContributionMinorUnits: db.Value(
            monthlyContributionMinorUnits,
          ),
          targetDate: db.Value(_dateOnlyMillisOrNull(targetDate)),
          createdAt: nowMillis,
          updatedAt: nowMillis,
        ),
        // The starting amount is the goal's first entry, never a field of
        // the goal (research.md Decision 3). Its key is derived from the
        // goal's, so it is unique yet traceable to this save.
        initialContribution: starting > 0
            ? db.SavingsContributionsCompanion.insert(
                id: _uuid.v4(),
                idempotencyKey: '$idempotencyKey:starting',
                goalId: goalId,
                type: ContributionType.contribution.value,
                amountMinorUnits: starting,
                enteredAmountMinorUnits: starting,
                enteredCurrencyCode: currency.code,
                date: _dateOnlyMillis(now),
                note: const db.Value(SavingsContribution.startingAmountNote),
                createdAt: nowMillis,
              )
            : null,
      );
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to create savings goal: $e'));
    }
  }

  @override
  Future<Either<Failure, SavingsGoal>> editSavingsGoal({
    required String goalId,
    required String name,
    String? type,
    required int targetAmountMinorUnits,
    int? monthlyContributionMinorUnits,
    DateTime? targetDate,
  }) async {
    final validation = _validatePlan(
      name: name,
      targetAmountMinorUnits: targetAmountMinorUnits,
      monthlyContributionMinorUnits: monthlyContributionMinorUnits,
    );
    if (validation != null) return Left(validation);
    try {
      final existing = await _activeGoalOrNull(goalId);
      if (existing == null) return const Left(_goalNotFound);

      // FR-003 applies when a target date is *set*: a date that was valid
      // when chosen and has since passed makes the goal overdue, not the
      // rest of the goal uneditable (data-model.md).
      final targetMillis = _dateOnlyMillisOrNull(targetDate);
      if (targetMillis != null && targetMillis != existing.targetDate) {
        final dateFailure = _validateNewTargetDate(targetDate);
        if (dateFailure != null) return Left(dateFailure);
      }

      // Never the currency (FR-027), and never the history: only the plan
      // the progress is computed against changes.
      final updated = await _dao.updateGoal(
        goalId,
        db.SavingsGoalsCompanion(
          name: db.Value(name.trim()),
          type: db.Value(_normalizedType(type)),
          targetAmountMinorUnits: db.Value(targetAmountMinorUnits),
          monthlyContributionMinorUnits: db.Value(
            monthlyContributionMinorUnits,
          ),
          targetDate: db.Value(targetMillis),
          updatedAt: db.Value(_clock.now().millisecondsSinceEpoch),
        ),
      );
      return Right(updated.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to edit savings goal: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> archiveSavingsGoal(String goalId) =>
      _setArchived(goalId, archived: true);

  @override
  Future<Either<Failure, Unit>> restoreSavingsGoal(String goalId) =>
      _setArchived(goalId, archived: false);

  /// FR-020: flips only the flag (and `updatedAt`) — the goal's entries,
  /// and so every figure derived from them, are untouched. Already in the
  /// requested state is a no-op success that queues nothing.
  Future<Either<Failure, Unit>> _setArchived(
    String goalId, {
    required bool archived,
  }) async {
    try {
      final goal = await _activeGoalOrNull(goalId);
      if (goal == null) return const Left(_goalNotFound);
      if (goal.isArchived == archived) return const Right(unit);
      await _dao.updateGoal(
        goalId,
        db.SavingsGoalsCompanion(
          isArchived: db.Value(archived),
          updatedAt: db.Value(_clock.now().millisecondsSinceEpoch),
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(
        CacheFailure(
          'Failed to ${archived ? 'archive' : 'restore'} savings goal: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteSavingsGoal(String goalId) async {
    try {
      await _dao.transaction(() async {
        final goal = await _activeGoalOrNull(goalId);
        if (goal == null) throw const _Rejected(_goalNotFound);
        // FR-021: any entry ever logged — soft-deleted ones included, so the
        // audit trail stays attributable — blocks the delete; the caller
        // offers archiving instead.
        if (await _dao.hasAnyContribution(goalId)) {
          throw const _Rejected(
            GoalHasHistoryFailure(
              'This goal has logged entries; archive it instead',
            ),
          );
        }
        // A tombstone, never a row delete: it syncs as an upsert carrying
        // `deleted_at` (021 — `recordDelete` is never used for savings).
        final nowMillis = _clock.now().millisecondsSinceEpoch;
        await _dao.updateGoal(
          goalId,
          db.SavingsGoalsCompanion(
            deletedAt: db.Value(nowMillis),
            updatedAt: db.Value(nowMillis),
          ),
        );
      });
      return const Right(unit);
    } on _Rejected catch (e) {
      return Left(e.failure);
    } catch (e) {
      return Left(CacheFailure('Failed to delete savings goal: $e'));
    }
  }

  @override
  Future<Either<Failure, SavingsOverview>> getSavingsOverview({
    bool includeArchived = false,
  }) async {
    try {
      final contextResult = await _getConversionContext();
      if (contextResult.isLeft()) {
        return Left(contextResult.getLeft().toNullable()!);
      }
      final context = contextResult.toNullable()!;
      // One snapshot: the goals and the balances summed for them.
      final (goalRows, balances) = await _dao.transaction(
        () async => (
          await _dao.getGoals(includeArchived: includeArchived),
          await _dao.balancesByGoal(),
        ),
      );
      final asOf = _clock.now();
      return Right(
        SavingsOverview(
          primaryCurrency: context.primary,
          goals: [
            for (final row in goalRows)
              _overviewLine(
                row.toDomain(),
                current: balances[row.id] ?? 0,
                primary: context.primary,
                rates: context.rates,
                asOf: asOf,
              ),
          ],
        ),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to load savings overview: $e'));
    }
  }

  /// One overview line: progress in the goal's own currency, and its
  /// current amount converted into [primary] at read time (FR-019). A
  /// missing rate blocks only this line — it stays listed, is left out of
  /// the total and names the rate it needs (018 FR-009); never a 1:1 guess.
  GoalOverviewLine _overviewLine(
    SavingsGoal goal, {
    required int current,
    required Currency primary,
    required List<ExchangeRate> rates,
    required DateTime asOf,
  }) {
    final progress = _calculator.progressFor(
      goal,
      currentAmountMinorUnits: current,
      asOf: asOf,
    );
    // Nothing saved is zero in every currency: no rate is needed to know
    // it, so an empty foreign-currency goal never marks the total
    // incomplete.
    if (current == 0) {
      return GoalOverviewLine(
        goal: goal,
        progress: progress,
        primaryCurrencyAmountMinorUnits: 0,
      );
    }
    return switch (_converter.convert(
      amount: Money.fromMinorUnits(current, goal.currency),
      targetCurrency: primary,
      rates: rates,
    )) {
      ConversionConverted(:final value) => GoalOverviewLine(
        goal: goal,
        progress: progress,
        primaryCurrencyAmountMinorUnits: value.minorUnits,
      ),
      ConversionRateUnavailable(:final missingRateFor) => GoalOverviewLine(
        goal: goal,
        progress: progress,
        primaryCurrencyAmountMinorUnits: null,
        missingRatesFor: [missingRateFor],
      ),
    };
  }

  @override
  Stream<Either<Failure, SavingsOverview>> watchSavingsOverview({
    bool includeArchived = false,
  }) => _db.watchEither(
    _detailTables,
    () => getSavingsOverview(includeArchived: includeArchived),
  );

  // ---------------------------------------------------------- contributions

  @override
  Future<Either<Failure, SavingsContribution>> logContribution({
    required String idempotencyKey,
    required String goalId,
    required Money amount,
    required DateTime date,
    String? note,
  }) => _logEntry(
    type: ContributionType.contribution,
    idempotencyKey: idempotencyKey,
    goalId: goalId,
    amount: amount,
    date: date,
    note: note,
  );

  @override
  Future<Either<Failure, SavingsContribution>> logWithdrawal({
    required String idempotencyKey,
    required String goalId,
    required Money amount,
    required DateTime date,
    String? note,
  }) => _logEntry(
    type: ContributionType.withdrawal,
    idempotencyKey: idempotencyKey,
    goalId: goalId,
    amount: amount,
    date: date,
    note: note,
  );

  Future<Either<Failure, SavingsContribution>> _logEntry({
    required ContributionType type,
    required String idempotencyKey,
    required String goalId,
    required Money amount,
    required DateTime date,
    String? note,
  }) async {
    if (!amount.isPositive) return const Left(_amountNotPositive);
    try {
      // Checked before anything that may have changed since the original
      // save (an archive, a rate): a retry returns what that save wrote.
      final retried = await _dao.getContributionByIdempotencyKey(
        idempotencyKey,
      );
      if (retried != null) return Right(retried.toDomain());

      final goal = await _activeGoalOrNull(goalId);
      if (goal == null) return const Left(_goalNotFound);
      if (goal.isArchived) {
        return const Left(
          GoalArchivedFailure('Restore the goal to log new entries'),
        );
      }

      final converted = await _toGoalCurrency(amount, _currencyOf(goal));
      if (converted.isLeft()) return Left(converted.getLeft().toNullable()!);
      final amountMinorUnits = converted.toNullable()!;
      if (amountMinorUnits <= 0) return const Left(_amountNotPositive);

      final nowMillis = _clock.now().millisecondsSinceEpoch;
      final row = await _dao.transaction(() async {
        // Inside the transaction, so the balance checked is the balance the
        // withdrawal is written against (research.md Decision 5).
        if (type == ContributionType.withdrawal) {
          final balance = await _dao.balanceForGoal(goalId);
          if (amountMinorUnits > balance) {
            throw _Rejected(_exceedsBalance(balance));
          }
        }
        return _dao.insertContributionIdempotent(
          db.SavingsContributionsCompanion.insert(
            id: _uuid.v4(),
            idempotencyKey: idempotencyKey,
            goalId: goalId,
            type: type.value,
            amountMinorUnits: amountMinorUnits,
            enteredAmountMinorUnits: amount.minorUnits,
            enteredCurrencyCode: amount.currency.code,
            date: _dateOnlyMillis(date),
            note: db.Value(_normalizedNote(note)),
            createdAt: nowMillis,
          ),
        );
      });
      return Right(row.toDomain());
    } on _Rejected catch (e) {
      return Left(e.failure);
    } catch (e) {
      return Left(CacheFailure('Failed to log savings entry: $e'));
    }
  }

  @override
  Future<Either<Failure, SavingsContribution>> editContribution({
    required String contributionId,
    required Money amount,
    required DateTime date,
    String? note,
  }) async {
    if (!amount.isPositive) return const Left(_amountNotPositive);
    try {
      final existing = await _activeContributionOrNull(contributionId);
      if (existing == null) return const Left(_entryNotFound);
      // Allowed on an archived goal (FR-020): only a deleted one refuses.
      final goal = await _activeGoalOrNull(existing.goalId);
      if (goal == null) return const Left(_goalNotFound);

      // Re-converted at the rate in effect now (spec Edge Cases); the prior
      // entered and converted figures are kept in the audit row.
      final converted = await _toGoalCurrency(amount, _currencyOf(goal));
      if (converted.isLeft()) return Left(converted.getLeft().toNullable()!);
      final amountMinorUnits = converted.toNullable()!;
      if (amountMinorUnits <= 0) return const Left(_amountNotPositive);

      final isWithdrawal = existing.type == ContributionType.withdrawal.value;
      final now = _clock.now();
      final updated = await _dao.transaction(() async {
        // The balance without this entry's own current value, so an edited
        // withdrawal is never checked against itself (data-model.md).
        final others = await _dao.balanceForGoal(
          existing.goalId,
          excludingContributionId: existing.id,
        );
        final after = isWithdrawal
            ? others - amountMinorUnits
            : others + amountMinorUnits;
        if (after < 0) {
          throw _Rejected(
            _exceedsBalance(
              isWithdrawal ? others : others + existing.amountMinorUnits,
            ),
          );
        }
        final row = await _dao.updateContribution(
          existing.id,
          db.SavingsContributionsCompanion(
            amountMinorUnits: db.Value(amountMinorUnits),
            enteredAmountMinorUnits: db.Value(amount.minorUnits),
            enteredCurrencyCode: db.Value(amount.currency.code),
            date: db.Value(_dateOnlyMillis(date)),
            note: db.Value(_normalizedNote(note)),
            editedAt: db.Value(now.millisecondsSinceEpoch),
          ),
        );
        await _audit(existing, ContributionAuditChange.edited, now);
        return row;
      });
      return Right(updated.toDomain());
    } on _Rejected catch (e) {
      return Left(e.failure);
    } catch (e) {
      return Left(CacheFailure('Failed to edit savings entry: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteContribution(
    String contributionId,
  ) async {
    try {
      final existing = await _activeContributionOrNull(contributionId);
      if (existing == null) return const Left(_entryNotFound);
      final now = _clock.now();
      await _dao.transaction(() async {
        // Removing a withdrawal only ever raises the balance; removing a
        // contribution must not take it below zero.
        if (existing.type == ContributionType.contribution.value) {
          final balance = await _dao.balanceForGoal(existing.goalId);
          if (balance - existing.amountMinorUnits < 0) {
            throw _Rejected(_exceedsBalance(balance));
          }
        }
        await _dao.softDeleteContribution(existing.id, now);
        await _audit(existing, ContributionAuditChange.deleted, now);
      });
      return const Right(unit);
    } on _Rejected catch (e) {
      return Left(e.failure);
    } catch (e) {
      return Left(CacheFailure('Failed to delete savings entry: $e'));
    }
  }

  // ------------------------------------------------------------------ reads

  @override
  Future<Either<Failure, SavingsGoalDetail>> getGoalDetail(
    String goalId,
  ) async {
    try {
      // One transaction: the history and the balance summed from it are
      // read from the same snapshot, so the card and the list beneath it
      // can never disagree.
      final detail = await _dao.transaction(() async {
        final goalRow = await _activeGoalOrNull(goalId);
        if (goalRow == null) return null;
        final history = await _dao.getHistoryForGoal(goalId);
        final current = await _dao.balanceForGoal(goalId);
        final goal = goalRow.toDomain();
        return SavingsGoalDetail(
          goal: goal,
          progress: _calculator.progressFor(
            goal,
            currentAmountMinorUnits: current,
            asOf: _clock.now(),
          ),
          history: [for (final row in history) row.toDomain()],
        );
      });
      if (detail == null) return const Left(_goalNotFound);
      return Right(detail);
    } catch (e) {
      return Left(CacheFailure('Failed to load savings goal: $e'));
    }
  }

  @override
  Stream<Either<Failure, SavingsGoalDetail>> watchGoalDetail(String goalId) =>
      _db.watchEither(_detailTables, () => getGoalDetail(goalId));

  @override
  Future<Either<Failure, List<SavingsGoalWithContributions>>>
  getAllGoalsWithContributions() async {
    try {
      final goals = await _dao.transaction(() async {
        final rows = await _dao.getGoals(includeArchived: true);
        return [
          for (final row in rows)
            SavingsGoalWithContributions(
              goal: row.toDomain(),
              contributions: [
                for (final entry in await _dao.getHistoryForGoal(row.id))
                  entry.toDomain(),
              ],
            ),
        ];
      });
      return Right(goals);
    } catch (e) {
      return Left(CacheFailure('Failed to load savings goals: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SavingsContributionAudit>>>
  getAllContributionAudits() async {
    try {
      final rows = await _dao.getAllAudits();
      return Right([for (final row in rows) row.toDomain()]);
    } catch (e) {
      return Left(CacheFailure('Failed to load change history: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<SavingsContributionAudit>>>
  watchContributionAuditHistory(String contributionId) =>
      _db.watchEither({_db.savingsContributionAudits}, () async {
        try {
          final rows = await _dao.getAuditsForContribution(contributionId);
          return Right<Failure, List<SavingsContributionAudit>>(
            rows.map((r) => r.toDomain()).toList(),
          );
        } catch (e) {
          return Left<Failure, List<SavingsContributionAudit>>(
            CacheFailure('Failed to load change history: $e'),
          );
        }
      });

  // --------------------------------------------------------------- helpers

  /// 021: the tables a goal's figures are read from — this feature's own
  /// two, plus 018's rates and primary currency (the contract re-emits on
  /// those; an equal re-read is swallowed by `watchEither`). A write to any
  /// of them, local or applied by sync, re-reads the open goal page.
  Set<db.TableInfo<db.Table, Object?>> get _detailTables => {
    _db.savingsGoals,
    _db.savingsContributions,
    _db.exchangeRates,
    _db.primaryCurrencySettings,
  };

  /// [amount] in [goalCurrency]'s minor units — unchanged when already in
  /// it, otherwise converted at the current rate. A missing rate is a
  /// [RatesMissingFailure] naming the entered currency; never a 1:1 guess.
  Future<Either<Failure, int>> _toGoalCurrency(
    Money amount,
    Currency goalCurrency,
  ) async {
    if (amount.currency == goalCurrency) return Right(amount.minorUnits);
    final contextResult = await _getConversionContext();
    return contextResult.flatMap(
      (context) => switch (_converter.convert(
        amount: amount,
        targetCurrency: goalCurrency,
        rates: context.rates,
      )) {
        ConversionConverted(:final value) => Right(value.minorUnits),
        ConversionRateUnavailable(:final missingRateFor) => Left(
          RatesMissingFailure([missingRateFor]),
        ),
      },
    );
  }

  /// Appends the FR-030 audit row for [before] — the entry as it was just
  /// before this edit or delete.
  Future<void> _audit(
    db.SavingsContribution before,
    ContributionAuditChange change,
    DateTime changedAt,
  ) => _dao.insertAudit(
    db.SavingsContributionAuditsCompanion.insert(
      id: _uuid.v4(),
      contributionId: before.id,
      changeType: change.value,
      previousValuesJson: jsonEncode({
        'amountMinorUnits': before.amountMinorUnits,
        'enteredAmountMinorUnits': before.enteredAmountMinorUnits,
        'enteredCurrencyCode': before.enteredCurrencyCode,
        'date': before.date,
        'note': before.note,
      }),
      changedAt: changedAt.millisecondsSinceEpoch,
    ),
  );

  Future<db.SavingsGoal?> _activeGoalOrNull(String goalId) async {
    final row = await _dao.getGoalById(goalId);
    if (row == null || row.deletedAt != null) return null;
    return row;
  }

  Future<db.SavingsContribution?> _activeContributionOrNull(String id) async {
    final row = await _dao.getContributionById(id);
    if (row == null || row.deletedAt != null) return null;
    return row;
  }

  Currency _currencyOf(db.SavingsGoal goal) =>
      Currency.fromCode(goal.currencyCode);

  /// Today's local calendar date, from the injected clock.
  DateTime _today() {
    final now = _clock.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _dateOnlyMillis(DateTime date) =>
      _dateOnly(date).millisecondsSinceEpoch;

  static int? _dateOnlyMillisOrNull(DateTime? date) =>
      date == null ? null : _dateOnlyMillis(date);

  /// A blank type is a plain custom-named goal: `null`.
  static String? _normalizedType(String? type) {
    final trimmed = type?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static String? _normalizedNote(String? note) {
    final trimmed = note?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// FR-001/FR-002, shared by create and edit.
  static ValidationFailure? _validatePlan({
    required String name,
    required int targetAmountMinorUnits,
    required int? monthlyContributionMinorUnits,
  }) {
    if (name.trim().isEmpty) {
      return const ValidationFailure('A goal needs a name');
    }
    if (targetAmountMinorUnits <= 0) {
      return const ValidationFailure('Target amount must be greater than zero');
    }
    // Absent is fine (no contribution plan); present must be positive —
    // a zero plan would never reach anything (data-model.md).
    if (monthlyContributionMinorUnits != null &&
        monthlyContributionMinorUnits <= 0) {
      return const ValidationFailure(
        'Monthly contribution must be greater than zero',
      );
    }
    return null;
  }

  /// FR-002: zero is a valid starting amount (it simply creates no entry).
  static ValidationFailure? _validateStartingAmount(int? starting) =>
      starting != null && starting < 0
      ? const ValidationFailure('Starting amount cannot be negative')
      : null;

  /// FR-003: strictly after today, compared as calendar dates.
  InvalidTargetDateFailure? _validateNewTargetDate(DateTime? targetDate) {
    if (targetDate == null) return null;
    return _dateOnly(targetDate).isAfter(_today())
        ? null
        : const InvalidTargetDateFailure('Target date must be after today');
  }

  static WithdrawalExceedsBalanceFailure _exceedsBalance(int available) =>
      WithdrawalExceedsBalanceFailure(
        'The goal balance cannot go below zero',
        availableMinorUnits: available < 0 ? 0 : available,
      );

  static const _goalNotFound = GoalNotFoundFailure('Savings goal not found');
  static const _entryNotFound = GoalNotFoundFailure('Savings entry not found');
  static const _amountNotPositive = ValidationFailure(
    'Amount must be greater than zero',
  );
}

/// Carries a typed rejection out of a `_dao.transaction`, rolling it back.
class _Rejected implements Exception {
  const _Rejected(this.failure);

  final Failure failure;
}
