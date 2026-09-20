import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end language switch + restart-persistence flow (User Stories
/// 1-2; quickstart.md scenarios 1-2). Run against the real app (real DI,
/// real on-device SQLite).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// (Re)builds GetIt's singletons from scratch — a fresh `SettingsCubit`,
  /// `AppDatabase`, etc. — then resolves the initial language exactly like
  /// `main()` does. The underlying SQLite file on disk is unaffected, so
  /// calling this after a language change simulates a real app restart:
  /// the new "session" only knows what was actually persisted.
  Future<void> bootApp(WidgetTester tester) async {
    await getIt.reset();
    await configureDependencies();
    await getIt<SettingsCubit>().initialize();
    appRouter.go('/people');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  // The Settings tab's `NavigationDestination` label and `SettingsPage`'s
  // `AppBar` title use the same ARB key, so a plain `find.text(...)` for
  // "Settings" matches both — scope to the nav bar specifically.
  Finder settingsTabFinder(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  Finder appBarTitleFinder(String label) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(label));

  testWidgets(
    'switching language live-updates the UI, and survives a simulated '
    'restart, in both directions (US1, US2)',
    (tester) async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final ar = await AppLocalizations.delegate.load(const Locale('ar'));

      // Start from a known baseline: force English first regardless of
      // the simulator's own device locale, so the rest of this test isn't
      // order/environment-dependent.
      await bootApp(tester);
      await tester.tap(settingsTabFinder(en.settingsTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.languageEnglish));
      await tester.pumpAndSettle();

      // --- Switch to Arabic ---
      await tester.tap(find.text(en.languageArabic));
      await tester.pumpAndSettle();

      // Live switch (FR-004): no restart, the Settings tab itself is
      // already re-rendered in Arabic/RTL.
      expect(appBarTitleFinder(ar.settingsTitle), findsOneWidget);
      expect(
        Directionality.of(tester.element(appBarTitleFinder(ar.settingsTitle))),
        TextDirection.rtl,
      );

      await bootApp(tester);

      // Restart-persistence (FR-005): opens directly in Arabic/RTL, no
      // language selection needed.
      expect(find.text(ar.peopleListTitle), findsWidgets);
      expect(
        Directionality.of(tester.element(find.text(ar.peopleListTitle).first)),
        TextDirection.rtl,
      );

      // --- Switch back to English ---
      await tester.tap(settingsTabFinder(ar.settingsTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ar.languageEnglish));
      await tester.pumpAndSettle();

      expect(appBarTitleFinder(en.settingsTitle), findsOneWidget);
      expect(
        Directionality.of(tester.element(appBarTitleFinder(en.settingsTitle))),
        TextDirection.ltr,
      );

      await bootApp(tester);

      expect(find.text(en.peopleListTitle), findsWidgets);
      expect(
        Directionality.of(tester.element(find.text(en.peopleListTitle).first)),
        TextDirection.ltr,
      );
    },
  );

  testWidgets(
    'full-app correctness under Arabic/RTL: recording a transaction with a '
    'Latin-script name renders Arabic UI text and Western-digit amounts/'
    'dates, with the name legible inline (US3; quickstart.md scenario 3)',
    (tester) async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final ar = await AppLocalizations.delegate.load(const Locale('ar'));
      final eastenArabicDigits = RegExp(r'[٠-٩]');
      final name = 'Flow Latin ${DateTime.now().millisecondsSinceEpoch}';

      await bootApp(tester);
      await tester.tap(settingsTabFinder(en.settingsTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.languageArabic));
      await tester.pumpAndSettle();

      // Back to the People tab (now mirrored) and record a transaction.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(ar.peopleListTitle),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(ar.recordTransactionAction));
      await tester.pumpAndSettle();

      // Every label on this form should already be Arabic — no leftover
      // English strings (FR-010).
      expect(find.text(ar.personLabel), findsOneWidget);
      expect(find.text(ar.amountLabel), findsOneWidget);
      expect(find.text(ar.dateLabel), findsOneWidget);
      expect(find.text(en.personLabel), findsNothing);
      expect(find.text(en.amountLabel), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, ar.personLabel),
        name,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(ar.createPersonInlineAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ar.directionReceived));
      await tester.enterText(
        find.widgetWithText(TextField, ar.amountLabel),
        '2000',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text(ar.commonSave));
      await tester.pumpAndSettle();

      // Landed on PersonDetailPage, still in Arabic/RTL, with the
      // Latin-script name rendered legibly (Flutter's Unicode bidi
      // algorithm keeps the Latin run intact within the RTL paragraph).
      expect(find.text(name), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text(name))),
        TextDirection.rtl,
      );

      // The amount and date on this page use Western digits (0-9) only,
      // never Eastern Arabic-Indic glyphs (FR-011).
      final amountTexts = tester
          .widgetList<Text>(find.textContaining('2,000.00'))
          .toList();
      expect(amountTexts, isNotEmpty);
      for (final widget in amountTexts) {
        expect(eastenArabicDigits.hasMatch(widget.data ?? ''), isFalse);
      }
      final offending = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where(eastenArabicDigits.hasMatch)
          .toList();
      expect(offending, isEmpty);
    },
  );
}
