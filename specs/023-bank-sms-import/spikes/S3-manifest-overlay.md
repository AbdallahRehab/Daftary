# Spike S3: READ_SMS manifest overlay mechanism (T012)

**Status: NOT RUN — device required.** Per the orchestrator, S3 is grouped with the device spikes and was not executed in this environment (no Gradle build of the release manifest was run here). Nothing below was observed. T012 stays unchecked.

Note: unlike S1, S2, S4 and S5, S3 needs only an Android SDK and a Gradle build, not a physical device. It can be run on any workstation or CI runner with the Android SDK.

## Question

With AGP 8.11.1 (`android/settings.gradle.kts:22`), does `androidComponents.onVariants { it.sources.manifests.addStaticManifestFile(...) }` make a READ_SMS-only overlay file appear in the output of `:app:processReleaseMainManifest`? If not, the manifest-only `:sms_capability` library module is used.

## Default approach (already designated; adopted as the primary choice for T104)

Source: research.md Decision 3; AGENT_BRIEFING "Capability switch (CHK013)".

- One switch, read by Gradle only: `providers.environmentVariable("DAFTARY_SMS_IMPORT").orNull == "true"`, with the `-Pdaftary.smsImport=true` Gradle property fallback (configuration-cache safe). No Dart const, no `--dart-define`.
- Primary mechanism: when the switch is on, `androidComponents.onVariants { variant -> variant.sources.manifests.addStaticManifestFile("sms_capability/AndroidManifest.xml") }` in `android/app/build.gradle.kts`, with `android/app/sms_capability/AndroidManifest.xml` containing only `<uses-permission android:name="android.permission.READ_SMS"/>`. No module, no hard-coded `compileSdk`.
- The main manifest never mentions READ_SMS. It carries `tools:node="remove"` for RECEIVE_SMS, SEND_SMS, RECEIVE_MMS, RECEIVE_WAP_PUSH, WRITE_SMS and READ_PHONE_STATE.
- Dart reads `readSmsDeclared` from `getCapabilities` (`PackageInfo.requestedPermissions`).
- Default is off.

## Fallback

Manifest-only library module `:sms_capability`:
- `android/sms_capability/build.gradle.kts` (`com.android.library`, `namespace`, `compileSdk = 36` hardcoded to match `FlutterExtension`, or read from `rootProject.extra`) and `android/sms_capability/src/main/AndroidManifest.xml` (READ_SMS only).
- `android/settings.gradle.kts` always `include(":sms_capability")`.
- `android/app/build.gradle.kts` adds `implementation(project(":sms_capability"))` only when the switch is on.

## Merged-manifest path for T105 (to be re-verified)

`android/app/build/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml` (from research Decision 3, "re-verified at implementation"). T105's `tool/check_merged_manifest.sh` should locate the file with a `find` under `app/build/intermediates/merged_manifest/release/` rather than hard-coding the subdirectory, so an AGP layout change fails loudly ("file not found") instead of silently passing.

## What must be verified

| # | Check | Expected |
|---|---|---|
| 1 | `./gradlew :app:processReleaseMainManifest` with the env unset; grep the merged manifest | No `READ_SMS`, no `android.permission.*SMS*` |
| 2 | Same with `DAFTARY_SMS_IMPORT=true` | Exactly one `READ_SMS`; no RECEIVE_SMS/SEND_SMS/READ_PHONE_STATE |
| 3 | Same with `-Pdaftary.smsImport=true` and env unset | Same as 2 |
| 4 | Toggle the switch between two builds with the configuration cache on | The manifest follows the switch (no stale cache) |
| 5 | Debug and profile variants | Their own `src/<type>/AndroidManifest.xml` content (INTERNET) is kept |
| 6 | `flutter build apk` (universal and `--split-per-abi`) + `aapt dump permissions` | Matches 1/2 |
| 7 | Exact merged-manifest file path for AGP 8.11.1 | Written here for T105 |

## Result

Not available. Until a build run, T104 implements the AGP static-manifest overlay as designated, and T105's script verifies it (and fails if the overlay does not reach the merged manifest, which is the signal to switch to the module fallback).

## Observed during T104/T105 (workstation build, no device)

These are build-only checks, run on macOS with AGP 8.11.1, Gradle 8.14 and Flutter 3.47.0. T012 stays unchecked because the orchestrator groups S3 with the device spikes, and checks 4 (configuration cache on) and 6 (`--split-per-abi`) were not run.

- Check 1: `./gradlew :app:processDebugMainManifest` and `:app:processReleaseMainManifest` with the env unset gave no `READ_SMS` and no SMS permission.
- Check 2: with `DAFTARY_SMS_IMPORT=true`, exactly one `READ_SMS` and nothing else SMS-related.
- Check 3: with `-Pdaftary.smsImport=true` and the env unset, exactly one `READ_SMS`.
- Toggling back to unset gave 0 `READ_SMS`. The configuration cache is off in this project.
- The primary mechanism, `variant.sources.manifests.addStaticManifestFile(...)`, works, so the fallback module is not needed.
- Check 6 was partly run: `flutter build apk --debug` both ways, then `aapt dump permissions` on the capability APK listed `READ_SMS` and no RECEIVE_SMS, SEND_SMS or READ_PHONE_STATE.
- Check 7: the merged manifest is at `build/app/intermediates/merged_manifest/<variant>/process<Variant>MainManifest/AndroidManifest.xml`. The directory also holds `output<Variant>AppLinkSettings/AndroidManifest.xml`, so `tool/check_merged_manifest.sh` selects the `process<Variant>MainManifest` file.
