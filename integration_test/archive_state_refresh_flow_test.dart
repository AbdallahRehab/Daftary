import 'package:daftary/core/design_system/app_button.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/people/presentation/pages/archived_people_page.dart';
import 'package:daftary/features/people/presentation/widgets/person_list_tile.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end archive/unarchive reload flow (005-archive-state-refresh
/// quickstart.md Scenarios 1, 2, and 4). Runs against the real app (real
/// DI, real on-device SQLite) — mirrors
/// `integration_test/language_switch_flow_test.dart`'s pattern.
///
/// Each test filters the active/archived lists down to its own
/// uniquely-named person via the search box before interacting with it —
/// this repository's on-device database accumulates real and
/// previously-run-test data across sessions, and `ListView.builder` only
/// builds elements for rows within the current viewport, so an unfiltered
/// list can leave the row this test cares about unbuilt (and therefore
/// unfindable) without ever indicating an actual defect. Assertions use
/// finders scoped to the actual row widget (`PersonListTile`/`ListTile`),
/// not a bare `find.text(name)`, since the search box itself echoes the
/// typed query text as an `EditableText` that would otherwise also match.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> bootApp(WidgetTester tester) async {
    await getIt.reset();
    await configureDependencies();
    await getIt<SettingsCubit>().initialize();
    // Force a known-English baseline regardless of the simulator's device
    // locale or any language persisted by an earlier test run on this
    // same on-device database, so the l10n string matching below isn't
    // order/environment-dependent.
    await getIt<SettingsCubit>().changeLanguage(AppLanguage.english);
    appRouter.go('/people');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  Future<void> searchFor(
    WidgetTester tester,
    AppLocalizations l10n,
    String query,
  ) async {
    final searchField = find.ancestor(
      of: find.text(l10n.searchPeopleHint),
      matching: find.byType(TextField),
    );
    await tester.enterText(searchField, query);
    await tester.pumpAndSettle();
  }

  /// Creates a real, uniquely-named person via the Add Person flow (avoids
  /// collisions with any pre-existing on-device data across test runs),
  /// then returns to the active list (a successful save now auto-opens the
  /// new person's own detail screen — 005-archive-state-refresh T031/T032
  /// / FR-010) and filters it down to just that person.
  Future<String> addPerson(WidgetTester tester, AppLocalizations l10n) async {
    final name = 'ArchiveFlowTest${DateTime.now().microsecondsSinceEpoch}';
    await tester.tap(find.byTooltip(l10n.addPersonAction));
    await tester.pumpAndSettle();
    final nameField = find.ancestor(
      of: find.text(l10n.nameLabel),
      matching: find.byType(TextField),
    );
    await tester.enterText(nameField, name);
    await tester.tap(find.widgetWithText(AppButton, l10n.commonSave));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await searchFor(tester, l10n, name);
    return name;
  }

  Finder activeRowFor(String name) => find.widgetWithText(PersonListTile, name);

  Finder archiveButtonFor(String name) => find.descendant(
    of: activeRowFor(name),
    matching: find.byIcon(Icons.archive_outlined),
  );

  // The archived list's rows are plain `ListTile`s (`ArchivedPeoplePage`),
  // distinct from the active list's `PersonListTile`.
  Finder archivedRowFor(String name) => find.widgetWithText(ListTile, name);

  testWidgets(
    'unarchiving from the archived list makes the person reappear in the '
    'active list immediately, with no reload/navigation/restart (US1 MVP, '
    'Scenario 1)',
    (tester) async {
      await bootApp(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      final name = await addPerson(tester, l10n);
      expect(activeRowFor(name), findsOneWidget);

      // Archive from the active list (already-correct self-reload, per
      // research.md) — disappears from the active list, appears archived.
      await tester.tap(archiveButtonFor(name));
      await tester.pumpAndSettle();
      expect(activeRowFor(name), findsNothing);

      // Open the archived list and restore — this is the exact originally
      // reported bug's round trip (research.md Decision 1's root-cause
      // call site).
      await tester.tap(find.byTooltip(l10n.archivedPeopleAction));
      await tester.pumpAndSettle();
      expect(find.byType(ArchivedPeoplePage), findsOneWidget);
      await searchFor(tester, l10n, name);
      expect(archivedRowFor(name), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, l10n.restoreAction));
      await tester.pumpAndSettle();
      // Restored: disappears from the archived list it's currently on.
      expect(archivedRowFor(name), findsNothing);

      // Navigate back to the active list without any manual reload — the
      // person must already be visible again (FR-001, FR-004, SC-001,
      // SC-003, SC-005). The active list's own search term ("name",
      // preserved per FR-005) still scopes it to just this person.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(activeRowFor(name), findsOneWidget);
    },
  );

  testWidgets(
    'a rapid double-tap on the same person\'s archive control produces '
    'exactly one state transition, no flicker or duplicate row (Scenario 4, '
    'FR-006)',
    (tester) async {
      await bootApp(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      final name = await addPerson(tester, l10n);
      expect(activeRowFor(name), findsOneWidget);

      final archiveButton = archiveButtonFor(name);
      // First tap starts the archive() call (re-entrancy guard engages
      // before the repository call resolves); the second tap must be a
      // no-op since the control disables itself immediately.
      await tester.tap(archiveButton, warnIfMissed: false);
      await tester.tap(archiveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Exactly one archive happened: the row is gone, not duplicated or
      // left in a stuck/half-archived state.
      expect(activeRowFor(name), findsNothing);

      await tester.tap(find.byTooltip(l10n.archivedPeopleAction));
      await tester.pumpAndSettle();
      await searchFor(tester, l10n, name);
      expect(archivedRowFor(name), findsOneWidget);
    },
  );

  testWidgets(
    'opening a person\'s detail screen from the archived list and returning '
    'with no change does not stale-flash and reloads correctly (FR-008/'
    'FR-009)',
    (tester) async {
      await bootApp(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      final name = await addPerson(tester, l10n);
      await tester.tap(archiveButtonFor(name));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(l10n.archivedPeopleAction));
      await tester.pumpAndSettle();
      await searchFor(tester, l10n, name);
      expect(archivedRowFor(name), findsOneWidget);

      await tester.tap(archivedRowFor(name));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Still correctly on the archived list, still showing the person,
      // search term still applied — no stale flash, no accidental
      // disappearance from an unrelated reload.
      expect(find.byType(ArchivedPeoplePage), findsOneWidget);
      expect(archivedRowFor(name), findsOneWidget);
    },
  );
}
