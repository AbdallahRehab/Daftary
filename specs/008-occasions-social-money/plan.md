# Implementation Plan: Occasions / Social Money

**Branch**: `008-occasions-social-money` | **Date**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-occasions-social-money/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Let the app's single local user group multiple people's money contributions under one named social event ("Ahmed's Wedding") — recording who gave/received how much, with a type (wedding, engagement, birthday, newborn/سبوع, condolence, celebration, other/custom), notes, and optional photo attachments — and see the occasion's total received, total given, net, and settlement status computed on demand. The key architectural decision: an Occasion participant contribution is **not** a new parallel ledger — it is stored as an existing `MoneyTransaction` row (from 001-money-relationships-tracking) carrying a new `TransactionKind.occasionContribution` value and a nullable `occasionId` foreign key, so it is simultaneously the one row shown in the person's own transaction history/balance (`transactions` feature, unchanged calculation) and the one row aggregated into the occasion's totals. Implemented as one new Flutter clean-architecture feature (`occasions`) plus a small, additive extension to the existing `transactions` feature's data layer (new enum value + nullable column + one new indexed query), using BLoC/Cubit, the existing `Money` type, and the existing soft-delete/edit-audit/idempotency conventions already proven in `transactions`.

## Technical Context

**Language/Version**: Dart 3.10 (SDK constraint `^3.10.0` in `pubspec.yaml`), Flutter 3.47.0 (pinned via `fvm`, `.fvmrc`)

**Primary Dependencies**: `flutter_bloc` (state management, per constitution Principle III), `get_it` + `injectable` for dependency injection, `drift` + `sqlite3_flutter_libs` + `path_provider` for the local relational database (same `AppDatabase`), `fpdart` for `Either<Failure, Success>` result flow, `equatable` for value equality, `uuid` for entity/idempotency-key generation, `intl` (`flutter_localizations`/`gen_l10n`) for Arabic/English localization and EGP formatting, `go_router` for declarative navigation. **New dependency required**: an image capture/selection package (`image_picker`, camera-and-gallery, MIT-licensed, actively maintained) for FR-017 (attach photos to an Occasion) — chosen over building a custom camera flow because this feature only needs simple capture/pick, not preprocessing (preprocessing/cropping is scoped to the later OCR feature which may reuse the same package). No cloud storage dependency: attachments are stored as local file references only (see research.md).

**Storage**: Local SQLite via `drift`, same single on-device `daftary.sqlite` file/`AppDatabase` used by `people`/`transactions`/`finance`. Additive schema migration: (a) one new table `Occasions`, one new table `OccasionAttachments`; (b) two additive, nullable columns on the existing `MoneyTransactions` table (`occasion_id`, `counts_toward_balance`) plus widening the existing `kind` enum column to accept a new `occasionContribution` value. `AppDatabase.schemaVersion` increments by 1 from whatever value it holds at implementation time (currently 4; 5 if `finance`/007 has landed first — order is a release-planning concern, not a spec dependency). No remote backend or network layer (feature is local-only, matching the rest of the app).

**Testing**: `flutter_test` (unit/widget), `bloc_test` + `mocktail` (Cubit unit tests with faked repositories/use cases), `integration_test` (critical end-to-end flows: create occasion + add participants, verify contribution appears in person history, edit/remove a participant from both entry points, delete an occasion and verify cascade, archive/filter occasions, attach/remove a photo).

**Target Platform**: Android and iOS mobile apps (existing app scope); desktop/web build targets scaffolded by `flutter create` remain out of scope.

**Project Type**: mobile-app (Flutter, feature-first clean architecture)

**Performance Goals**: Occasion creation + 3 participants round trip in <90s end-to-end per SC-001 (dominated by user input time; each individual save completes well under 300ms on mid-range Android); occasion totals/settlement recompute and render in <1s for up to 200 participants in a single occasion (SC-002 tested at 30, ceiling set higher for headroom); occasions list scroll sustains ~60fps on mid-range Android hardware, consistent with the existing `transactions`/`people` lists.

