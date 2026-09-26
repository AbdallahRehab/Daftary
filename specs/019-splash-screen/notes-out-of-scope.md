# 019 Splash Screen — Out-of-scope notes

Issues found during implementation that are unrelated to the splash screen. Recorded, not fixed.

- **Android build JDK mismatch (machine setup):** `flutter build apk` selects Java 25, which the project's Gradle version does not support ("compatible Gradle versions for Java 25.0.3 are 9.1.0 or newer"). Worked around for 019 verification by running `./gradlew assembleDebug` with `JAVA_HOME` set to JDK 21. Fix separately via `flutter config --jdk-dir` or a Gradle upgrade. Unrelated to the splash.
- **Kotlin/AGP deprecation warnings:** Flutter warns that Kotlin 2.2.20 support will be dropped soon (upgrade to at least 2.3.20). Pre-existing; unrelated.
- **Flutter migrator edits `android/gradle.properties`:** a Gradle build via the Flutter plugin adds `android.builtInKotlin=false` and `android.newDsl=false`. Reverted to keep 019 in scope; adopting them is a separate toolchain decision.
- **Pre-existing integration test failures (confirmed on the pre-019 baseline, `HEAD` `51fc87c`, iPhone 17 simulator, identical errors):**
  - `onboarding_flow_test.dart` (6 tests): `l10nOf()` calls `AppLocalizations.of(tester.element(find.byType(DaftaryApp)))!`. `DaftaryApp`'s element sits above `MaterialApp`'s `Localizations`, so this is always null ("Null check operator used on a null value"). Fix: look up from an element below `MaterialApp`.
  - `archive_state_refresh_flow_test.dart` (3 tests): active-list `PersonListTile` for the newly added person not found.
  - `money_relationships_flows_test.dart` (1 test): the 60 fps scroll test finds no `ListView` on `PersonDetailPage`.
