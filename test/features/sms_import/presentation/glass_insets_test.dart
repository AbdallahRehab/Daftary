import 'package:daftary/core/design_system/glass/app_navigation_bar.dart';
import 'package:daftary/core/design_system/glass/app_scaffold.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/sms_import/data/platform/system_clipboard_reader.dart';
import 'package:daftary/features/sms_import/domain/entities/merchant_category_mapping.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/usecases/clear_learned_mappings.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_pasted_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_shared_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/read_clipboard_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/remove_learned_mapping.dart';
import 'package:daftary/features/sms_import/domain/usecases/undo_ignore.dart';
import 'package:daftary/features/sms_import/domain/usecases/unmute_sender.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_learned_mappings.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_muted_senders.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_undo_list.dart';
import 'package:daftary/features/sms_import/presentation/cubit/ignored_imports_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/learned_categories_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/muted_senders_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/paste_cubit.dart';
import 'package:daftary/features/sms_import/presentation/pages/bank_messages_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/bank_messages_settings_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/enable_bank_messages_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/ignored_imports_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/import_review_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/learned_categories_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/muted_senders_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/paste_bank_message_page.dart';
import 'package:daftary/features/sms_import/presentation/shared_text_inbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../core/design_system/glass/glass_test_harness.dart';
import '../helpers/builders.dart';
import '../helpers/fakes.dart';
import '../helpers/review_harness.dart';
import '../helpers/scan_presentation.dart';
import '../helpers/widget_harness.dart';

class _MockImportPasted extends Mock implements ImportPastedText {}

class _MockImportShared extends Mock implements ImportSharedText {}

