import 'dart:io';

import 'package:drift/drift.dart';
export 'package:drift/drift.dart';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../sync/sync_bootstrap.dart';
import 'finance_category_seed.dart';
import 'migrations/migration_guards.dart';
import 'migrations/v7_currency_support.dart';
import 'migrations/v9_sync_support.dart';
import 'migrations/v10_merge_features.dart';
import 'migrations/v12_finance_entry_audits.dart';
import 'sync_tables.dart';

export 'sync_tables.dart';

part 'app_database.g.dart';

@TableIndex(name: 'idx_people_normalized_name', columns: {#normalizedName})
@TableIndex(
  name: 'idx_people_archived',
  columns: {#isArchived, #normalizedName},
)
class People extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get relationshipTag => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(
  name: 'idx_transactions_person_id',
  columns: {#personId, #deletedAt},
)
@TableIndex(name: 'idx_transactions_date', columns: {#date, #deletedAt})
@TableIndex(
  name: 'idx_transactions_occasion_id',
  columns: {#occasionId, #deletedAt},
)
@TableIndex(
  name: 'idx_transactions_ocr_scan_id',
  columns: {#ocrScanId, #deletedAt},
)
class MoneyTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get personId => text().references(People, #id)();
  IntColumn get amountMinorUnits => integer()();

  /// 018: ISO 4217 code of [amountMinorUnits]. Pre-018 rows are backfilled
  /// to explicit `'EGP'` by the v7 migration (FR-002).
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();
  TextColumn get direction => text()();
  TextColumn get kind => text()();
  IntColumn get date => integer()();
  TextColumn get note => text().nullable()();

  /// The [Occasions] row this contribution was recorded under (008).
  /// `NULL` for every ordinary transaction — which is every row that
  /// existed before this feature, so the migration needs no backfill.
  TextColumn get occasionId => text().nullable().references(Occasions, #id)();

  /// Whether this row counts toward the person's net balance (008 FR-018).
  /// `TRUE` for every kind but an occasion contribution recorded as
  /// non-counting, so the default keeps all pre-existing rows correct.
  BoolColumn get countsTowardBalance =>
      boolean().withDefault(const Constant(true))();

  /// How this row was created: `'manual'` or `'ocr'` (009 FR-012). The
  /// default keeps every pre-009 row correct with no backfill — they were
  /// all typed in by hand.
  TextColumn get source => text().withDefault(const Constant('manual'))();

  /// The [OcrScans] row this transaction was confirmed from (009).
  /// `NULL` for every manually entered row. Intentionally *not* declared
  /// as a `references()` FK: 009 FR-023 lets the user delete a past scan
  /// while the transactions it produced stay — a real FK would either
  /// block that delete or cascade it, and both are wrong here
  /// (data-model.md Relationships).
  TextColumn get ocrScanId => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A named social event the user tracks money around (008). Carries no
/// money of its own: its totals are always aggregated from the
/// [MoneyTransactions] rows pointing at it, never stored here
/// (008 research.md Decision 4).
@TableIndex(
  name: 'idx_occasions_idempotency_key',
  columns: {#idempotencyKey},
  unique: true,
)
@TableIndex(name: 'idx_occasions_date', columns: {#date, #deletedAt})
@TableIndex(name: 'idx_occasions_type', columns: {#type})
class Occasions extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get name => text()();

  /// Epoch millis, date-only. May be in the future (pre-planned occasions).
  IntColumn get date => integer()();

  /// A standard `OccasionType` value or free text, same open-set pattern as
  /// [People.relationshipTag] (008 research.md Decision 6).
  TextColumn get type => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A photo attached to an [Occasions] row (008 FR-017). Only a local path
/// into the app's private sandboxed storage is stored — never a remote URL,
/// and the bytes are never uploaded.
@TableIndex(
  name: 'idx_occasion_attachments_occasion_id',
  columns: {#occasionId, #deletedAt},
)
class OccasionAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get occasionId => text().references(Occasions, #id)();
  TextColumn get filePath => text()();
  IntColumn get createdAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One user-initiated paper-scanning session (009). Holds the prepared
/// image and the batch-level choices that apply to everything parsed out of
/// it, but never any money: the money only exists once the user confirms
/// the review, as ordinary [MoneyTransactions] rows (009 research.md
/// Decision 5).
@TableIndex(
  name: 'idx_ocr_scans_idempotency_key',
  columns: {#idempotencyKey},
  unique: true,
)
@TableIndex(name: 'idx_ocr_scans_status', columns: {#status, #deletedAt})
class OcrScans extends Table {
  TextColumn get id => text()();

  /// Regenerated per confirm attempt; the UNIQUE index above is what makes
  /// a double-tapped confirm a no-op rather than a second batch of
  /// transactions (009 FR-021).
  TextColumn get idempotencyKey => text()();

  /// Path into the app's own sandboxed storage. Never a remote URL — the
  /// bytes are never uploaded (009 FR-019/FR-023).
  TextColumn get sourceImagePath => text()();
  TextColumn get cropBounds => text().nullable()();
  IntColumn get rotationDegrees => integer().withDefault(const Constant(0))();

  /// `'processing'|'needsReview'|'confirmed'|'discarded'|'failed'`.
  TextColumn get status => text()();

  /// Set when the user tags the whole batch to an occasion at review time
  /// (009 FR-014), so every entry confirmed afterwards is recorded as that
  /// occasion's contribution (008).
  TextColumn get occasionId => text().nullable().references(Occasions, #id)();

  /// `'given'|'received'`, or `NULL` while the user has not chosen a batch
  /// default yet (009 FR-005).
  TextColumn get defaultDirection => text().nullable()();

  /// 018: the ISO 4217 code every amount read off this page is recorded in
  /// — the primary currency when the scan started, so review and confirm
  /// agree even if the primary currency changes in between.
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One proposed transaction parsed out of an [OcrScans] row, before the
/// user has agreed to it (009).
///
/// Persisted rather than held in memory so a half-reviewed scan survives
/// the app being backgrounded mid-review — but persisted *as a suggestion*:
/// nothing here counts toward any balance, and the only way a row in this
/// table becomes money is `confirmScanBatch` (constitution Principle X).
@TableIndex(name: 'idx_candidate_entries_scan_id', columns: {#scanId})
class CandidateEntries extends Table {
  TextColumn get id => text()();
  TextColumn get scanId => text().references(OcrScans, #id)();

  /// `'pendingReview'|'confirmed'|'discarded'`.
  TextColumn get status =>
      text().withDefault(const Constant('pendingReview'))();
  TextColumn get personName => text()();

  /// Per-field provenance, stored as a `kind`/`level` pair per field
  /// (009 data-model.md's `FieldConfidence`): `'read'|'inferred'` and
  /// `'low'|'medium'|'high'|'none'`. Kept as two columns rather than one
  /// encoded string so a future query can filter on either half.
  TextColumn get personNameConfidenceKind => text()();
  TextColumn get personNameConfidenceLevel => text()();
  TextColumn get matchedPersonId => text().nullable().references(People, #id)();
  IntColumn get amountMinorUnits => integer().nullable()();
  TextColumn get amountConfidenceKind => text()();
  TextColumn get amountConfidenceLevel => text()();
  TextColumn get direction => text().nullable()();
  TextColumn get directionConfidenceKind => text()();
  TextColumn get directionConfidenceLevel => text()();
  IntColumn get date => integer().nullable()();
  TextColumn get dateConfidenceKind => text()();
  TextColumn get dateConfidenceLevel => text()();
  TextColumn get notes => text().nullable()();

  /// The unedited recognized line this entry was parsed from, so review can
  /// compare against the page and a past scan stays explainable.
  TextColumn get rawOcrText => text()();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_audit_transaction_id', columns: {#transactionId})
class TransactionAuditEntries extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(MoneyTransactions, #id)();
  TextColumn get changeType => text()();
  TextColumn get previousValuesJson => text().nullable()();
  IntColumn get changedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 022 D2: append-only history of a [FinanceEntries] row, mirroring
/// [TransactionAuditEntries]. Written in the same transaction as each
/// create, edit, delete and restore. `changeType` is one of `created`,
/// `edited`, `deleted`, `restored`; `previousValuesJson` holds the values
/// before an edit (amount, currency, type, category, date, note) and is
/// null for every other change.
@TableIndex(name: 'idx_finance_audit_entry_id', columns: {#financeEntryId})
class FinanceEntryAudits extends Table {
  TextColumn get id => text()();
  TextColumn get financeEntryId => text().references(FinanceEntries, #id)();
  TextColumn get changeType => text()();
  TextColumn get previousValuesJson => text().nullable()();
  IntColumn get changedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A user-facing label grouping [FinanceEntries] rows. Owned entirely by
/// the `finance` feature — never joined against [People]/[MoneyTransactions]
/// (data-model.md "Relationship to existing entities", FR-023).
@TableIndex(
  name: 'idx_finance_categories_normalized_name',
  columns: {#normalizedName, #type},
)
class FinanceCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Trimmed, whitespace-collapsed, lowercased copy of [name], indexed with
  /// [type] for the FR-008 duplicate check — same precedent as
  /// [People.normalizedName].
  TextColumn get normalizedName => text()();

  /// `'income'` | `'expense'`. Immutable after creation (data-model.md).
  TextColumn get type => text()();

  /// A key into `CategoryIconRegistry`, never a raw icon codepoint or hex
  /// color (research.md Decision 10).
  TextColumn get icon => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single recorded income or expense event belonging to the user. Shaped
/// like [MoneyTransactions] (idempotency key, soft delete, edit marker) but
/// entirely independent of it — it has no `personId` and is never joined
/// against [People] (research.md Decision 1, FR-023).
@TableIndex(
  name: 'idx_finance_entries_category_id',
  columns: {#categoryId, #deletedAt},
)
@TableIndex(name: 'idx_finance_entries_date', columns: {#date, #deletedAt})
class FinanceEntries extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get categoryId => text().references(FinanceCategories, #id)();

  /// `'income'` | `'expense'`. Always equal to the referenced category's
  /// `type` (enforced in the repository, not only by the schema).
  TextColumn get type => text()();
  IntColumn get amountMinorUnits => integer()();

  /// 018: ISO 4217 code of [amountMinorUnits] (backfilled to `'EGP'`).
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();
  IntColumn get date => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A user's spending plan for one calendar month (010). Carries planned
/// figures only — every "actual" figure is derived at read time from 007's
/// `FinanceEntries` through `FinanceRepository`, never stored here, and no
/// 007 table gains a column for it (010 FR-022).
@TableIndex(
  name: 'idx_budgets_idempotency_key',
  columns: {#idempotencyKey},
  unique: true,
)
// Partial: a soft-deleted budget must not block re-creating one for the
// same month (010 data-model.md Lifecycle).
@TableIndex.sql(
  'CREATE UNIQUE INDEX idx_budgets_month ON budgets (month) '
  'WHERE deleted_at IS NULL',
)
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text()();

  /// `'YYYY-MM'` — at most one active budget per calendar month.
  TextColumn get month => text()();

  /// Optional reference figure (010 FR-003); never aggregated from income
  /// entries.
  IntColumn get expectedIncomeMinorUnits => integer().nullable()();

  /// 018: the ISO 4217 code every planned figure of this budget (and its
  /// allocations) is in — the primary currency when the budget was
  /// created, so switching the primary currency later never reinterprets a
  /// plan. Actual spend is converted into it at read time.
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One expense category's planned amount within a [Budgets] row (010).
/// Removed by hard delete: it is plan data with no financial history of its
/// own (010 research.md Decision 5).
@TableIndex(
  name: 'idx_budget_allocations_budget_category',
  columns: {#budgetId, #categoryId},
  unique: true,
)
@TableIndex(
  name: 'idx_budget_allocations_idempotency_key',
  columns: {#idempotencyKey},
  unique: true,
)
@TableIndex(name: 'idx_budget_allocations_budget_id', columns: {#budgetId})
class BudgetCategoryAllocations extends Table {
  TextColumn get id => text()();

  /// What lets a retried "add allocation" return the row it already wrote
  /// instead of tripping the `(budget_id, category_id)` duplicate guard —
  /// without it a retry and a genuine duplicate would be indistinguishable.
  TextColumn get idempotencyKey => text()();
  TextColumn get budgetId => text().references(Budgets, #id)();
  TextColumn get categoryId => text().references(FinanceCategories, #id)();

  /// `>= 0`; zero is a valid plan (010 FR-002).
  IntColumn get plannedAmountMinorUnits => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A named target the user is saving toward (011). Carries the plan only:
/// the saved amount is always aggregated from its [SavingsContributions]
/// rows, never stored here (011 research.md Decision 2).
@TableIndex(
  name: 'idx_savings_goals_idempotency_key',
  columns: {#idempotencyKey},
  unique: true,
)
class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get name => text()();

  /// A standard `SavingsGoalType` value, or `null` for a plain custom-named
  /// goal — cosmetic only, same open-set pattern as [Occasions.type].
  TextColumn get type => text().nullable()();

  /// 018: the ISO 4217 code every amount of this goal (and every
  /// [SavingsContributions.amountMinorUnits] under it) is in. Set at
  /// creation and never edited (011 FR-027).
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();

  /// `> 0` (011 FR-002).
  IntColumn get targetAmountMinorUnits => integer()();

  /// `> 0` when present; `null` means no contribution plan.
  IntColumn get monthlyContributionMinorUnits => integer().nullable()();

  /// Epoch millis, date-only.
  IntColumn get targetDate => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  /// Tombstone of a goal deleted with no history (011 FR-021), kept so the
  /// delete syncs.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One deposit or withdrawal against a [SavingsGoals] row (011). The amount
/// is always positive; [type] carries the direction (011 FR-007).
@TableIndex(
  name: 'idx_savings_contributions_idempotency_key',
  columns: {#idempotencyKey},
  unique: true,
)
@TableIndex(
  name: 'idx_savings_contributions_goal_id',
  columns: {#goalId, #deletedAt},
)
class SavingsContributions extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get goalId => text().references(SavingsGoals, #id)();

  /// `'contribution'` | `'withdrawal'`. Immutable after creation.
  TextColumn get type => text()();

  /// In the goal's currency — the only figure progress sums.
  IntColumn get amountMinorUnits => integer()();

  /// What the user typed, in [enteredCurrencyCode] (018, 011 FR-028); equal
  /// to [amountMinorUnits] when that is the goal's currency, otherwise
  /// converted once at log/edit time.
  IntColumn get enteredAmountMinorUnits => integer()();
  TextColumn get enteredCurrencyCode => text()();

  /// Epoch millis, date-only.
  IntColumn get date => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Prior values of a [SavingsContributions] row, captured on each edit or
/// delete (011 FR-030) — the same shape as [TransactionAuditEntries].
/// Append-only.
@TableIndex(
  name: 'idx_savings_contribution_audits_contribution_id',
  columns: {#contributionId},
)
class SavingsContributionAudits extends Table {
  TextColumn get id => text()();
  TextColumn get contributionId =>
      text().references(SavingsContributions, #id)();

  /// `'edited'` | `'deleted'`.
  TextColumn get changeType => text()();

  /// JSON of the row before the change.
  TextColumn get previousValuesJson => text()();
  IntColumn get changedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The user's language, theme and Liquid Glass preferences. Single-row
/// table (data-model.md): the app always reads/writes the fixed `id`
/// `'singleton'` — there is never more than one row.
class AppSettings extends Table {
  TextColumn get id => text()();
  TextColumn get languageCode => text()();
  TextColumn get themeMode => text().nullable()();

  /// 020: NULL = never set → default (data-model.md).
  BoolColumn get glassEnabled => boolean().nullable()();

  /// 020: a `GlassLevel.value`. NULL = never set → default (data-model.md).
  TextColumn get glassTransparency => text().nullable()();

  /// 020: a `GlassLevel.value`. NULL = never set → default (data-model.md).
  TextColumn get glassIntensity => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Whether the user has finished the onboarding sequence. Single-row table
/// (data-model.md): the app always reads/writes the fixed `id`
/// `'singleton'` — there is never more than one row, same pattern as
/// [AppSettings].
class OnboardingStatus extends Table {
  TextColumn get id => text()();
  BoolColumn get isComplete => boolean().withDefault(const Constant(false))();
  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 017 Proactive Insights & Reminders: the device-level notification
/// configuration. Single-row table — the app always reads/writes the fixed
/// `id` `'singleton'`, same pattern as [AppSettings]. Quiet hours are
/// minutes since local midnight, both null or both set (data-model.md).
class NotificationPreferences extends Table {
  TextColumn get id => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get budgetWarningsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get savingsCheckInsEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get quietHoursStartMinutes => integer().nullable()();
  IntColumn get quietHoursEndMinutes => integer().nullable()();
  BoolColumn get osPermissionGranted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 017: the band each notification source was in when it was last notified
/// about — the cooldown bookkeeping behind FR-015/FR-016. `sourceId` is
/// deliberately not a foreign key into 010's/011's tables (data-model.md
/// "Relationships"); a stale id is handled at read time.
///
/// Unique on `(source_type, source_id, applicable_period)`. The period is
/// indexed through `COALESCE(..., '')` because SQLite treats NULLs as
/// distinct in a unique index — without it, savings-goal rows (whose period
/// is always null) could be duplicated.
@TableIndex.sql(
  'CREATE UNIQUE INDEX idx_notification_history_source '
  'ON notification_history '
  "(source_type, source_id, COALESCE(applicable_period, ''))",
)
class NotificationHistory extends Table {
  TextColumn get id => text()();

  /// `'budgetCategory'` | `'savingsGoal'`.
  TextColumn get sourceType => text()();
  TextColumn get sourceId => text()();

  /// `'YYYY-MM'` for budget categories, null for savings goals.
  TextColumn get applicablePeriod => text().nullable()();

  /// A `ThresholdBand` name.
  TextColumn get lastNotifiedBand => text()();
  IntColumn get lastNotifiedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 018 Multi-Currency: the device-wide primary currency. Single-row table —
/// the app always reads/writes the fixed `id` `'singleton'`; an absent row
/// means the EGP default (FR-005).
class PrimaryCurrencySettings extends Table {
  TextColumn get id => text()();
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 018: user-maintained manual exchange rates — "1 [currencyCode] =
/// [rateMicros] / 10^6 [relativeToCurrencyCode]". Stored as a scaled integer,
/// never REAL (constitution Principle VIII). Unique per currency pair, so an
/// edit upserts rather than duplicating (data-model.md).
@TableIndex(
  name: 'idx_exchange_rates_pair',
  columns: {#currencyCode, #relativeToCurrencyCode},
  unique: true,
)
class ExchangeRates extends Table {
  TextColumn get id => text()();
  TextColumn get currencyCode => text()();
  TextColumn get relativeToCurrencyCode => text()();
  IntColumn get rateMicros => integer()();
  IntColumn get lastUpdatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The single, continuous assistant conversation (014). At most one row per
/// installation, created lazily on first use.
///
/// Named `Ai…` rather than `AI…` so drift derives the SQL name
/// `ai_conversations` (not `a_i_conversations`); `@DataClassName` keeps the
/// generated row class from shadowing the domain `AIConversation` entity.
@DataClassName('AiConversationRow')
class AiConversations extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastActivityAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One question or answer within [AiConversations] (014). Owns no money and
/// references no other feature's table (FR-023).
@DataClassName('AiMessageRow')
@TableIndex(
  name: 'idx_ai_messages_conversation_created',
  columns: {#conversationId, #createdAt},
)
class AiMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text().references(AiConversations, #id)();

  /// `'user'|'assistant'`.
  TextColumn get sender => text()();
  TextColumn get content => text()();

  /// `'sent'|'answered'|'failed'`.
  TextColumn get status => text()();

  /// Set only when [status] is `'failed'`: `'invalidApiKey'|'rateLimited'|
  /// 'network'|'providerError'|'unrecognizedResponse'`.
  TextColumn get failureReason => text().nullable()();

  /// Which tool/use-case pairs grounded an assistant answer's figures.
  TextColumn get groundingRefsJson => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The assistant's configuration (014). Single-row table under the fixed
/// `id` `'singleton'`, same pattern as [AppSettings]. Holds only non-secret
/// metadata — the API key itself lives exclusively in secure storage
/// (014 research.md Decision 3), never here, not even as a hash.
@DataClassName('AiSettingsRow')
class AiSettings extends Table {
  TextColumn get id => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get providerId => text().nullable()();
  BoolColumn get hasStoredCredential =>
      boolean().withDefault(const Constant(false))();
  IntColumn get consentAcceptedAt => integer().nullable()();
  IntColumn get updatedAt => integer()();

  /// The `observationKey` of the last proactive observation surfaced in the
  /// conversation (User Story 7 AC3 / FR-020 no-repeat rule), or `null`
  /// when none was ever surfaced. Not user data in its own right — only a
  /// de-duplication marker; written only after the observation was
  /// successfully narrated and persisted.
  TextColumn get lastObservationKey => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The app's single local SQLite database. Opened against a file in the
/// app's sandboxed documents directory (OS-level storage protection —
/// research.md Decision 11), never against a network resource: this
/// feature is fully local-only.
@DriftDatabase(
  tables: [
    People,
    MoneyTransactions,
    TransactionAuditEntries,
    AppSettings,
    OnboardingStatus,
    FinanceCategories,
    FinanceEntries,
    NotificationPreferences,
    NotificationHistory,
    PrimaryCurrencySettings,
    ExchangeRates,
    // 021 Offline-First Cloud Sync (sync_tables.dart).
    SyncOutboxEntries,
    SyncRecordMeta,
    SyncConflicts,
    ConflictResolutions,
    SyncState,
    Occasions,
    OccasionAttachments,
    OcrScans,
    CandidateEntries,
    Budgets,
    BudgetCategoryAllocations,
    AiConversations,
    AiMessages,
    AiSettings,
    SavingsGoals,
    SavingsContributions,
    SavingsContributionAudits,
    FinanceEntryAudits,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [syncBootstrap] queues the pre-existing data for upload once, in
  /// `beforeOpen` (021 T063). The app always passes it; tests that are not
  /// about sync leave it out.
  AppDatabase({SyncBootstrap? syncBootstrap})
    : _syncBootstrap = syncBootstrap,
      super(_openConnection());

  AppDatabase.forTesting(super.executor, {SyncBootstrap? syncBootstrap})
    : _syncBootstrap = syncBootstrap;

  final SyncBootstrap? _syncBootstrap;

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(appSettings);
      }
      if (from < 3) {
        await m.addColumn(appSettings, appSettings.themeMode);
      }
      if (from < 4) {
        await m.createTable(onboardingStatus);
      }
      if (from < 5) {
        await m.createTable(financeCategories);
        await m.createTable(financeEntries);
      }
      // A pre-merge feature-line install (008/009/010/014) also reports
      // 6..9 but has none of main's v6..v9 schema, all of which is purely
      // additive over v5 — so it replays main's steps from v5.
      final mainFrom =
          from >= 6 && from <= 9 && await isPreMergeFeatureLine(this)
          ? 5
          : from;
      if (mainFrom < 6) {
        // 017: purely additive — no existing table is touched.
        await m.createTable(notificationPreferences);
        await m.createTable(notificationHistory);
        await m.createIndex(idxNotificationHistorySource);
      }
      if (mainFrom < 7) {
        await migrateToCurrencySupport(this, m);
      }
      if (mainFrom < 8) {
        // 020: purely additive and nullable — no backfill, so existing rows
        // read as "never set" and resolve to the glass defaults.
        await m.addColumn(appSettings, appSettings.glassEnabled);
        await m.addColumn(appSettings, appSettings.glassTransparency);
        await m.addColumn(appSettings, appSettings.glassIntensity);
      }
      if (mainFrom < 9) {
        // 021: the local sync tables, two business indexes and deterministic
        // exchange-rate ids. No reads (data-model.md §3).
        await migrateToSyncSupport(this, m);
      }
      if (from < 10) {
        // The 008/009/010/014 line and the 016-021 line both shipped a
        // "v6..v9" of their own before they were merged, so this step
        // reconciles instead of assuming (v10_merge_features.dart).
        await migrateToMergedFeatures(this, m);
      }
      if (from < 11) {
        // 011 Savings Goals: purely additive — three new tables and their
        // indexes, no existing table touched. One transaction, so a failure
        // leaves the file at v10 and the next open retries cleanly. Every object
        // is guarded, so a file that got past this step without advancing
        // its version also re-opens.
        await transaction(() async {
          await ensureTable(this, m, savingsGoals);
          await ensureTable(this, m, savingsContributions);
          await ensureTable(this, m, savingsContributionAudits);
          await ensureIndex(this, m, idxSavingsGoalsIdempotencyKey);
          await ensureIndex(this, m, idxSavingsContributionsIdempotencyKey);
          await ensureIndex(this, m, idxSavingsContributionsGoalId);
          await ensureIndex(
            this,
            m,
            idxSavingsContributionAuditsContributionId,
          );
        });
      }
      if (from < 12) {
        // 022 D2 + B1 repair: purely additive (finance_entry_audits and
        // sync_state.b1_repull_done), no existing row touched
        // (v12_finance_entry_audits.dart).
        await migrateToFinanceEntryAudits(this, m);
      }
    },
    beforeOpen: (details) async {
      // The starter categories are seeded here rather than inside
      // `onUpgrade` because seeding reads the table first (to stay
      // idempotent), and a read issued while a migration is still in
      // flight rolls that migration back — taking the two `createTable`
      // calls above with it. `beforeOpen` runs after the migration has
      // committed, and covers a fresh install (`onCreate`, which never
      // reaches the `from < 5` branch) in the same step.
      //
      // Unguarded on purpose: `seedDefaultFinanceCategories` returns after
      // a single `LIMIT 1` read once the set is present, so running it on
      // every open costs almost nothing and makes the starter set
      // self-healing if an earlier seed was interrupted.
      await seedDefaultFinanceCategories(this);
      // 021: after the seed, so pristine starter categories are recognized
      // and skipped. Guarded by `sync_state.bootstrap_enqueued` alone, set
      // in the same transaction (data-model.md §3).
      await _syncBootstrap?.enqueueExistingDataIfNeeded(this);
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(documentsDir.path, 'daftary.sqlite'));
    return NativeDatabase.createInBackground(dbFile);
  });
}
