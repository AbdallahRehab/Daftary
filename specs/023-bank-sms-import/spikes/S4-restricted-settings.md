# Spike S4: restricted settings inference and Play Protect in Egypt (T013, OQ5, OQ6)

**Status: NOT RUN — device required.** Real Android 14/15/16 devices (including an Egyptian-market OEM) and a device located in Egypt are needed. Nothing below was observed. T013 stays unchecked. OQ5 and OQ6 remain **open release gates** (owner-only).

## Questions

1. For a sideloaded install (GitHub release APK) on Android 15+, when READ_SMS is blocked by restricted settings, is the "no permission dialog was shown" inference reliable?
2. What are the exact App info steps to allow restricted settings on target devices?
3. (OQ5) Does Play Protect enhanced fraud protection block installing or updating an internet-sideloaded APK that declares SMS permissions on devices in Egypt?

## Default approach (already designated; adopted as the primary choice for T106, T108 and T119)

Source: research.md Decision 2, contracts/sms-platform-channel.md §2.3, contracts/ui-contract.md §3.2 and §3.7.

- `requestPermission()` returns `{granted, shouldShowRationale, dialogShown, sdkInt, installSource}`. `dialogShown` is true when the activity got `onPause` between the request and the result (the system dialog is a separate translucent activity).
- `installSource`: `getInstallSourceInfo().packageSource` on API 33+ (`PACKAGE_SOURCE_STORE` = store), otherwise `installingPackageName` against a small store list (Play, Samsung, Huawei, Xiaomi). `unknown` below API 30.
- Pure-Dart classifier:
  - granted → `granted`
  - not granted, `dialogShown == false`, `sdkInt >= 35`, install source not a store → `restrictedBlocked` (**inferred**)
  - not granted, `shouldShowRationale == false`, previously requested → `permanentlyDenied`
  - otherwise → `denied`
  - not granted after a prior grant → `revoked`
- An elapsed-time heuristic is only a secondary tie-break, never the sole signal.
- Guidance copy (ui-contract §3.2), never claiming certainty ("Android may be blocking this permission"):
  1. Open App info
  2. Open the overflow menu (three dots)
  3. Choose "Allow restricted settings"
  4. Come back and tap "Try again"
  An "Open App info" button (`AppSettings.openAppSettings()`, not wrapped in `runExternalActivity`). On resume the cubit re-checks status and advances if granted (FR-072). Paste/share fallback is always visible.
- OQ5 default (spec): **assume Play Protect may block**; verify before release.

## Fallback

- Inference wrong on a device (false `restrictedBlocked` or a missed one): keep the classifier but widen the copy so both paths are offered ("If no prompt appeared, Android may be blocking this permission. Show me how" plus "Try again"). The classifier stays pure Dart, so only its rule and its tests change.
- OEM uses different step wording or location: the numbered steps in the ARB copy are generic ("overflow menu (three dots)"); per-OEM wording is not added in v1.
- OQ5 fails (Play Protect blocks SMS-declaring sideloaded APKs in Egypt): ship two APKs (a standard SMS-free APK built with the switch off, and a "with bank SMS" APK with `DAFTARY_SMS_IMPORT=true`), or drop Android SMS reading in v1 and keep paste and share (spec OQ5 alternatives; plan release considerations). This is the owner's decision.

## What must be verified on a device

| # | Check | Expected / to record |
|---|---|---|
| 1 | Android 15 (and 16) device, APK installed from a browser download, tap Enable | No system dialog; result denied; classifier yields `restrictedBlocked` |
| 2 | Same device after "Allow restricted settings" | System dialog appears; grant succeeds; resume auto-advances |
| 3 | Android 14 device, same sideloaded install | Record whether restricted settings applies to READ_SMS on 14 (dialog shown or not) |
| 4 | Store-installed or `adb install` build | `installSource` classified correctly; no false `restrictedBlocked` |
| 5 | User denies twice ("Don't allow") | `permanentlyDenied`, not `restrictedBlocked` (dialog was shown) |
| 6 | OEM with a full-screen permission activity | `dialogShown` still true; App Lock not triggered (wrapped in `runExternalActivity`) |
| 7 | Exact on-screen wording and location of "Allow restricted settings" on Pixel, Samsung and one Egyptian-market OEM, English and Arabic system language | Record verbatim for T119 copy review |
| 8 | (OQ5) On a device in Egypt with Play Protect on: install and update an APK declaring READ_SMS from a browser download | Record whether install/update is blocked, warned or allowed |

Record device model, OS version, OEM skin, system language and install source for each row.

## Result

Not available. Until a device run, T106/T108 ship the inference as designated and T119 ships the generic four-step copy. OQ5 and OQ6 remain unresolved release gates.
