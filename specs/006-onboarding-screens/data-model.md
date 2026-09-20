# Phase 1 Data Model: Onboarding / Intro Screens

## Entity: Onboarding Completion State

The spec's Key Entity "a persisted flag/record indicating whether the current user has completed or skipped onboarding." Persisted as a new single-row Drift table, `OnboardingStatus`, following the exact shape of feature 002's `AppSettings` table (single fixed-id row, no history table).

### Drift table

```dart
/// Whether the current install has finished (or skipped) onboarding.
/// Single-row table (like AppSettings): the app always reads/writes the
/// fixed id 'singleton'.
class OnboardingStatus extends Table {
  TextColumn get id => text()();
  BoolColumn get isComplete => boolean().withDefault(const Constant(false))();
  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `TEXT` (PK) | Always the fixed constant `'singleton'` — never more than one row, same pattern as `AppSettings`. |
| `isComplete` | `BOOLEAN` | `true` once the user has finished the last screen, explicitly skipped, or the app auto-detected pre-existing data (FR-010a). Defaults `false`. |
| `completedAt` | `INTEGER` (epoch ms), nullable | Set once, at the moment `isComplete` is written `true`. `null` while no row exists yet or `isComplete` is still `false`. Not read by any gating logic — kept only as basic write-time provenance, consistent with `AppSettings.updatedAt`'s existing role. |

**No row at all** (table exists, but no `'singleton'` row has ever been written) is a valid, meaningful state distinct from `isComplete = false`: it means "never resolved yet" — on a fresh install this is what `ResolveOnboardingStatus` sees before onboarding is shown for the first time. Once written, the row is only ever moved from absent → `isComplete = true` (or from `isComplete = false` → `true` if some future migration path ever writes an intermediate `false` row — the current design never writes `isComplete = false` explicitly, only ever creates the row already `true`, since there's nothing meaningful to persist before completion; see State Transitions below).

**Why not a "started/in-progress" state**: the spec's Edge Cases explicitly require that an app killed mid-onboarding (before completion or skip) show onboarding again *from the beginning* on next launch (FR-010). Persisting a partial-progress/"started" state would either be unused (since the UI never reads it to resume) or would require additional resume logic the spec explicitly does not call for. A boolean flag written exactly once, only on actual completion, is the minimal correct model — deliberately not over-engineered into a richer state machine.

### State Transitions

```
(no row exists)
     │
     │  user finishes last screen, OR user taps Skip, OR
     │  ResolveOnboardingStatus detects pre-existing Person/Transaction data (FR-010a)
     ▼
isComplete = true, completedAt = <write time>
     │
     │  (terminal — no code path ever flips isComplete back to false)
     ▼
isComplete = true forever
```

There is no `isComplete = false` row ever written by this feature — the row simply does not exist until the moment of completion. This keeps "app was killed mid-onboarding" and "app has never been launched with this feature yet" indistinguishable by design (both are "no row"), which is exactly correct per FR-010: both cases must show onboarding again from the start.

### Migration

`AppDatabase.schemaVersion` bumps from `3` to `4`. This assumes `003-dark-mode-theme`'s own migration (`2` → `3`, adding the nullable `themeMode` column to `AppSettings`) has already been merged — per this feature's spec Assumptions, `003-dark-mode-theme` is a hard prerequisite, not just a build-order preference. If `003-dark-mode-theme` has not shipped yet when this feature is implemented, coordinate migration order first: do not have both features independently claim version `3`. `MigrationStrategy.onUpgrade` gains one more branch, appended after feature 003's:

```dart
onUpgrade: (m, from, to) async {
  if (from < 2) {
    await m.createTable(appSettings);
  }
  if (from < 3) {
    // feature 003-dark-mode-theme: nullable themeMode column on AppSettings
  }
  if (from < 4) {
    await m.createTable(onboardingStatus);
  }
},
```

`onCreate: (m) => m.createAll()` already covers a fresh install (no migration branch needed there — `createAll()` picks up the new table automatically).

## Entity: Onboarding Screen

The spec's Key Entity "one step in the introductory sequence, with its own message/illustration content and position within the overall progress indicator." This content is **static and bundled with the app** (per spec Assumptions: "exact copy/illustration content is a content/design decision made during implementation... no backend/network call is required to determine onboarding content") — it is never read from or written to the database, and therefore is not a Drift table.

Modeled as a Flutter-framework-free Domain enum (so the *existence and order* of the 5 topics is a Domain-level concept per Principle I), with the actual copy/icon mapping kept in Presentation (since real content needs `AppLocalizations`/`BuildContext`, which are Flutter types that must not leak into Domain):

```dart
// domain/entities/onboarding_topic.dart
enum OnboardingTopic {
  understandingMoney,      // FR-002(1): income/expenses/savings/financial activity
  moneyBetweenPeople,      // FR-002(2): money given/received, what remains unsettled
  socialOccasions,         // FR-002(3): weddings/birthdays/engagements/newborns/gifts
  scanningRecords,         // FR-002(4): scan paper records, review extracted data before saving
  aiAssistant,              // FR-002(5): financial understanding via the AI assistant
}
```

`OnboardingTopic.values` (in this fixed declaration order) **is** the sequence and step count driving the progress indicator (`step = index + 1`, `total = OnboardingTopic.values.length`) — no separate "position" field is needed since Dart enum declaration order is already stable and explicit.

| Field (conceptual) | Source | Notes |
| --- | --- | --- |
| `topic` | `OnboardingTopic` enum value | Domain-level identity of the screen; Flutter-free. |
| `index` / step number | `OnboardingTopic.values.indexOf(topic)` | Drives `OnboardingProgressIndicator`; `total` = `OnboardingTopic.values.length` (5). |
| title / body copy | `presentation/onboarding_content.dart` — a `Map<OnboardingTopic, ...>`-style lookup returning `AppLocalizations` getters (new ARB keys, one title + one description per topic) | Never hardcoded strings (Principle XIII). |
| illustration/icon | Same `presentation/onboarding_content.dart` lookup — an `IconData` (or bundled image asset) per topic, styled via `core/design_system` tokens | No new hardcoded design values (Principle XV). |

**Validation rules**: None beyond compile-time exhaustiveness — `OnboardingTopic` is a closed `enum`, so every switch/lookup over it is statically checked by the analyzer to cover all 5 topics (and any future addition/removal is a single, compiler-enforced change point).

**FR-003 constraint (AI-assistant screen accuracy)**: Not a structural/data-model constraint — it's a content-review requirement (SC-005: "zero onboarding screens contain unsupported financial promises, verified through content review"). Recorded here only to flag that the `aiAssistant` topic's copy is the one screen requiring explicit product/content sign-off before merge, since it is the only topic describing a capability (the AI assistant) rather than a purely descriptive app feature.
