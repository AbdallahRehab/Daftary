# Data Model: Branded Splash Screen (019)

Nothing in this feature is persisted. It has no new tables, preferences or migrations. The entities below are in-memory presentation state that exists only during one launch.

## AppStartupState (immutable, `Equatable`, `copyWith`)

| Field | Type | Default | Meaning |
|---|---|---|---|
| `status` | `AppStartupStatus` | `idle` | Where startup is (see transitions) |
| `appearanceResolved` | `bool` | `false` | `SettingsCubit.initialize()` has completed, so language and theme are final. Gates `DaftaryApp.locale` and the splash text reveal. |
| `failure` | `StartupFailure?` | `null` | Set only while `status == failed` |

`enum AppStartupStatus { idle, preparing, ready, failed }`

`enum StartupFailure { error, timeout }`: both show the same user message. The distinction exists for logs and tests.

Getters and flags:

- `isReady` is `status == ready`.
- `isFailed` is `status == failed`.
- `isRetry` is a stored field (not derived): set by `retry()` so the error layout keeps showing, with its button disabled, while the retry runs, instead of flashing back to the brand layout. It is not reset on `ready`, which is harmless because `ready` is terminal and the gate stops reading it after hand-off.

### State transitions

```text
idle ──start()──▶ preparing ──settings ok──▶ preparing(appearanceResolved=true)
                                         ──onboarding ok──▶ ready        (terminal)
preparing ──step throws / 10 s elapsed──▶ failed(failure)
failed ──retry()──▶ preparing(isRetry=true) ──…──▶ ready | failed
```

Rules:

- `start()` when `status != idle` returns the same in-flight future and emits nothing (idempotent, so there's no duplicate initialization).
- `retry()` is ignored unless `status == failed`, which protects against duplicate taps.
- `ready` is terminal: no further emissions, and `appearanceResolved` stays `true`.
- `appearanceResolved` never goes back from `true` to `false`.
- Steps are memoized per cubit instance:
  - A completed step is never re-run.
  - A step that threw is cleared, so retry re-runs it.
  - A step that is still pending after a timeout is joined on retry, not restarted.

### Budget

`timeout: Duration` is a constructor parameter (`@ignoreParam`, default `Duration(seconds: 10)`) and applies to each `start`/`retry` attempt.

## Gate-local (widget) state: `AppStartupGate`

| Field | Meaning |
|---|---|
| `_intro: AnimationController(900 ms)` | The splash story |
| `_exit: AnimationController(280 ms)` | The splash fade-out over the mounted app |
| `_introDone: bool` | The intro reached its end, or reduced motion is on |
| `_handedOff: bool` | One-way latch: set once when `_introDone && state.isReady`; from then on `child` (the Router) is mounted |
| `_splashRemoved: bool` | Set when `_exit` completes; the splash subtree is dropped |

Latch rules:

- `_handedOff` flips to `true` exactly once per gate lifetime.
- Theme, language and lifecycle changes rebuild the gate but never reset it (FR-014, FR-017).
- The gate is not keyed on locale or theme, so it survives `MaterialApp` rebuilds.

## SplashAppearance (derived, never stored)

| Input | Source |
|---|---|
| Field color | `Theme.of(context).brightness`: `AppBrandColors.field` (light) or `AppBrandColors.fieldDeep` (dark) |
| Direction | `Directionality.of(context)`: flips the person's side and the ledger-line write direction |
| Motion allowed | `!MediaQuery.disableAnimationsOf(context)` |
| Text | `AppLocalizations.of(context)`: `appTitle`, `splashTagline`, `splashErrorMessage`, `commonRetry` |
