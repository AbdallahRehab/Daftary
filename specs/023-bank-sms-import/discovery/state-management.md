# Discovery T003: Cubit/BLoC conventions, rollback and single-flight idioms

Read-only notes for every 023 Cubit (T078, T079 and the other six in ui-contract.md), for `SmsCatchUpTrigger`/`ScanCoordinator`, and for the `_ConfirmAborted` rollback in T074.

## Flags: where the plan or contracts are wrong or imprecise

| # | Plan/contract claim | Reality | What to do |
| --- | --- | --- | --- |
| S1 | "`_ConfirmAborted` rollback idiom in the OCR confirm path" (plan.md:47, :272, :415; tasks T003/T070/T074) | The OCR class is called **`_BatchAborted`** (`lib/features/ocr/data/repositories/ocr_repository_impl.dart:690-698`). No `_ConfirmAborted` exists anywhere in `lib/`. | Create `_ConfirmAborted` as a new private class that copies `_BatchAborted` (section 4). The name in tasks and plan is fine for the **new** class. Just don't search for an existing one. |
| S2 | OCR confirm as the model for the status guard | OCR reads the scan status **before** opening its transaction (`ocr_repository_impl.dart:368-388`), so two concurrent confirms could both pass the check. Its cubit-level single-flight hides this. | SMS `confirm` re-reads the status **inside** `_db.transaction` (FR-075a). See transactions.md F3. |
| S3 | "`SmsCatchUpTrigger` is a lifecycle observer ... like `NotificationRecomputeTrigger`" (plan.md:43) | `NotificationRecomputeTrigger` registers its **own** `WidgetsBindingObserver` (`notification_recompute_trigger.dart:29,48`). Its comment says `AppLifecycleObserver` "does not exist in code yet" (`:15-18`), which is **stale**: `lib/core/security/app_lifecycle_observer.dart` now exists. | Copying the observer pattern is fine and is what the plan means. Lock state must come through the `LockStatus`/`isLocked` port (T006), never from the trigger's own lifecycle reading. Don't "fix" the stale comment (out of slice). |
| S4 | Redacted `toString` on Paste and review states (plan.md:460) | `Equatable.toString` prints **every prop in debug builds** (`EquatableConfig.stringify` defaults to `true` under asserts, `equatable-2.1.0/lib/src/equatable_config.dart:18-28`). Any state, draft, failure or value object that holds SMS-derived text leaks it through `toString` in debug, in test failure output and in `bloc_test` diffs. No `BlocObserver` is installed (`grep BlocObserver lib` is empty), so nothing logs transitions today. | Override `toString` on **every** Equatable type that carries SMS-derived fields (states, `ReviewDraft`, `PendingSmsImport`, `ParsedSms`, `RawIncoming` …), not only the states. Precedent: `email_link_state.dart:55-59`. Never add a `BlocObserver`. |
| S5 | "Each Cubit defines idle/loading/success/failure" (plan.md:43) | The house style is **one** Equatable state class with an `enum XStatus`, not sealed or union states. 52 of 62 `*_state.dart` files use an `enum ...Status`, none uses `sealed class`, and there are 0 `Bloc<` classes. Cubits are `@injectable` (54) unless app-wide (3 `@lazySingleton`: `SettingsCubit`, `AppStartupCubit`, `OnboardingCubit`). | Use the enum-status template below and register page Cubits as `@injectable` (factory). |

## 1. State class template (copy this)

Modeled on `ScanReviewState` (`lib/features/ocr/presentation/cubit/scan_review_state.dart:15-193`) and `ScanHistoryState` (`scan_history_state.dart:6-50`). The rules are:

