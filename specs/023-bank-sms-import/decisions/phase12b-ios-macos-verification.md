# Phase 12b — T159 iOS / macOS verification

Date: 2026-10-12. Branch `023-bank-sms-import`. Toolchain: fvm Flutter 3.47.0.

## 1. Zero diff in ios/ and macos/

- `git merge-base main HEAD` = `4a5565d` = `HEAD` = `main`. The branch has no commits of its own yet; all 023 work is uncommitted in the working tree.
- `git diff --stat main -- ios macos`: empty (this covers committed and working-tree changes).
- `git status --porcelain ios macos`: empty, so there are no untracked or modified files. This was checked before the builds and again after them.
- `git status --porcelain --ignored ios macos` shows only the usual gitignored generated files: `.symlinks/`, `Pods/`, `Flutter/ephemeral/`, `Generated.xcconfig`, `GeneratedPluginRegistrant.{h,m}`, `flutter_export_environment.sh`, `Flutter.podspec`.
- Podfile.lock: the only recent Podfile.lock change is commit `4a5565d` ("chore(macos): update Podfile.lock", removing 6 lines). That commit is the merge-base and is already on `main`. It predates 023 and has nothing to do with SMS. There is no Podfile.lock diff against `main`.
- A grep for `sms|bank.?message` across ios/ and macos/ (excluding Pods, build output and ephemeral files) finds no matches.
- Files checked unchanged: `ios/Runner/{AppDelegate.swift, Info.plist, SecurityPlugin.swift, Runner-Bridging-Header.h}`, `macos/Runner/{Info.plist, DebugProfile.entitlements, Release.entitlements, AppDelegate.swift, MainFlutterWindow.swift}`. There are no iOS entitlements files and no extensions.
- The only new dependency in 023 is `pointycastle` (pure Dart, already resolved transitively and now listed directly in pubspec.yaml). It adds no native plugin, so the plugin registrants and Podfiles stay unchanged.

## 2. macOS build

`fvm flutter build macos --debug` produced `✓ Built build/macos/Build/Products/Debug/daftary.app`.

The first attempt failed. `lib/core/di/injection.config.dart` was stale against constructors the concurrent presentation agent was editing (`BankMessagesHomeCubit` expected 3 arguments and got 2; `BankMessagesCubit` expected 10 and got 9). I edited nothing. I polled `dart analyze` until those errors were gone (about 10 minutes), then rebuilt successfully.

## 3. iOS build

`fvm flutter build ios --simulator --debug --no-codesign` produced `✓ Built build/ios/iphonesimulator/Runner.app` (Xcode build took about 597 s). The only warning: the google_mlkit plugins don't support Swift Package Manager. This warning is pre-existing and unrelated to SMS.

## 4. "iOS paste works"

- Verified: `fvm flutter test test/features/sms_import/presentation/pages/paste_bank_message_page_test.dart` passed all 19 tests, including the storage-failure case, the ar/en × RTL/LTR × light/dark matrix and 200% text scaling.
- Not verified: I did not install or run the app in an iOS Simulator, so there was no manual paste walkthrough on a simulator. Simulators are available (iOS 26.4/26.5) but none was booted. The task brief accepts a successful simulator build plus the paste widget tests as evidence. A real-device or simulator walkthrough stays with the owner under T160.

## Result

There is zero SMS-related diff in ios/ and macos/, and both builds succeed. T159 is marked [X], with the caveat in section 4 that paste was verified by widget tests rather than an interactive simulator run.
