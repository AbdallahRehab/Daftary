# Contract Extension: TransactionsRepository (001, extended by this feature)

This feature adds two methods to the existing `TransactionsRepository` interface (`specs/001-money-relationships-tracking/contracts/transactions_repository.md`) rather than introducing a competing interface — see research.md Decision 1. All existing 001 methods and their signatures are unchanged.

```dart
abstract class TransactionsRepository {
  // ...existing 001 methods unchanged (addTransaction, recordRepayment,
  // editTransaction, deleteTransaction, getPersonHistory, getPersonBalance,
  // getOverview)...

  /// Creates a MoneyTransaction with kind = occasionContribution, linked to
  /// [occasionId]. Used internally by OccasionsRepositoryImpl
  /// (addParticipantContribution) — Presentation never calls this directly
  /// for occasion flows; it goes through OccasionsRepository so the
  /// occasion-specific validation (occasion must exist, must not be
  /// deleted) is applied in one place.
  Future<Either<Failure, MoneyTransaction>> addOccasionContribution({
    required String idempotencyKey,
    required String personId,
    required String occasionId,
    required int amountMinorUnits,
    required TransactionDirection direction,
    required bool countsTowardBalance,
    String? note,
  });

  /// All non-deleted contribution rows for one occasion, across all
  /// participants, in chronological order (backs
  /// OccasionsRepository.getOccasionDetail's participant list and
  /// OccasionSummary aggregation).
  Future<Either<Failure, List<MoneyTransaction>>> getContributionsForOccasion(
    String occasionId,
  );
}
```

**Behavioral change to existing methods**:
- `getPersonBalance`/`getOverview` (001, unchanged signatures): their underlying SQL aggregate gains the `counts_toward_balance` filter predicate described in data-model.md's "Balance computation (updated)" note. This is a query-body change only — no interface, parameter, or return-type change, so no 001 call site is affected.
- `getPersonHistory` (001, unchanged signature): now also returns `occasionContribution`-kind rows for that person (previously only `initialExchange`/`repayment` existed); the Presentation layer's existing transaction-list-tile rendering gains a branch to show the linked occasion's name as a label (FR/US2 Acceptance Scenario 4), consistent with how `kind` is already used to distinguish a repayment visually (001 US3 AC1).