- An enum status. When a busy phase must disable an action, give it a distinct value such as `submitting` (`scan_review_state.dart:9-23`, rationale at `:11-14`).
- Every field is `final`. Lists, sets and maps are replaced wholesale and held as `List.unmodifiable` (`scan_review_cubit.dart:98,336`, rationale at `scan_review_state.dart:28-31`).
- Derived getters live on the state (`isSubmitting`, `canConfirm`, `orderedEntries` at `scan_review_state.dart:93-139`), never in the widget.
- `copyWith` takes nullable params, plus an explicit `clearX` flag for each nullable field that must be resettable (`scan_review_state.dart:141-176`, `failure: clearFailure ? null : (failure ?? this.failure)`). Note that `EmailLinkState.copyWith` uses a different style (failure reset unless passed, `email_link_state.dart:36-50`). Prefer the `clearX` style.
- `props` lists every field.
- A redacted `toString` (S4).

```dart
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

enum ImportReviewStatus { initial, loading, ready, loadFailure, submitting, success }

/// Immutable state for `ImportReviewCubit` (constitution Principle IV).
class ImportReviewState extends Equatable {
  const ImportReviewState({
    this.status = ImportReviewStatus.initial,
    this.pendingId = '',
    this.draft,
    this.missing = const {},
    this.duplicateRequest,          // one-shot flag consumed via BlocListener
    this.failure,
  });

  final ImportReviewStatus status;
  final String pendingId;
  final ReviewDraft? draft;
  final Set<ReviewField> missing;
  final DuplicateFinding? duplicateRequest;
  final Failure? failure;

  bool get isSubmitting => status == ImportReviewStatus.submitting;
  bool get canAdd =>
      !isSubmitting && status == ImportReviewStatus.ready && draft != null && missing.isEmpty;

  ImportReviewState copyWith({
    ImportReviewStatus? status,
    String? pendingId,
    ReviewDraft? draft,
    Set<ReviewField>? missing,
    DuplicateFinding? duplicateRequest,
    bool clearDuplicateRequest = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ImportReviewState(
      status: status ?? this.status,
      pendingId: pendingId ?? this.pendingId,
      draft: draft ?? this.draft,
      missing: missing ?? this.missing,
      duplicateRequest:
          clearDuplicateRequest ? null : (duplicateRequest ?? this.duplicateRequest),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, pendingId, draft, missing, duplicateRequest, failure];

  /// Never prints message-derived values (FR-097, FR-101).
  @override
  String toString() =>
      'ImportReviewState(status: $status, missing: ${missing.length}, '
      'hasDuplicateRequest: ${duplicateRequest != null}, '
      'failure: ${failure.runtimeType})';
}
```

For value objects such as `ReviewDraft`, follow `CandidateEntry.copyWith` (`lib/features/ocr/domain/entities/candidate_entry.dart:120-150`): nullable params plus `clearX` flags (`clearMatchedPersonId` at `:125,141-143`). Keep the domain rule on the entity (`isConfirmEligible`, `:103`) so the cubit never duplicates it (`scan_review_cubit.dart:26-32`). The same applies to `ReviewDraft.validate()`.

## 2. Cubit template and its single-flight action (the "Add" gate)

Source: `ScanReviewCubit` (`lib/features/ocr/presentation/cubit/scan_review_cubit.dart`).

- `@injectable class X extends Cubit<XState>` with positional use-case injection and `super(const XState())` (`:37-50`).
- `load(id)` emits `loading` with `clearFailure: true`, awaits, **checks `if (isClosed) return;` after every await**, then emits `ready` or `loadFailure` (`:65-102`).
- **Single-flight gate** (`:291-341`). The guard is the first statement, and the `submitting` status is emitted **before the first `await`**, so a second tap in the same frame returns early:

```dart
  Future<void> add() async {
    if (state.isSubmitting || state.status == ImportReviewStatus.success) return; // single-flight
    final draft = state.draft;
    if (draft == null) return;
    final missing = draft.validate();
    if (missing.isNotEmpty) {
      emit(state.copyWith(missing: missing));
      return;
    }
    emit(state.copyWith(status: ImportReviewStatus.submitting, clearFailure: true)); // before any await

    final result = await _addImportedTransaction(pendingId: state.pendingId, draft: draft);
    if (isClosed) return;
    result.match(
      (failure) => failure is ProbableDuplicateFailure
          ? emit(state.copyWith(status: ImportReviewStatus.ready, duplicateRequest: failure.finding))
          : emit(state.copyWith(status: ImportReviewStatus.ready, failure: failure)),
      (_) => emit(state.copyWith(status: ImportReviewStatus.success)),
    );
  }

  void consumeDuplicateRequest() =>
      emit(state.copyWith(clearDuplicateRequest: true)); // like dismissCancelConfirmation, :389-392
```

