# Contract: `AppStartupCubit`

**File**: `lib/features/startup/presentation/cubit/app_startup_cubit.dart`
**Registration**: `@lazySingleton` (root-scoped, like `SettingsCubit` and `OnboardingCubit`)

```dart
@lazySingleton
class AppStartupCubit extends Cubit<AppStartupState> {
  AppStartupCubit(
    this._settings,            // SettingsCubit
    this._onboarding,          // OnboardingCubit
    {@ignoreParam Duration timeout = const Duration(seconds: 10)},
  );

  /// Runs startup once. Safe to call repeatedly; later calls return the
  /// first call's future and emit nothing.
  Future<void> start();

  /// Only acts when state.status == failed. Re-runs only unfinished steps;
  /// joins a step still pending from a timed-out attempt.
  Future<void> retry();

  /// Completes when status first becomes `ready` (immediately if it already
  /// is). Never completes with an error.
  Future<void> get whenReady;
}
```

## Ordered steps (awaited, inside the `timeout` budget)

1. `SettingsCubit.initialize()` → emit `appearanceResolved: true`
2. `OnboardingCubit.initialize()` → emit `status: ready`

## Guarantees (each backed by a test in `test/features/startup/presentation/cubit/app_startup_cubit_test.dart`)

| # | Guarantee |
|---|---|
| G1 | `idle → preparing → preparing(appearanceResolved) → ready` on success, in that order |
| G2 | Concurrent or repeated `start()` runs each step exactly once |
| G3 | A step throwing → `failed(error)`; nothing is rethrown; the error is logged under `daftary.startup` |
| G4 | Budget elapsed → `failed(timeout)` |
| G5 | `retry()` after G3 re-runs only the failed step and the steps after it (completed steps are not re-run) |
| G6 | `retry()` after G4 while a step is still pending awaits that same future (the step is invoked once in total) |
| G7 | `retry()` is a no-op in `idle`, `preparing` and `ready` |
| G8 | `whenReady` completes once on `ready` and never errors, including when the cubit is closed first (`firstWhere(..., orElse: () => state)`) |

## Callers

- `main.dart`: `unawaited(startup.start())` before `runApp`. `startup.whenReady` then starts `NotificationRecomputeTrigger` and `NotificationTapRouter`.
- `AppStartupGate`: reads state and calls `retry()` from the error action.
- `integration_test/*` `bootApp()`: `await getIt<AppStartupCubit>().start()`.
