import 'dart:io';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/data_privacy/domain/usecases/export_user_data.dart';
import 'package:daftary/features/data_privacy/presentation/pages/data_export_page.dart';
import 'package:daftary/features/data_privacy/presentation/pages/delete_data_confirmation_page.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';
import 'package:daftary/core/money/money.dart';

/// 013 T054 — end-to-end coverage of Export (US2) and Delete (US3) against
/// the real app (real DI, real on-device SQLite), following quickstart.md
/// Scenarios 2 and 3.
///
/// The OS share sheet itself is platform UI the test driver cannot
/// dismiss, so share-cancel-returns-to-ready is covered by
/// `test/widget/data_export_page_test.dart` and
/// `test/features/data_privacy/presentation/cubit/export_cubit_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const uuid = Uuid();

  /// Rebuilds GetIt from scratch and boots the app in English, like
  /// `onboarding_flow_test.dart` does — each test starts from a clean
  /// singleton graph over the shared on-device database.
  Future<void> bootApp(WidgetTester tester, String location) async {
    await getIt.reset();
    await configureDependencies();
    await getIt<SettingsCubit>().initialize();
    await getIt<SettingsCubit>().changeLanguage(AppLanguage.english);
    await getIt<OnboardingCubit>().initialize();
    appRouter.go(location);
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  /// Seeds one person and one expense so both the export and the wipe have
  /// real rows to act on. Returns the unique person name for lookups.
  Future<String> seedData() async {
    final name = 'Privacy Seed ${uuid.v4().substring(0, 8)}';
    (await getIt<PeopleRepository>().createPerson(
      name: name,
    )).getOrElse((f) => throw StateError('seed person failed: $f'));

    final categories = (await getIt<CategoryRepository>().getCategories(
      type: FinanceEntryType.expense,
    )).getOrElse((f) => throw StateError('categories failed: $f'));
    (await getIt<FinanceRepository>().addEntry(
      idempotencyKey: uuid.v4(),
      categoryId: categories.first.id,
      type: FinanceEntryType.expense,
      amount: Money.egp(12345),
      date: DateTime.now(),
    )).getOrElse((f) => throw StateError('seed entry failed: $f'));
    return name;
  }

  Future<int> peopleCount(AppDatabase db) =>
      db.select(db.people).get().then((rows) => rows.length);

  Future<int> financeEntryCount(AppDatabase db) =>
      db.select(db.financeEntries).get().then((rows) => rows.length);

  Future<void> typePhraseAndDelete(
    WidgetTester tester,
    AppLocalizations l10n,
  ) async {
    await tester.enterText(
      find.byType(TextField),
      l10n.deleteDataConfirmPhrase,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.deleteDataConfirmAction));
    await tester.pumpAndSettle();
  }

  group('US2 — Export', () {
    testWidgets('generates a complete CSV containing every seeded record '
        '(Scenario 2, SC-003)', (tester) async {
      await bootApp(tester, '/overview');
      final name = await seedData();
      appRouter.go('/settings/export');
      await tester.pumpAndSettle();
      final l10n = await english();

      expect(find.byType(DataExportPage), findsOneWidget);
      await tester.tap(find.text(l10n.exportGenerateAction));
      await tester.pumpAndSettle();

      expect(find.text(l10n.exportReadyTitle), findsOneWidget);
      expect(find.text(l10n.exportShareAction), findsOneWidget);

      // Re-run the same use case the page used to read the produced file
      // directly — the UI only exposes it through the share sheet.
      final result = (await getIt<ExportUserData>()()).getOrElse(
        (f) => throw StateError('export failed: $f'),
      );
      final csv = await File(result.filePath).readAsString();
      expect(csv, contains(name));
      expect(csv, contains('12345'));
      final db = getIt<AppDatabase>();
      expect(result.sectionCounts['People'], await peopleCount(db));
      expect(
        result.sectionCounts['FinanceEntries'],
        await financeEntryCount(db),
      );
    });
  });

  group('US3 — Delete', () {
    testWidgets('a forced mid-wipe failure shows the error and loses no data '
        '(SC-005)', (tester) async {
      await bootApp(tester, '/overview');
      await seedData();
      final db = getIt<AppDatabase>();
      final peopleBefore = await peopleCount(db);
      final entriesBefore = await financeEntryCount(db);

      await db.customStatement('''
        CREATE TRIGGER it_force_wipe_failure BEFORE DELETE ON finance_entries
        BEGIN SELECT RAISE(ABORT, 'forced mid-wipe failure'); END;
      ''');
      addTearDown(
        () =>
            db.customStatement('DROP TRIGGER IF EXISTS it_force_wipe_failure'),
      );

      appRouter.go('/settings/delete-data');
      await tester.pumpAndSettle();
      final l10n = await english();
      await typePhraseAndDelete(tester, l10n);

      expect(find.byType(DeleteDataConfirmationPage), findsOneWidget);
      expect(find.text(l10n.deleteDataError), findsOneWidget);
      expect(await peopleCount(db), peopleBefore);
      expect(await financeEntryCount(db), entriesBefore);
    });

    testWidgets('typing the phrase and confirming wipes everything and '
        'returns to onboarding (Scenario 3)', (tester) async {
      await bootApp(tester, '/overview');
      await seedData();

      appRouter.go('/settings');
      await tester.pumpAndSettle();
      final l10n = await english();

      final tile = find.text(l10n.settingsDeleteDataTile);
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.byType(DeleteDataConfirmationPage), findsOneWidget);
      expect(find.text(l10n.deleteDataWarningMessage), findsOneWidget);

      await typePhraseAndDelete(tester, l10n);

      expect(find.byType(OnboardingPage), findsOneWidget);
      final db = getIt<AppDatabase>();
      expect(await peopleCount(db), 0);
      expect(await financeEntryCount(db), 0);
      expect(await db.select(db.moneyTransactions).get(), isEmpty);
      // Default categories are re-seeded, matching a fresh install.
      expect(await db.select(db.financeCategories).get(), isNotEmpty);
    });
  });
}