The OCR cubit generates a **fresh UUID idempotency key per attempt** (`:307`). SMS does **not**: its key is `sms-import:<pendingId>` and the repository builds it. The cubit holds no key.

- Replace list elements immutably with a helper that builds a new unmodifiable list (`:396-402`). Never assign by index.
- A stream subscription in a cubit (for `BankMessagesCubit` with `WatchPendingImports`/`WatchPendingImportCount`) follows `ScanHistoryCubit` (`scan_history_cubit.dart:25-94`): `StreamSubscription? _subscription`, `subscribe()` cancels any earlier subscription, the `listen` callback checks `isClosed`, and `close()` cancels before `super.close()`. Its `Completer _firstResult` (`:26,34,76-81`) is a test aid that resolves once the first result arrives.

## 3. Page wiring and one-shot flags

- `BlocProvider(create: (_) => getIt<ScanReviewCubit>()..load(scanId))` (`lib/features/ocr/presentation/pages/scan_review_page.dart:35-36`). `getIt` comes from `lib/core/di/injection.dart:6`.
- One-shot UI requests are **state flags consumed by a listener**, not streams or callbacks. See `BlocConsumer(listenWhen: (p, c) => p.status != c.status || p.requiresCancelConfirmation != c.requiresCancelConfirmation, listener: ...)` (`scan_review_page.dart:52-74`). The flag is cleared through a cubit method (`dismissCancelConfirmation`, `scan_review_cubit.dart:389-392`). The duplicate-sheet request (plan.md:460, T078) uses this exact pattern.
- Unsaved edits: `requiresCancelConfirmation` together with `PopScope(canPop: false, onPopInvokedWithResult: ... cubit.cancel())` (`scan_review_page.dart:76-83`, cubit `:369-376`) is the precedent for the "unsaved-edit prompt flag" in T071 and T078.

## 4. The rollback idiom (`_BatchAborted` becomes `_ConfirmAborted`)

Source: `OcrRepositoryImpl.confirmScanBatch` (`ocr_repository_impl.dart:424-500`) and the class at `:690-698`.

```dart
// Bottom of sms_import_repository_impl.dart: a private control-flow device, never a Failure.
/// Unwinds [SmsImportRepositoryImpl.confirm] from inside its database
/// transaction so everything rolls back. Carries the inner failure.
class _ConfirmAborted implements Exception {
  const _ConfirmAborted(this.failure);
  final Failure failure;

  @override
  String toString() => '_ConfirmAborted(${failure.runtimeType})'; // never the message (S4/F5)
}

// Inside confirm():
try {
  final ref = await _db.transaction(() async {
    final row = await _dao.getById(pendingId);                     // re-read INSIDE (S2)
    if (row == null || row.status != 'pending') {
      throw const _ConfirmAborted(ImportAlreadyDecidedFailure());
    }
    final saved = switch (confirmed) {
      ConfirmedPersonTransaction c => (await _transactions.addSmsSourcedTransaction(
          idempotencyKey: 'sms-import:$pendingId', /* ... */))
          .match((f) => throw _ConfirmAborted(f), (t) => SavedRecordRef.transaction(t.id)),
      ConfirmedFinanceEntry c => (await _finance.addSmsSourcedEntry(
          idempotencyKey: 'sms-import:$pendingId', /* ... */))
          .match((f) => throw _ConfirmAborted(f), (e) => SavedRecordRef.entry(e.id)),
    };
    // tombstone, status=added, raw_blob=NULL, scrub, learned mapping, addedCount
    return saved;
  });
  return Right(ref);
} on _ConfirmAborted catch (aborted) {
  return Left(_contentFree(aborted.failure));   // map; never forward inner messages (transactions.md F5)
} catch (e) {
  return const Left(CacheFailure('sms_confirm_failed')); // no `$e` (SQLite errors carry bound params)
}
```