/// Regression for the glass-ON layout bug found by T158 (FR-095,
/// ui-contract §3.4): with Liquid Glass ON (the shipped default) an
/// `AppScaffold` body runs beneath the shell's glass bars, so each 023
/// page's scrollable must add `AppGlassInsets.of(context)` to its padding.
/// Every page is hosted in the shell's frame (an `AppScaffold` with an
/// `AppNavigationBar`) on a 390×844 phone; its main list is scrolled to the
/// end and the last item must sit above the bottom bar, and the first item
/// must start below the top bar. Synthetic data only.
void main() {
  final clock = FixedClock(DateTime(2026, 3, 10, 12));
  var navTaps = 0;

  Widget shell(Widget page) => AppScaffold(
    body: page,
    bottomNavigationBar: AppNavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (_) => navTaps++,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    ),
  );

  Future<void> pumpGlass(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    navTaps = 0;
    await pumpSmsPage(tester, page, glass: onStyle, frame: shell);
    expect(tester.takeException(), isNull);
  }

  Rect navBar(WidgetTester tester) =>
      tester.getRect(find.byType(AppNavigationBar));

  Rect topBar(WidgetTester tester) => tester.getRect(find.byType(AppBar).last);

  /// The page's main vertical list (the outermost one under the page).
  Finder mainList(Type pageType) => find
      .descendant(of: find.byType(pageType), matching: find.byType(ListView))
      .first;

  /// Jumps [list] to its end, repeating while lazily built children grow
  /// the extent.
  Future<void> scrollToEnd(WidgetTester tester, Finder list) async {
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    for (var i = 0; i < 20; i++) {
      final position = scrollable.position;
      if (position.pixels >= position.maxScrollExtent) break;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
  }

  Widget lastChild(WidgetTester tester, Finder list) {
    final delegate =
        tester.widget<ListView>(list).childrenDelegate
            as SliverChildListDelegate;
    return delegate.children.last;
  }

  Widget firstChild(WidgetTester tester, Finder list) {
    final delegate =
        tester.widget<ListView>(list).childrenDelegate
            as SliverChildListDelegate;
    return delegate.children.first;
  }

  /// The checks every page shares: first item clear of the top bar at
  /// rest, last item clear of the bottom bar at the end of the list.
  Future<void> expectClearOfBars(WidgetTester tester, Type pageType) async {
    final list = mainList(pageType);
    expect(list, findsOneWidget);

    final first = find.byWidget(firstChild(tester, list));
    expect(
      tester.getRect(first).top,
      greaterThanOrEqualTo(topBar(tester).bottom),
      reason: '$pageType: first item under the glass top bar',
    );

    await scrollToEnd(tester, list);
    final last = find.byWidget(lastChild(tester, list));
    expect(
      tester.getRect(last).bottom,
      lessThanOrEqualTo(navBar(tester).top),
      reason: '$pageType: last item under the glass bottom bar',
    );
    expect(tester.takeException(), isNull);
  }

  group('Liquid Glass ON inside the shell', () {
    testWidgets('review: Add and Ignore sit above the bottom bar and are '
        'hit-testable', (tester) async {
      final harness = ReviewHarness();
      addTearDown(harness.dispose);
      harness.repository.seed([buildPendingImport()]);
      await pumpGlass(
        tester,
        ImportReviewPage(importId: 'pending-1', cubit: harness.build()),
      );

      await expectClearOfBars(tester, ImportReviewPage);
      for (final key in const ['import_review_add', 'import_review_ignore']) {
        final button = find.byKey(ValueKey(key));
        expect(button, findsOneWidget);
        expect(
          tester.getRect(button).bottom,
          lessThanOrEqualTo(navBar(tester).top),
          reason: key,
        );
        expect(button.hitTestable(), findsOneWidget, reason: key);
      }
      // A tap on Ignore reaches Ignore, not the bar beneath it.
      await tester.tap(find.byKey(const ValueKey('import_review_ignore')));
      await tester.pumpAndSettle();
      expect(navTaps, 0);
    });

    testWidgets('bank messages hub (list)', (tester) async {
      final repository = FakeSmsImportRepository(clock: clock);
      final deps = HubScanDeps(
        capability: true,
        settings: FakeSmsImportSettingsRepository(
          settings: const SmsImportSettings(isEnabled: true),
        ),
      );
      deps.permissions.status = SmsPermissionStatus.granted;
      addTearDown(repository.close);
      addTearDown(deps.settings.close);
      repository.seed([
        for (var i = 0; i < 8; i++)
          buildPendingImport(id: 'p$i', fingerprint: 'fp$i'),
      ]);
      await pumpGlass(
        tester,
        BankMessagesPage(
          cubit: buildBankMessagesCubit(repository, clock, deps: deps),
        ),
      );
      await expectClearOfBars(tester, BankMessagesPage);
    });

    testWidgets('bank messages hub (empty): action above the bottom bar', (
      tester,
    ) async {
      final repository = FakeSmsImportRepository(clock: clock);
      final deps = HubScanDeps();
      addTearDown(repository.close);
      addTearDown(deps.settings.close);
      await pumpGlass(
        tester,
        BankMessagesPage(
          cubit: buildBankMessagesCubit(repository, clock, deps: deps),
        ),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      final action = find.text(l10n.smsImportPasteTitle);
      expect(action, findsOneWidget);
      expect(
        tester.getRect(action).bottom,
        lessThanOrEqualTo(navBar(tester).top),
      );
      expect(
        tester.getRect(action).top,
        greaterThanOrEqualTo(topBar(tester).bottom),
      );
    });

    testWidgets('paste', (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (_) async => null,
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final inbox = SharedTextInbox();
      addTearDown(inbox.dispose);
      await pumpGlass(
        tester,
        PasteBankMessagePage(
          cubit: PasteCubit(
            ReadClipboardText(const SystemClipboardReader()),
            _MockImportPasted(),
            _MockImportShared(),
            inbox,
          ),
        ),
      );
      await expectClearOfBars(tester, PasteBankMessagePage);
    });

    testWidgets('enable (explain step)', (tester) async {
      final deps = HubScanDeps(capability: true);
      final repository = FakeSmsImportRepository();
      addTearDown(deps.settings.close);
      addTearDown(repository.close);
      await pumpGlass(
        tester,
        EnableBankMessagesPage(
          cubit: buildEnableFlowCubit(deps, repository: repository),
        ),
      );
      await expectClearOfBars(tester, EnableBankMessagesPage);
    });

    testWidgets('settings', (tester) async {
      final deps = HubScanDeps(
        capability: true,
        settings: FakeSmsImportSettingsRepository(
          settings: const SmsImportSettings(isEnabled: true),
        ),
      );
      deps.permissions.status = SmsPermissionStatus.granted;
      addTearDown(deps.settings.close);
      await pumpGlass(
        tester,
        BankMessagesSettingsPage(cubit: buildSettingsCubit(deps)),
      );
      await expectClearOfBars(tester, BankMessagesSettingsPage);
    });

    testWidgets('ignored', (tester) async {
      final repository = FakeSmsImportRepository(clock: clock);
      final deps = HubScanDeps(capability: true);
      addTearDown(repository.close);
      addTearDown(deps.settings.close);
      repository.seed([
        for (var i = 0; i < 10; i++)
          buildPendingImport(
            id: 'i$i',
            fingerprint: 'i$i',
            status: SmsImportStatus.ignored,
            decidedAt: clock.now().subtract(Duration(days: 1 + i % 5)),
            hasRawText: false,
          ),
      ]);
      await pumpGlass(
        tester,
        IgnoredImportsPage(
          cubit: IgnoredImportsCubit(
            WatchUndoList(repository),
            UndoIgnore(repository),
            GetSmsCapability(deps.gateway),
            clock,
          ),
        ),
      );
      await expectClearOfBars(tester, IgnoredImportsPage);
    });

    testWidgets('muted senders', (tester) async {
      final settings = FakeSmsImportSettingsRepository();
      addTearDown(settings.close);
      for (var i = 0; i < 15; i++) {
        settings.mutedSenders.add('EXAMPLEBANK$i');
      }
      await pumpGlass(
        tester,
        MutedSendersPage(
          cubit: MutedSendersCubit(
            WatchMutedSenders(settings),
            UnmuteSender(settings),
          ),
        ),
      );
      await expectClearOfBars(tester, MutedSendersPage);
    });

    testWidgets('learned categories', (tester) async {
      final settings = FakeSmsImportSettingsRepository();
      addTearDown(settings.close);
      final categories = FakeCategoryRepository([
        testCategory('seed_groceries', FinanceEntryType.expense, name: 'Food'),
      ]);
      for (var i = 0; i < 15; i++) {
        final m = MerchantCategoryMapping(
          merchantKey: 'example merchant $i',
          entryType: FinanceEntryType.expense,
          categoryId: 'seed_groceries',
          updatedAt: DateTime(2026, 3, 4),
        );
        settings.mappings[(m.merchantKey, m.entryType.dbValue)] = m;
      }
      await pumpGlass(
        tester,
        LearnedCategoriesPage(
          cubit: LearnedCategoriesCubit(
            WatchLearnedMappings(settings),
            RemoveLearnedMapping(settings),
            ClearLearnedMappings(settings),
            GetCategories(categories),
          ),
        ),
      );
      await expectClearOfBars(tester, LearnedCategoriesPage);
    });
  });
}
