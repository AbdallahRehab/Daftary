import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/sync/local/sync_outbox.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../domain/entities/savings_contribution.dart' show ContributionType;
import '../sync/savings_contribution_audit_sync_mapper.dart';
import '../sync/savings_contribution_sync_mapper.dart';
import '../sync/savings_goal_sync_mapper.dart';

/// Direct `drift` access to `savings_goals`, `savings_contributions` and
/// `savings_contribution_audits` (011). Business rules — validation, the
/// withdrawal-balance check, archived goals, conversion — live in the
/// repository; this class only reads and writes rows.
///
/// 023/021: every write records its change to the [SyncOutbox] in the same
/// transaction. All three entity types are upsert-only on the wire: a goal
/// tombstone and a contribution soft delete travel as upserts carrying
/// `deleted_at`, and audits are append-only — `recordDelete` is never used
/// here (the server rejects a delete op for these types).
@injectable
class SavingsDao {
  SavingsDao(
    this._db,
    this._outbox,
    this._goalMapper,
    this._contributionMapper,
    this._auditMapper,
  );

  final db.AppDatabase _db;
  final SyncOutbox _outbox;
  final SavingsGoalSyncMapper _goalMapper;
  final SavingsContributionSyncMapper _contributionMapper;
  final SavingsContributionAuditSyncMapper _auditMapper;

  Future<db.SavingsGoal> _recordGoal(String id) async {
    final row = (await getGoalById(id))!;
    await _outbox.recordUpsert(
      SyncEntityType.savingsGoal,
      id,
      _goalMapper.toWire(row),
    );
    return row;
  }

  Future<db.SavingsContribution> _recordContribution(String id) async {
    final row = (await getContributionById(id))!;
    await _outbox.recordUpsert(
      SyncEntityType.savingsContribution,
      id,
      _contributionMapper.toWire(row),
    );
    return row;
  }

  /// Runs [action] in one DB transaction — nested DAO writes join it, so a
  /// change, its audit row and every outbox row commit or roll back
  /// together.
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // ------------------------------------------------------------------ goals

  /// Inserts [goal] and, when given, its [initialContribution] (the
  /// "starting amount", research.md Decision 3) in one transaction. If a
  /// goal with the same `idempotency_key` already exists (FR-022), nothing
  /// is written and the persisted row is returned.
  Future<db.SavingsGoal> insertGoalIdempotent(
    db.SavingsGoalsCompanion goal, {
    db.SavingsContributionsCompanion? initialContribution,
  }) {
    final idempotencyKey = goal.idempotencyKey.value;
    return _db.transaction(() async {
      final existing = await getGoalByIdempotencyKey(idempotencyKey);
      if (existing != null) return existing;
      await _db.into(_db.savingsGoals).insert(goal);
      final inserted = await _recordGoal(goal.id.value);
      if (initialContribution != null) {
        await insertContributionIdempotent(initialContribution);
      }
      return inserted;
    });
  }

  Future<db.SavingsGoal?> getGoalByIdempotencyKey(String key) => (_db.select(
    _db.savingsGoals,
  )..where((g) => g.idempotencyKey.equals(key))).getSingleOrNull();

  /// Includes tombstoned rows — the repository decides what a deleted goal
  /// means for each caller.
  Future<db.SavingsGoal?> getGoalById(String id) => (_db.select(
    _db.savingsGoals,
  )..where((g) => g.id.equals(id))).getSingleOrNull();

  /// Every non-deleted goal — archived ones only with [includeArchived] —
  /// oldest first. For the overview (US4).
  Future<List<db.SavingsGoal>> getGoals({bool includeArchived = false}) {
    return (_db.select(_db.savingsGoals)
          ..where(
            (g) => includeArchived
                ? g.deletedAt.isNull()
                : g.deletedAt.isNull() & g.isArchived.equals(false),
          )
          ..orderBy([(g) => db.OrderingTerm(expression: g.createdAt)]))
        .get();
  }

  /// Writes [companion] over goal [id] — an edit, archive, restore or
  /// tombstone — and queues the resulting row.
  Future<db.SavingsGoal> updateGoal(
    String id,
    db.SavingsGoalsCompanion companion,
  ) {
    return _db.transaction(() async {
      await (_db.update(
        _db.savingsGoals,
      )..where((g) => g.id.equals(id))).write(companion);
      return _recordGoal(id);
    });
  }

  // ---------------------------------------------------------- contributions

  /// Same idempotent-insert shape as [insertGoalIdempotent]: a retried key
  /// returns the existing row and queues nothing.
  Future<db.SavingsContribution> insertContributionIdempotent(
    db.SavingsContributionsCompanion companion,
  ) {
    final idempotencyKey = companion.idempotencyKey.value;
    return _db.transaction(() async {
      final existing = await getContributionByIdempotencyKey(idempotencyKey);
      if (existing != null) return existing;
      await _db.into(_db.savingsContributions).insert(companion);
      return _recordContribution(companion.id.value);
    });
  }

  Future<db.SavingsContribution?> getContributionByIdempotencyKey(String key) =>
      (_db.select(
        _db.savingsContributions,
      )..where((c) => c.idempotencyKey.equals(key))).getSingleOrNull();