OCR's own catch-all is `CacheFailure('Failed to confirm the batch: $e')` (`:498-499`). **Don't copy the `$e`.**

## 5. Service-level single-flight idiom (triggers, key store, scan coordinator)

Source: `NotificationRecomputeTrigger` (`lib/features/insights_notifications/presentation/notification_recompute_trigger.dart`).

```dart
  Future<bool>? _inFlight;                                   // :40

  /// A call while a pass is in flight joins it. Never throws.
  Future<bool> runIfDue() => _inFlight ??= _runIfDue().whenComplete(() {  // :69-71
    _inFlight = null;
  });

  Future<bool> _runIfDue() async {                           // :73-84
    try {
      final last = await _lastRun.read();
      if (last != null && _clock.now().difference(last) <= catchUpInterval) return false; // debounce
      await _engine.run();
      return true;
    } catch (_) {
      return false;                                          // swallowed, retried on next resume
    }
  }
```

The rest of its lifecycle:

- `@lazySingleton class ... with WidgetsBindingObserver` (`:28-29`).
- `start()` is idempotent through a `_started` flag. It calls `addObserver` and `unawaited(runIfDue())` (`:45-50`). `dispose()` removes the observer (`:54-58`).
- `didChangeAppLifecycleState` runs only on `resumed` (`:61-63`).
- Time comes from the injected `AppClock` (`lib/core/date/app_clock.dart:6-16`), never from `DateTime.now()`. Use it for the 60 s debounce and the year inference.
- Started in `lib/main.dart:50-56` inside `startup.whenReady.then((_) { if (!startup.state.isReady) return; ... })`. `SmsCatchUpTrigger.start()` goes in the same block. That block's exact lock timing is T006's job.

A second precedent is `SupabaseInitializer._pending` (`lib/core/sync/remote/supabase_initializer.dart:94`), used for lazy single-flight initialization. It is the model for `SmsKeyStore`'s lazy key generation.

Adaptations for `SmsCatchUpTrigger` and `RunCatchUpScan`:

- Return a `CatchUpOutcome` instead of a `bool`. Concurrent callers share the same future.
- Wrap the body in `ScanCoordinator.runExclusive`, and return `skipped(alreadyRunning)` when an explicit scan holds the coordinator.
- The `catch (_)` must not log anything (briefing rule 6). Count the failure content-free instead.

## 6. Test templates

- **Cubit tests**: `bloc_test` ^10 and `mocktail` ^1 (`pubspec.yaml:132-133`). Mocks are `class _MockX extends Mock implements X {}`. There is a `build()` factory, plus `registerFallbackValue` in `setUpAll` for any non-primitive used with `any()` (`test/features/ocr/presentation/cubit/scan_review_cubit_test.dart:25-44,123-154`). Use `blocTest<Cubit, State>(setUp:, build:, act:, verify:)` (`:157-169`).
- **Double-tap single-flight test** (`scan_review_cubit_test.dart:314-337`): the stub delays 20 ms, the test runs `await Future.wait([cubit.add(), cubit.add()])` and checks `verify(...).called(1)`.
- **Service single-flight test** (`test/features/insights_notifications/presentation/notification_recompute_trigger_test.dart:77-87`): the engine stub returns a `Completer` future. The test calls twice, completes the completer, and checks that both results are equal and `called(1)`. A `WidgetsBindingObserver` needs `TestWidgetsFlutterBinding.ensureInitialized()` (`:17`). It also has a "never throws" case (`:89-93`).
- **Redaction test** (T071): build a state holding a synthetic amount or merchant and assert that `state.toString()` contains neither.