**Constraints**: Fully offline-capable (no network dependency at all); money stored/computed as integer minor units (piastres) via the existing `Money` type, never floating point (constitution Principle VIII); every participant-contribution save and every occasion-create save is idempotent (FR-019 — no accidental double-submit duplicates, same pattern as `transactions`' idempotency key); every contribution/occasion edit or deletion remains traceable (constitution Financial Domain Override) by reusing the existing `TransactionAuditEntry` mechanism for contributions and a new lightweight audit entry for occasion-level edits; full Arabic (RTL) and English (LTR) UI including the standard occasion type names and Arabic-Indic numeral input (FR-022); this feature MUST NOT change the existing `PersonBalance`/`OverviewSummary` computation formulas — it only adds more rows of the same `MoneyTransaction` shape for them to sum over (FR-023).

**Scale/Scope**: Single user per device; assume up to ~2,000 occasions and ~200 participants per occasion as the practical performance ceiling (well above realistic personal/family use across years of events); 1 new feature (`occasions`) plus a small additive change inside the existing `transactions` feature's data layer; ~6-7 screens (occasions list, occasion detail, create/edit occasion, add/edit participant, archived occasions, attachment viewer — some may be combined at implementation time, see Project Structure).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Clean Architecture Layering | `occasions` splits into `data/domain/presentation`; screens never touch `drift`/DB directly; the `transactions` feature's existing layering is extended, not bypassed | PASS |
| II. Feature-First Modularity | New code lives under `lib/features/occasions/`; the one cross-feature touch point (`MoneyTransaction` gaining `occasionContribution`/`occasionId`) lives inside the existing `transactions` feature (Domain entity + Data mapper/DAO), not duplicated into `occasions` — `occasions` depends on `transactions`' public Domain contracts (repository interface, entities), never the reverse | PASS |
| III. BLoC/Cubit Mandate | Cubits per screen/flow (`OccasionsListCubit`, `OccasionFormCubit`, `OccasionDetailCubit`, `ParticipantFormCubit`, `ArchivedOccasionsCubit`); no alternate state layer | PASS |
| IV. Immutable State | All Cubit states are `Equatable` value classes updated via `copyWith()`; no mutated list/map fields | PASS |
| V. Domain-Driven Business Logic | Use cases: `CreateOccasion`, `EditOccasion`, `DeleteOccasion`, `ArchiveOccasion`, `RestoreOccasion`, `AddParticipantContribution`, `EditParticipantContribution`, `RemoveParticipantContribution`, `GetOccasionDetail`, `GetOccasionsList`, `AddOccasionAttachment`, `RemoveOccasionAttachment` — each a meaningful business action, several coordinating two repositories (occasion + transaction) | PASS |
| VI. Repository Pattern | Domain defines `OccasionsRepository` (new) and reuses `TransactionsRepository` (extended, still one interface, one implementation) — Presentation/Domain depend only on abstractions via DI | PASS |
| VII. Explicit Error Handling | All repository/use-case calls return `Either<Failure, T>` (`fpdart`); typed `Failure`s reused from `core/error/failure.dart` plus `OccasionNotFoundFailure`/`ParticipantNotFoundFailure` where a more specific message earns its keep — no empty catches, no raw exceptions to UI | PASS |
| VIII. Deterministic Financial Calculations | Occasion totals (received/given/net/settlement) computed by domain code as a deterministic SUM over linked `MoneyTransaction` rows — the exact same aggregation shape already used for `PersonBalance`/`OverviewSummary`, no AI involvement | PASS |
| IX. AI Isolation | Not applicable — no AI integration in this feature | PASS (N/A) |
| X. OCR Human-in-the-Loop | Not applicable — no OCR in this feature (photo attachments here are opaque files, not parsed) | PASS (N/A) |
| XI. Offline Resilience & Idempotent Sync | Feature is local-only; idempotency enforced via a client-generated idempotency key with a DB unique constraint, mirroring `MoneyTransactions.idempotencyKey`, for both `createOccasion` and `addParticipantContribution` | PASS |
| XII. Security & Secrets | No secrets/API keys; attachment photos are stored in the app's private local sandboxed storage (same mechanism already decided for the app in 001 research.md), never uploaded; camera/gallery permission requested contextually only when the user taps "attach photo" (FR-017, constitution Engineering Standards) | PASS |
| XIII. Localization & RTL/LTR | `gen_l10n` ARB additions for `ar`/`en` (occasion form, type names, participant form, settlement labels); `intl` currency/number formatting and Arabic-Indic numeral parsing reused as-is from `core/money` | PASS |
| XIV. Dependency Injection | `get_it`/`injectable` wires the new DAO, `OccasionsRepository`, use cases, Cubits, and the new attachment-picker service abstraction; nothing self-instantiated | PASS |
| XV. Design System | Reuses existing `core/design_system` components (`AppButton`, `AppTextField`, `AppDateField`, `AppCard`, `AppEmptyView`, `AppConfirmDialog`, `AppChip`/relationship-tag-style chip for occasion type); an occasion-type icon picker and a participant-row widget are the only genuinely new visual components, built inside `features/occasions/presentation/widgets/` first | PASS |
| XVI. Testability by Design | Use cases/repositories/mappers/validators unit-tested; Cubits tested with `bloc_test`/`mocktail`; widget tests for the occasion form and participant form; `integration_test` for the flows listed in Scale/Scope, including the cross-feature assertion that a contribution appears correctly in the person's own history | PASS |

No violations requiring justification — **Complexity Tracking is not needed.**

**Post-Design Re-Check** (after Phase 1 `data-model.md`/`contracts/`/`quickstart.md`): Extending `MoneyTransaction`/`TransactionKind` rather than inventing a second, parallel "OccasionContribution" write path is the direct, minimal implementation of the spec's core data-integrity decision (FR-005/FR-009 — one row of truth, two read views) — not speculative scope, and it keeps `PersonBalance`/`OverviewSummary` correct for free instead of requiring a second, occasion-aware balance calculation. The `countsTowardBalance` per-contribution flag (FR-018) is the minimal field needed to support the condolence-exception default without adding a second calculation path — `PersonBalance` simply filters on it, exactly as it already filters on `deletedAt`. No new dependency beyond the one image-picker package justified above, no layering, state-management, or architectural deviation introduced. All gates above remain **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/008-occasions-social-money/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── database/                  # AppDatabase gains Occasions + OccasionAttachments tables,
│   │                                # and additive occasion_id/counts_toward_balance columns +
│   │                                # widened kind enum on the existing MoneyTransactions table;
│   │                                # schemaVersion incremented by 1, additive migration only
│   ├── design_system/              # reused as-is (occasion-type chip styled like relationship tag chip)
│   ├── di/                         # gains occasions feature registrations (generated via injectable)
│   ├── error/                      # reused; gains OccasionNotFoundFailure/ParticipantNotFoundFailure
│   ├── l10n/                       # app_en.arb / app_ar.arb gain occasions-feature keys
│   ├── media/                      # NEW small cross-feature wrapper: AttachmentPickerService
│   │                                # abstraction over the new image-picker dependency (also reused
│   │                                # by the later OCR feature's capture step — built here first since
│   │                                # this feature needs it first, per constitution Principle II's
│   │                                # "only promote to core once genuinely shared" — justified because
│   │                                # OCR's spec already names photo capture as its first step)
│   ├── money/                      # reused as-is (Money, EgpFormatter, numeral parser)
│   └── routing/                    # app_router.dart gains the occasions branch/routes
│
├── features/
│   ├── people/                     # UNCHANGED
│   ├── transactions/                # EXTENDED (additive only):
│   │   ├── domain/entities/money_transaction.dart   # TransactionKind gains `occasionContribution`;
│   │   │                                              # MoneyTransaction gains nullable occasionId,
│   │   │                                              # countsTowardBalance (default true)
│   │   ├── domain/repositories/transactions_repository.dart  # gains getContributionsForOccasion(),
│   │   │                                              # addOccasionContribution(), consistent with
│   │   │                                              # existing addTransaction()/recordRepayment()
│   │   ├── data/models/transaction_mapper.dart        # maps the two new columns
│   │   └── data/datasources/transactions_dao.dart      # query by occasion_id, indexed
│   ├── settings/                    # UNCHANGED
│   ├── onboarding/                  # UNCHANGED
│   ├── finance/                     # UNCHANGED (007, if present) — no interaction with this feature
│   └── occasions/                   # NEW
│       ├── data/
│       │   ├── datasources/         # OccasionsDao (drift): occasions + attachments queries
│       │   ├── models/              # OccasionEntity/OccasionAttachmentEntity <-> domain mappers
│       │   └── repositories/        # OccasionsRepositoryImpl (composes OccasionsDao +
│       │                              # TransactionsRepository for participant contributions)
│       ├── domain/
│       │   ├── entities/            # Occasion, OccasionType, OccasionAttachment,
│       │   │                          # OccasionSummary (totals/settlement), OccasionParticipantRow
│       │   ├── repositories/         # OccasionsRepository (abstract)
│       │   └── usecases/             # CreateOccasion, EditOccasion, DeleteOccasion,
│       │   │                          # ArchiveOccasion, RestoreOccasion, GetOccasionsList,
│       │   │                          # GetOccasionDetail, AddParticipantContribution,
│       │   │                          # EditParticipantContribution, RemoveParticipantContribution,
│       │   │                          # AddOccasionAttachment, RemoveOccasionAttachment
│       └── presentation/
│           ├── cubit/                # OccasionsListCubit, OccasionFormCubit, OccasionDetailCubit,
│           │                          # ParticipantFormCubit, ArchivedOccasionsCubit
│           ├── pages/                 # OccasionsListPage, OccasionFormPage, OccasionDetailPage,
│           │                          # ParticipantFormPage, ArchivedOccasionsPage
│           └── widgets/               # OccasionListTile, OccasionTypeChip, OccasionTypePicker,
│                                       # ParticipantRow, OccasionTotalsCard, SettlementStatusBadge,
│                                       # OccasionAttachmentGallery
│
└── main.dart                          # UNCHANGED (occasions Cubits resolved per-screen via DI like
                                        # transactions' Cubits already are)

test/
├── features/
│   ├── transactions/
│   │   └── domain/usecases/          # existing tests extended for occasionContribution kind
│   └── occasions/
│       ├── domain/usecases/          # unit tests, faked repositories
│       ├── data/repositories/        # OccasionsRepositoryImpl tests against an in-memory drift DB
│       └── presentation/cubit/       # bloc_test + mocktail
└── widget/                            # OccasionFormPage, ParticipantFormPage widget tests

integration_test/
└── occasions_flows_test.dart          # create occasion + participants, verify contribution in
                                        # person history/balance, edit from both entry points,
                                        # delete occasion cascade, archive/restore, filter/search,
                                        # attach/remove photo (US1-US5)
```

**Structure Decision**: Standard single Flutter app (Option 1 shape), one new feature-first module `lib/features/occasions/` added alongside the existing features, per constitution Principle II. The one deliberate exception to "features don't reach into each other's internals" is that `occasions` depends on `transactions`' **public Domain layer** (its repository interface and `MoneyTransaction`/`TransactionKind` entities) exactly the way `budgets`/`savings` will later depend on `finance`'s Category vocabulary (007's plan.md) — this is composition through a stable Domain contract, not a layering violation, and it is the direct consequence of the spec's core decision (single source of financial truth, no parallel ledger). No `backend/`/`api/` split — this feature has no server component. Tests mirror `lib/` under Flutter's `test/` directory, plus one new `integration_test/` file.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
