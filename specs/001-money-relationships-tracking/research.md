# Phase 0 Research: Money Relationships Tracking

All Technical Context unknowns from `plan.md` are resolved below. No `NEEDS CLARIFICATION` markers remain — the spec's own Clarifications session (single-device/local-only, archived-balance inclusion, transaction-kind immutability, duplicate-name match rule) already removed the highest-impact product ambiguities; this document resolves the remaining *technical* decisions needed to start Phase 1 design.

## 1. Local persistence: Drift (SQLite) vs. Isar vs. Hive vs. sqflite

**Decision**: `drift` (type-safe SQL over SQLite), with `sqlite3_flutter_libs` for the native library and `path_provider` for the DB file location.

**Rationale**: The domain is inherently relational (`Person` 1—* `MoneyTransaction`) and the hardest correctness requirement (SC-002: balance always exactly matches the sum of history, verified against 50+ transactions/person; SC-005: correct totals over 500 people/10k transactions in <2s) is best satisfied by `SUM()`/`GROUP BY` aggregate queries the database engine already optimizes, rather than loading all rows into Dart to sum in memory. Drift also gives compile-time-checked queries, straightforward schema migrations, and an in-memory/test DB mode that makes repository-layer tests (constitution Principle XVI) fast and real (no hand-rolled fakes duplicating SQL logic). A unique index is the natural, atomic way to enforce the idempotency-key constraint from FR-020/SC-006.

**Alternatives considered**:
- **Isar**: Very fast NoSQL object DB with good Flutter ergonomics, but aggregate "sum where personId=X and not deleted" queries and multi-field uniqueness constraints are less natural than in SQL, and its Dart-side query composition would push more of the "deterministic financial calculation" burden (Principle VIII) into hand-written Dart code, which is easier to get subtly wrong at scale.
- **Hive**: Excellent for simple key-value/object storage, but no query engine — computing overview totals across 10k transactions would mean manual iteration, working against the SC-005 performance target and against keeping balance computation provably correct.
- **sqflite (raw SQL strings)**: Same relational strengths as Drift, but no compile-time query verification; higher risk of a hand-written SQL bug silently corrupting a financial total, which the constitution's Financial Domain Override treats as unacceptable.

## 2. Error/result flow: fpdart vs. dartz vs. hand-rolled Result

**Decision**: `fpdart`'s `Either<Failure, T>` for every repository and use-case return type.

**Rationale**: Constitution Principle VII mandates a typed result mechanism instead of exceptions-as-control-flow. `fpdart` is actively maintained (dartz is not), has good `flutter_bloc` community precedent, and its `Either` composes cleanly with `Cubit` state transitions (`fold` into loading/success/failure states).

**Alternatives considered**: `dartz` (unmaintained, sunk-cost risk); a hand-rolled sealed `Result<T>` class (viable and zero-dependency, but reinvents well-trodden ground for no real benefit here — rejected to keep the codebase smaller).

## 3. Dependency injection: get_it (+injectable) vs. Riverpod-as-DI vs. manual

**Decision**: `get_it` as the service locator, with `injectable` code generation to keep registration boilerplate low as features grow.

**Rationale**: Constitution Principle XIV requires DI everywhere but is state-management-agnostic on the *mechanism*; Principle III already mandates `flutter_bloc` for state, so introducing Riverpod purely as a DI layer would mean two competing patterns for "getting things into a widget" with no added benefit. `get_it` is the standard, lightweight pairing with `flutter_bloc` in the Flutter community and keeps Cubits trivially constructible in tests via manual registration overrides.