  /// Includes soft-deleted rows.
  Future<db.SavingsContribution?> getContributionById(String id) => (_db.select(
    _db.savingsContributions,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  /// [goalId]'s non-deleted entries in chronological order: by entry date,
  /// then creation time for entries on the same date (FR-008).
  Future<List<db.SavingsContribution>> getHistoryForGoal(String goalId) {
    return (_db.select(_db.savingsContributions)
          ..where((c) => c.goalId.equals(goalId) & c.deletedAt.isNull())
          ..orderBy([
            (c) => db.OrderingTerm(expression: c.date),
            (c) => db.OrderingTerm(expression: c.createdAt),
          ]))
        .get();
  }

  /// The goal's current balance in its own currency: Σ contributions −
  /// Σ withdrawals over its non-deleted entries (research.md Decision 2) —
  /// one SQL aggregate, never a stored figure. [excludingContributionId]
  /// leaves one entry out, for re-validating an edit against the balance
  /// without that entry's own current value (data-model.md).
  Future<int> balanceForGoal(
    String goalId, {
    String? excludingContributionId,
  }) async {
    final row = await _db
        .customSelect(
          '''
          SELECT COALESCE(SUM(CASE WHEN type = ?
                                   THEN -amount_minor_units
                                   ELSE amount_minor_units END), 0) AS balance
          FROM savings_contributions
          WHERE goal_id = ?
            AND deleted_at IS NULL
            AND (? IS NULL OR id <> ?)
          ''',
          variables: [
            db.Variable<String>(ContributionType.withdrawal.value),
            db.Variable<String>(goalId),
            db.Variable<String>(excludingContributionId),
            db.Variable<String>(excludingContributionId),
          ],
          readsFrom: {_db.savingsContributions},
        )
        .getSingle();
    return row.read<int>('balance');
  }

  /// Every goal's current balance, keyed by goal id — the same sum as
  /// [balanceForGoal], for all goals in one grouped aggregate, so the
  /// overview costs one query however many goals there are. A goal with no
  /// live entries is absent (balance `0`).
  Future<Map<String, int>> balancesByGoal() async {
    final rows = await _db
        .customSelect(
          '''
          SELECT goal_id,
                 SUM(CASE WHEN type = ?
                          THEN -amount_minor_units
                          ELSE amount_minor_units END) AS balance
          FROM savings_contributions
          WHERE deleted_at IS NULL
          GROUP BY goal_id
          ''',
          variables: [db.Variable<String>(ContributionType.withdrawal.value)],
          readsFrom: {_db.savingsContributions},
        )
        .get();
    return {
      for (final row in rows)
        row.read<String>('goal_id'): row.read<int>('balance'),
    };
  }

  /// Whether [goalId] has any entry at all — soft-deleted ones included —
  /// which is what blocks deleting the goal (FR-021). A `LIMIT 1` existence
  /// check.
  Future<bool> hasAnyContribution(String goalId) async {
    final row =
        await (_db.select(_db.savingsContributions)
              ..where((c) => c.goalId.equals(goalId))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<db.SavingsContribution> updateContribution(
    String id,
    db.SavingsContributionsCompanion companion,
  ) {
    return _db.transaction(() async {
      await (_db.update(
        _db.savingsContributions,
      )..where((c) => c.id.equals(id))).write(companion);
      return _recordContribution(id);
    });
  }

  /// A soft delete uploads as an upsert carrying `deleted_at`.
  Future<void> softDeleteContribution(String id, DateTime deletedAt) {
    return _db.transaction(() async {
      await (_db.update(
        _db.savingsContributions,
      )..where((c) => c.id.equals(id))).write(
        db.SavingsContributionsCompanion(
          deletedAt: db.Value(deletedAt.millisecondsSinceEpoch),
        ),
      );
      await _recordContribution(id);
    });
  }

  // ----------------------------------------------------------------- audits

  /// Appends one audit row (FR-030) and queues it — one upsert, never
  /// edited or deleted afterwards.
  Future<void> insertAudit(db.SavingsContributionAuditsCompanion companion) {
    return _db.transaction(() async {
      await _db.into(_db.savingsContributionAudits).insert(companion);
      final id = companion.id.value;
      final row = await (_db.select(
        _db.savingsContributionAudits,
      )..where((a) => a.id.equals(id))).getSingle();
      await _outbox.recordUpsert(
        SyncEntityType.savingsContributionAudit,
        id,
        _auditMapper.toWire(row),
      );
    });
  }

  /// 022 D1: every audit row of every contribution, oldest first.
  Future<List<db.SavingsContributionAudit>> getAllAudits() {
    return (_db.select(_db.savingsContributionAudits)..orderBy([
          (a) => db.OrderingTerm(expression: a.changedAt),
          (a) => db.OrderingTerm(expression: a.id),
        ]))
        .get();
  }

  /// Every audit row of [contributionId], oldest first (ties by id).
  Future<List<db.SavingsContributionAudit>> getAuditsForContribution(
    String contributionId,
  ) {
    return (_db.select(_db.savingsContributionAudits)
          ..where((a) => a.contributionId.equals(contributionId))
          ..orderBy([
            (a) => db.OrderingTerm(expression: a.changedAt),
            (a) => db.OrderingTerm(expression: a.id),
          ]))
        .get();
  }
}
