import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end theme switch flow (User Stories 1-3; quickstart.md's theme
/// scenarios). Run against the real app (real DI, real on-device SQLite).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// (Re)builds GetIt's singletons from scratch — a fresh `SettingsCubit`,
  /// `AppDatabase`, etc. — then resolves the initial theme exactly like
  /// `main()` does. The underlying SQLite file on disk is unaffected, so
  /// calling this after a theme change simulates a real app restart: the
  /// new "session" only knows what was actually persisted.
  Future<void> bootApp(WidgetTester tester) async {
    await getIt.reset();
    await configureDependencies();
    await getIt<SettingsCubit>().initialize();
    appRouter.go('/people');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  Finder settingsTabFinder(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  Brightness currentBrightness(WidgetTester tester) {
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final context = tester.element(find.byWidget(scaffold));
    return Theme.of(context).brightness;
  }

  testWidgets(
    'selecting Dark live-updates every reachable screen with no restart, '
    'and selecting Light again reverts with no regression (US1)',
    (tester) async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));

      await bootApp(tester);
      await tester.tap(settingsTabFinder(en.settingsTitle));
      await tester.pumpAndSettle();

      // Baseline: Light theme (whatever the resolved starting mode is,
      // this app instance is fresh so it hasn't been touched yet).
      await tester.tap(find.text(en.themeLight));
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.light);

      // --- Switch to Dark ---
      await tester.tap(find.text(en.themeDark));
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.dark);

      // Still Dark after navigating to People and Overview — no restart,
      // no per-screen flash of Light.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(en.peopleListTitle),
        ),
      );
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.dark);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(en.overviewTitle),
        ),
      );
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.dark);

      // --- Switch back to Light: no regression ---
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(en.settingsTitle),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.themeLight));
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.light);
    },
  );

  testWidgets(
    'the theme choice survives a simulated restart, for both Dark and '
    'Light (US2)',
    (tester) async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));

      await bootApp(tester);
      await tester.tap(settingsTabFinder(en.settingsTitle));
      await tester.pumpAndSettle();

      await tester.tap(find.text(en.themeDark));
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.dark);

      await bootApp(tester);

      // Launches directly in Dark — no manual re-selection needed.
      expect(currentBrightness(tester), Brightness.dark);

      await tester.tap(settingsTabFinder(en.settingsTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.themeLight));
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.light);

      await bootApp(tester);

      expect(currentBrightness(tester), Brightness.light);
    },
  );

  testWidgets(
    'System Default follows a live platform-brightness change while open, '
    'and persists as "system" rather than a frozen snapshot across a '
    'simulated restart (US3)',
    (tester) async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await bootApp(tester);
      await tester.tap(settingsTabFinder(en.settingsTitle));
      await tester.pumpAndSettle();

      await tester.tap(find.text(en.themeSystemDefault));
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.light);

      // Live platform-brightness change while the app is open (FR-002):
      // no manual re-selection, Flutter's own ThemeMode.system branch
      // re-resolves on the next frame.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(currentBrightness(tester), Brightness.dark);

      // Restart with the device now on Dark: reflects the *current*
      // system theme, not a frozen Light snapshot from the earlier
      // selection (Edge Case / Acceptance Scenario 2).
      await bootApp(tester);
      expect(currentBrightness(tester), Brightness.dark);

      // And if the device flips back to Light before the next restart,
      // "system" (not a resolved value) is what was actually persisted.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await bootApp(tester);
      expect(currentBrightness(tester), Brightness.light);
    },
  );
}