**Alternatives considered**: Riverpod (would also solve DI but overlaps/competes with the mandated BLoC state layer — rejected per Principle III's "second state-management paradigm... PROHIBITED without documented justification," and none exists here); pure manual constructor wiring in `main.dart` (works at this feature's size but scales poorly once `occasions`, `expenses`, `budgets` land in future specs — rejected as short-sighted given the brief's roadmap).

## 4. Money representation and arithmetic

**Decision**: Store and compute every amount as a signed 64-bit integer count of the smallest EGP subunit (piastres: 1 EGP = 100 piastres), wrapped in a small `Money` value type in `core/money/` that only exposes integer-safe operations (add, subtract, negate, compare) and formats to/from decimal EGP strings at the UI boundary only.

**Rationale**: Directly satisfies constitution Principle VIII ("no careless floating-point arithmetic") and the spec's own edge case/FR-006 requirement of zero rounding drift across repeated calculations, including decimal input like 150.50 EGP and amounts up to 5,000,000 EGP (well within `int64` range even in piastres: ~9.2 × 10^16 EGP max).

**Alternatives considered**: `double`/floating point (rejected outright — accumulates rounding error, explicitly prohibited); a `decimal`/`BigDecimal`-style package (technically safe, but adds a dependency and API surface for a problem integer minor units already solve simply and exactly at this feature's currency-precision requirements).

## 5. Idempotent save / duplicate-transaction protection

**Decision**: The Presentation layer generates a UUID **idempotency key** the moment the user taps "Save" (before the async use-case call resolves), disables the save control immediately (`buildWhen`-gated loading state), and the `AddTransaction`/`RecordRepayment` use case passes that key through to a `drift` `INSERT` guarded by a `UNIQUE` index on an `idempotency_key` column; a duplicate insert is caught and treated as "already saved, return the existing record" rather than an error.

**Rationale**: Directly implements FR-020/SC-006 ("a single user-initiated save action... never results in more than one recorded transaction") and Principle XI's idempotency-key guidance, entirely client-side since this feature has no network/backend layer to reconcile against (see Decision 7).

**Alternatives considered**: UI-only double-tap debouncing (insufficient alone — doesn't protect against a retried save after a process restart, which the spec's edge cases explicitly call out); relying on a "check if an identical transaction already exists" heuristic (rejected — a real second same-amount/same-day transaction against the same person is a legitimate, distinct event, so heuristic dedup would silently drop valid data).

## 6. Transaction edit/deletion traceability

**Decision**: `MoneyTransaction` rows carry `created_at`, `edited_at` (nullable), and `deleted_at` (nullable, soft-delete tombstone) columns. A companion append-only `TransactionAuditEntry` table records one row per create/edit/delete with a snapshot of the changed fields and a timestamp. Deletion is presented to the user as permanent and irreversible (no restore UI, per FR-016's explicit "cannot be undone" confirmation) — the tombstone exists purely to satisfy the constitution's traceability requirement, not to offer undo.

**Rationale**: Satisfies FR-015 ("visibly marked as an edited record"), SC-007 ("every edit or deletion... remains traceable... zero silent, untraceable modifications"), and the constitution's Financial Domain Override ("every financial mutation MUST be traceable via IDs, timestamps, audit metadata, and transaction history") without contradicting the spec's "cannot be undone" UX promise — those are independent concerns (data-layer auditability vs. UI-level undo).

**Alternatives considered**: Hard delete with no audit trail (simpler, but violates the constitution's traceability mandate outright — rejected); full event-sourcing of every field mutation (more powerful than this feature needs — rejected as over-engineering for a first-pillar feature).

## 7. Offline/sync model

**Decision**: This feature has no network layer at all. All reads/writes are local `drift` transactions. FR-021's "offline" and "reconciled" language, and the sync-conflict edge case, are satisfied trivially: the app is always effectively "offline" from a network standpoint (per the spec's Clarifications: single-device, local-only, no login/account/cloud sync in scope), and the only concurrency to guard against is two concurrent app processes/instances on the same device — handled by SQLite's own transactional isolation plus the idempotency-key constraint from Decision 5, not a network sync/reconciliation subsystem.

**Rationale**: Matches the spec's Clarifications exactly; building a network sync/reconciliation layer for a feature explicitly scoped as local-only would be unjustified complexity the constitution's "Do NOT over-engineer" / Architectural Decision Rule would flag.

**Alternatives considered**: A local "pending sync queue" scaffolded now for a future backend (rejected as speculative/premature — no future spec has yet defined the sync contract this would target; easy to add a `sync_status` column later without a migration disaster since Drift migrations are already part of the architecture).

## 8. Possible-duplicate person name matching (implements clarified FR-003 rule)

**Decision**: Implement the clarified case/whitespace-insensitive "exact, prefix, or contains" match as a pure Dart domain function (`FindPossibleDuplicatePerson` use case) operating on a normalized (lowercased, whitespace-collapsed) name index maintained in the `people` Drift table, avoiding any fuzzy-matching library.

**Rationale**: The clarification session already pinned the exact rule; no fuzzy/edit-distance library is needed, keeping this deterministic, fast (a simple `LIKE`-style query or in-memory scan is sufficient at a 500-person scale), and trivially unit-testable.

**Alternatives considered**: A fuzzy-matching package (e.g. Levenshtein-based) — explicitly rejected by the user during clarification in favor of the simpler prefix/contains rule.

## 9. Localization and Arabic-Indic numerals

**Decision**: `flutter_localizations` + `gen_l10n` (ARB-driven, generates `AppLocalizations`) for all user-facing strings (`ar`, `en`); `intl`'s `NumberFormat.currency` for EGP display formatting; a small `core/money/numeral_parser.dart` utility that maps Arabic-Indic digits (٠-٩) to Western digits (0-9) before parsing any user-entered amount, satisfying FR-023.

**Rationale**: `gen_l10n` is Flutter's first-party, constitution-endorsed (Principle XIII explicitly names it) localization mechanism, keeping strings out of source and RTL/LTR handled by Flutter's `Directionality` machinery. Digit normalization is a small, deterministic, easily-unit-tested pure function — no need for a third-party numerals package.

**Alternatives considered**: `easy_localization` or similar third-party i18n packages (unnecessary — `gen_l10n` is already the constitution-named standard and avoids an extra dependency).

## 10. Testing stack

**Decision**: `flutter_test` (unit + widget), `bloc_test` + `mocktail` (Cubit unit tests against mocked use cases/repositories), `integration_test` (device/simulator end-to-end flows), Drift's built-in in-memory `NativeDatabase.memory()` for fast, real-SQL repository tests.

**Rationale**: This is the de facto standard pairing for `flutter_bloc` projects and satisfies constitution Principle XVI's testability requirements at every layer (use cases, repositories, Cubits, widgets, critical end-to-end flows) without introducing redundant tooling.

**Alternatives considered**: `mockito` instead of `mocktail` (works but requires `build_runner` codegen for every mock; `mocktail` needs none, reducing build friction — rejected in favor of `mocktail`); golden tests (not required by the spec or constitution for this feature's visuals — deferred, not rejected outright, to be added if/when the design system stabilizes).
