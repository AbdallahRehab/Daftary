# Phase 1 Data Model: Income & Expense Tracking

Derived from the spec's Key Entities section and the Phase 0 research decisions (separate table from `MoneyTransactions`, archive-vs-delete category removal, integer-minor-unit money, soft-delete + undo). All money fields are integer minor units (piastres, reusing `core/money/Money`); all timestamps are UTC `DateTime`.

## Entity: Category

A user-facing label for grouping finance entries; the shared vocabulary Budgets (V2) will also read from.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key |
| `name` | `String` | Required, non-empty after trim. Normalized (lowercased, whitespace-collapsed) copy indexed for the duplicate check (FR-008) |
| `type` | enum `income` \| `expense` | Required, immutable after creation — a category serves one or the other, never both |
| `icon` | `String` | A key into the curated `CategoryIconRegistry` (research.md Decision 10), not a raw icon codepoint or color |
| `isDefault` | `bool` | `true` for the seeded starter set (research.md Decision 3); editable/archivable exactly like a custom category — "default" carries no special protection |
| `isArchived` | `bool` | Default `false`. `true` hides it from the entry-creation picker (FR-011) while preserving it for existing entries |
| `createdAt` | `DateTime` | Set once on creation (or on seed-migration insert) |
| `updatedAt` | `DateTime` | Updated on every rename/re-icon/archive |

**Validation rules**:
- `name` MUST be non-empty (trimmed).
- Before insert, the repository runs the FR-008 duplicate check: does any existing **active** category of the same `type` have an identical normalized name? If so, reject with `DuplicateCategoryFailure` (research.md Decision 5).
- `type` cannot change after creation (would silently reclassify every entry that references it — not offered as an edit operation).

**Removal semantics** (FR-010, research.md Decision 4): `RemoveCategory(id)` counts referencing `FinanceEntries` rows (including soft-deleted ones, since a restored/undone entry must still resolve its category). Zero references → hard `DELETE`. One or more → `isArchived = true`.

**Lifecycle**: `active → archived` (one-way for a used category — no "unarchive" UI is specified; re-creating the same name after archiving is explicitly allowed, research.md Decision 5). A never-used category's lifecycle is `active → deleted` (hard).

**Seed data** (research.md Decision 3), inserted once during the v5 migration, `isDefault = true`:
- Expense: Rent, Electricity, Water, Internet, Phone, Groceries, Transportation, Fuel, Medical, Education, Entertainment, Shopping, Restaurants, Subscriptions, Family, Other
- Income: Salary, Freelance, Business, Bonus, Gift, Other Income

## Entity: FinanceEntry

A single recorded income or expense event belonging to the user (never to another `Person`). Structurally parallel to, but entirely independent from, `MoneyTransaction` (research.md Decision 1).

| Field | Type | Rules |
|---|---|---|
| `id` | `String` (UUID) | Primary key |
| `idempotencyKey` | `String` (UUID) | **Unique index.** Client-generated once per save action; a retried insert with the same key is a no-op returning the existing row (FR-021) |
| `categoryId` | `String` (FK → `Category.id`) | Required — every entry belongs to exactly one category (FR-003: no uncategorized entries) |
| `type` | enum `income` \| `expense` | Required. MUST match the referenced category's `type` (enforced at the use-case level, not just the DB) — an income entry cannot point at an expense category or vice versa |
| `amountMinorUnits` | `int` | Required, `> 0` (FR-003: zero/negative rejected) |
| `date` | `DateTime` (date-only) | Defaults to today, user-editable; future dates accepted (FR-001, Edge Cases) |
| `note` | `String?` | Optional (FR-001) |
| `createdAt` | `DateTime` | Set once on creation |
| `editedAt` | `DateTime?` | Set on every field edit (amount/category/date/note); `null` means never edited (FR-019) |
| `deletedAt` | `DateTime?` | Soft-delete tombstone; `null` means active. Set immediately on delete, un-set by `RestoreFinanceEntry` within the undo window (research.md Decision 8) |

**Validation rules**:
- `amountMinorUnits > 0` (FR-003).
- `categoryId` must reference an existing `Category` — active *or* archived (editing an entry that already uses an archived category must keep working, FR-011).
- `type` must equal the referenced category's `type` at write time.
- Decimal input converted to exact integer piastres at the input boundary — no floating-point intermediate step (FR-004, mirrors `MoneyTransaction`).
- Amount ceiling reuses whatever maximum `MoneyTransaction.amountMinorUnits` already enforces (spec Assumptions — consistency over inventing a new limit).

**State transitions**: `created → [edited]* → [deleted → restored]?`. A restored entry returns to normal `[edited]*` state; `deletedAt` is simply `null` again with no separate "was once deleted" marker retained (the `TransactionAuditEntry`-equivalent below is what preserves that history if ever needed).

**Derived (not stored)**: `FinanceSummary` (total income, total expenses, net, for a period) and `CategoryBreakdownItem` (per-category total + share, ordered descending) — both computed on demand by SQL aggregate over non-deleted rows (research.md Decision 6), never cached as mutable columns.

## Relationship to existing entities

- **`Person` / `MoneyTransaction`**: No relationship. `FinanceEntry` has no `personId` and is never joined against `People`/`MoneyTransactions` in any query this feature defines (FR-023). This is a deliberate architectural boundary, not an oversight — see research.md Decision 1.
- **`Category`**: `FinanceEntry.categoryId → Category.id`, required, many-to-one.
- **Future features**: Budgets (V2) is specified to read `Category` (to scope a budget to one or more expense categories) and aggregate `FinanceEntries` (to compute current spend) through this feature's `FinanceRepository`/`CategoryRepository` contracts — it must not introduce a second categories table or a second spend-aggregation query path.

## Schema (drift, additive only)

```dart
class FinanceCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  TextColumn get type => text()();            // 'income' | 'expense'
  TextColumn get icon => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class FinanceEntries extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get categoryId => text().references(FinanceCategories, #id)();
  TextColumn get type => text()();            // 'income' | 'expense'
  IntColumn get amountMinorUnits => integer()();
  IntColumn get date => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

Indexes: `idx_finance_categories_normalized_name` on `(normalizedName, type)` (duplicate check, research.md Decision 5); `idx_finance_entries_category_id` on `(categoryId, deletedAt)`; `idx_finance_entries_date` on `(date, deletedAt)` (period queries, research.md Decision 6).

`AppDatabase.schemaVersion` 4 → 5; `onUpgrade` gains `if (from < 5) { ... }` creating both tables and inserting the seed rows from the Category "Seed data" section above, in one migration step.
