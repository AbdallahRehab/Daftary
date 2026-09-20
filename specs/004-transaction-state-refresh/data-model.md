# Data Model: Fix Stale State After Adding Money / Transactions

**Feature**: `004-transaction-state-refresh` | **Date**: 2026-09-20

This is a navigation/state-propagation bug fix (see `research.md`), not a
data-shape change. No table, entity field, or repository return type changes.
This document exists to record, per the spec's Key Entities section, exactly
which existing entities are involved and confirms neither needs to change.

## Entities (existing, unchanged)

### Transaction (`MoneyTransaction`)

Source: `lib/features/transactions/domain/entities/money_transaction.dart`.
A single money-received/money-given/repayment record tied to a person
(`id`, `personId`, `amount`, `direction`, `kind`, `date`, `note`,
`createdAt`/`editedAt`/`deletedAt`). Already carries every field
`PersonDetailState.history` needs. **No change.**

### Person Balance Summary (`PersonBalance`)

Source: `lib/features/transactions/domain/entities/person_balance.dart`.
`{ personId, net }`, with `status` (`theyOweYou` / `youOweThem` / `settled`)
derived purely from the sign of `net`. Computed fresh on every
`TransactionsRepository.getPersonBalance` call from `TransactionsDao.netBalanceMinorUnits`
(a `SUM` over non-deleted rows, via `core/database/balance_queries.dart`) —
already always correct *at the moment it is computed*; the bug was never in
this computation, only in *when* `PersonDetailCubit` was told to recompute it.
**No change.**

### Presentation state (existing, unchanged)

- `PersonDetailState` (`lib/features/transactions/presentation/cubit/person_detail_state.dart`)
  — `status`, `person`, `balance`, `history`, `errorMessage`. Already an
  immutable `Equatable` value class updated via `copyWith()`
  (constitution Principle IV). No new field is needed: the fix changes *when*
  `PersonDetailCubit.refresh()` is invoked (navigation glue in
  `person_detail_page.dart` / `transaction_form_page.dart`), not what
  `PersonDetailState` holds or how it's built.
- `TransactionFormState` (`lib/features/transactions/presentation/cubit/transaction_form_state.dart`)
  — already exposes `savedTransaction` on success, which the fix's caller-side
  navigation (see `research.md` Decision) reads to decide where to navigate
  after a real `pop()`. No new field needed.

## Derivation / Computation Changes

None. `PersonBalance.net` and `PersonDetailState.history` continue to be
derived exactly as today (`SUM` of non-deleted `money_transactions` rows;
chronological non-deleted rows for the person, respectively) — see
`lib/core/database/balance_queries.dart` and
`TransactionsDao.getHistoryForPerson`. The fix only makes
`PersonDetailCubit.load()`/`refresh()` run reliably at the right time.

## Relationships

Unchanged: one `Person` (people feature) has many `MoneyTransaction`s
(transactions feature); `PersonBalance` is a pure function of a person's
non-deleted transactions. No new relationship introduced.
