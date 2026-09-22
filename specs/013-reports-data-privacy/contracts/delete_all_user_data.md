# Contract: DeleteAllUserData

Local-only Domain use case wrapping the one genuinely new repository this feature adds, `DataWipeRepository` (data-model.md), per research.md Decision 5.

```dart
@injectable
class DeleteAllUserData {
  const DeleteAllUserData(this._dataWipeRepository);

  final DataWipeRepository _dataWipeRepository;

  /// Wipes every table via [DataWipeRepository.deleteAllUserData] (FR-016,
  /// atomic per FR-018). Does NOT itself touch OnboardingCubit or trigger
  /// navigation — that orchestration belongs to the Presentation layer
  /// (DeleteAccountCubit), per research.md Decision 6, so this use case
  /// stays a pure "did the wipe succeed" answer, cleanly unit-testable
  /// without any Presentation/routing dependency.
  Future<Either<Failure, Unit>> call() => _dataWipeRepository.deleteAllUserData();
}
```

## Contract: `AppDatabase.deleteAllUserData()` (core/database extension)

The actual atomicity mechanism (research.md Decision 5), mirroring `balance_queries.dart`'s existing extension-on-`AppDatabase` precedent.

```dart
extension DataWipe on AppDatabase {
  /// Deletes every row from every table in one drift transaction — if any
  /// delete throws, every prior delete in this call is rolled back
  /// automatically by drift's transaction mechanism (FR-018). Order within
  /// the transaction respects foreign keys (TransactionAuditEntries and
  /// MoneyTransactions before People; FinanceEntries before
  /// FinanceCategories) even though drift's transaction rollback makes
  /// this defensive rather than strictly required for atomicity itself.
  Future<void> deleteAllUserData() {
    return transaction(() async {
      await delete(transactionAuditEntries).go();
      await delete(moneyTransactions).go();
      await delete(people).go();
      await delete(financeEntries).go();
      await delete(financeCategories).go();
      await delete(appSettings).go();
      await delete(onboardingStatus).go();
    });
  }
}
```

**Behavioral guarantees**:
- All-or-nothing: verified by `test/core/database/data_wipe_test.dart` forcing a failure partway through and asserting every table is still fully intact (research.md Decision 10) — a real `drift` transaction test, not a mocked one.
- Idempotent: calling this again against an already-empty database is a safe no-op (deleting zero rows from each table).
- Does not touch `AppDatabase.schemaVersion` or any table's schema — rows only, never structure.

## Contract: Post-delete onboarding reset (Presentation orchestration, `DeleteAccountCubit`)

Not a use-case contract, but the documented sequencing `DeleteAccountCubit` owns (research.md Decision 6):

```dart
Future<void> confirmDelete() async {
  emit(state.copyWith(status: DeleteStatus.inProgress));
  final result = await _deleteAllUserData();
  result.match(
    (failure) => emit(state.copyWith(status: DeleteStatus.error, errorMessage: ...)),
    (_) async {
      await _onboardingCubit.initialize(); // re-resolves to showOnboarding
      emit(state.copyWith(status: DeleteStatus.success));
      // caller (the page) reacts to `success` by calling context.go('/'),
      // which the router's existing redirect then sends to '/onboarding'
    },
  );
}
```
