# Contracts: Fix Stale State After Adding Money / Transactions

No Domain repository interface changes.

Per `research.md`, the root cause and the fix both live entirely in the
**Presentation** layer: `TransactionFormPage`'s post-save navigation
(`lib/features/transactions/presentation/pages/transaction_form_page.dart`)
uses `context.go(...)` where a real `Navigator` pop is required so that the
caller's already-correct `await context.push(...); if (context.mounted) { await ...refresh(); }`
idiom (in `PersonDetailPage`/`PeopleListPage`) actually resolves.

`TransactionsRepository` (`lib/features/transactions/domain/repositories/transactions_repository.dart`)
— the Domain/Data boundary contract for this feature area, per constitution
Principle VI — is **unchanged**:

- `addTransaction(...)`, `recordRepayment(...)`, `editTransaction(...)`,
  `deleteTransaction(...)` already return the freshly-written row (or
  `Unit`), and already handle idempotency/audit entries correctly (see
  `research.md` "Other Investigation Notes").
- `getPersonHistory(personId)` / `getPersonBalance(personId)` already return
  a correct, freshly-computed result on every call — the bug was never in
  what these methods return, only in whether `PersonDetailCubit` ever called
  them again after a successful add.

No new use case, no new repository method, no new DTO/entity field, and no
change to `TransactionFormCubit`'s or `PersonDetailCubit`'s public method
signatures is introduced by this fix. `contracts/` is included in this
feature's docs only for structural consistency with sibling features (e.g.
`specs/002-localization-language-switch/contracts/`); there is nothing to
document as a before/after interface change here.
