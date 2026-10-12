import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/dashboard/presentation/widgets/bank_messages_home_card.dart';
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

import '../helpers/builders.dart';
import '../helpers/fakes.dart';
import '../helpers/review_harness.dart';
import '../helpers/scan_presentation.dart';
import '../helpers/widget_harness.dart';

class _MockImportPasted extends Mock implements ImportPastedText {}

class _MockImportShared extends Mock implements ImportSharedText {}

/// One screen of the matrix: [pump] builds it (with its own fakes, closed
/// through `addTearDown`), [check] asserts its key semantics.
typedef _Screen = ({
  String name,
  Future<void> Function(
    WidgetTester tester,
    Locale locale,
    ThemeData theme,
    double textScale,
  )
  pump,
  void Function(WidgetTester tester, AppLocalizations l10n) check,
});

/// T156 — every new 023 screen in RTL x LTR x light x dark at 200% text:
/// no overflow or exception, the reading direction follows the locale and
/// each screen exposes its key semantics (ui-contract §7, §8.7). Synthetic
/// data only.
void main() {
  final clock = FixedClock(DateTime(2026, 3, 10, 12));

  /// A phone-sized surface, so 200% text is a real stress.
  void phoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  bool hasLabel(WidgetTester tester, Finder finder, String text) {
    final node = tester.getSemantics(finder);
    return node.label.contains(text) ||
        node.tooltip.contains(text) ||
        node.hint.contains(text);
  }

  final screens = <_Screen>[
    (
      name: 'bank messages hub',
      pump: (tester, locale, theme, scale) async {
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
          buildPendingImport(),
          buildPendingImport(
            id: 'pending-2',
            fingerprint: 'fp-2',
            amount: null,
            candidates: [100, 200],
            suggestedType: SuggestedRecordType.unset,
            merchant: 'متجر المثال بالاسم الطويل جدا',
            warnings: {SmsWarning.possibleDuplicate},
          ),
        ]);
        await pumpSmsPage(
          tester,
          BankMessagesPage(
            cubit: buildBankMessagesCubit(repository, clock, deps: deps),
          ),
          locale: locale,
          theme: theme,
          textScale: scale,
        );
      },
      check: (tester, l10n) {
        final card = find.byKey(
          const ValueKey('pending_import_card_pending-1'),
        );
        expect(card, findsOneWidget);
        final node = tester.getSemantics(card);
        expect(node.label, contains(l10n.financeTypeExpense));
        expect(node.hint, l10n.smsImportSemanticsOpenReview);
      },
    ),
    (
      name: 'review',
      pump: (tester, locale, theme, scale) async {
        final harness = ReviewHarness();
        addTearDown(harness.dispose);
        harness.repository.seed([buildPendingImport()]);
        await pumpSmsPage(
          tester,
          ImportReviewPage(importId: 'pending-1', cubit: harness.build()),
          locale: locale,
          theme: theme,
          textScale: scale,
        );
      },
      check: (tester, l10n) {
        expect(find.text(l10n.smsImportReviewTitle), findsWidgets);
        expect(
          find.bySemanticsLabel(
            RegExp(RegExp.escape(l10n.smsImportReviewTypeLabel)),
          ),
          findsWidgets,
        );
      },
    ),
    (
      name: 'paste',
      pump: (tester, locale, theme, scale) async {
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (_) async => null,
        );
        addTearDown(
          () =>
              messenger.setMockMethodCallHandler(SystemChannels.platform, null),
        );
        final inbox = SharedTextInbox();
        addTearDown(inbox.dispose);
        await pumpSmsPage(
          tester,
          PasteBankMessagePage(
            cubit: PasteCubit(
              ReadClipboardText(const SystemClipboardReader()),
              _MockImportPasted(),
              _MockImportShared(),
              inbox,
            ),
          ),
          locale: locale,
          theme: theme,
          textScale: scale,
        );
      },
      check: (tester, l10n) {
        expect(find.text(l10n.smsImportPasteTitle), findsWidgets);
        expect(
          find.byKey(const ValueKey('paste_bank_message_field')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            RegExp(RegExp.escape(l10n.smsImportPasteFieldLabel)),
          ),
          findsWidgets,
        );
      },
    ),
    (
      name: 'enable',
      pump: (tester, locale, theme, scale) async {
        final deps = HubScanDeps(capability: true);
        final repository = FakeSmsImportRepository();
        addTearDown(deps.settings.close);
        addTearDown(repository.close);
        await pumpSmsPage(
          tester,
          EnableBankMessagesPage(
            cubit: buildEnableFlowCubit(deps, repository: repository),
          ),
          locale: locale,
          theme: theme,
          textScale: scale,
        );
      },
      check: (tester, l10n) {
        expect(
          find.byKey(const ValueKey('sms_enable_explain')),
          findsOneWidget,
        );
        expect(find.text(l10n.smsImportEnableWhatIsRead), findsOneWidget);
      },
    ),
    (
      name: 'settings',
      pump: (tester, locale, theme, scale) async {
        final deps = HubScanDeps(
          capability: true,
          settings: FakeSmsImportSettingsRepository(
            settings: const SmsImportSettings(isEnabled: true),
          ),
        );
        deps.permissions.status = SmsPermissionStatus.granted;
        addTearDown(deps.settings.close);
        await pumpSmsPage(
          tester,
          BankMessagesSettingsPage(cubit: buildSettingsCubit(deps)),
          locale: locale,
          theme: theme,
          textScale: scale,
        );
      },
      check: (tester, l10n) {
        final chip = find.byKey(const ValueKey('sms_settings_status_chip'));
        expect(chip, findsOneWidget);
        expect(
          find.descendant(
            of: chip,
            matching: find.text(l10n.smsImportSettingsStatusLabel('on')),
          ),
          findsOneWidget,
        );
      },
    ),
    (
      name: 'ignored',
      pump: (tester, locale, theme, scale) async {
        final repository = FakeSmsImportRepository(clock: clock);
        final deps = HubScanDeps(capability: true);
        addTearDown(repository.close);
        addTearDown(deps.settings.close);
        repository.seed([
          buildPendingImport(
            id: 'i',
            fingerprint: 'i',
            status: SmsImportStatus.ignored,
            decidedAt: clock.now().subtract(const Duration(days: 3)),
            hasRawText: false,
          ),
        ]);
        await pumpSmsPage(
          tester,
          IgnoredImportsPage(
            cubit: IgnoredImportsCubit(
              WatchUndoList(repository),
              UndoIgnore(repository),
              GetSmsCapability(deps.gateway),
              clock,
            ),
          ),
          locale: locale,
          theme: theme,
          textScale: scale,
        );
      },
      check: (tester, l10n) {
        expect(find.byKey(const ValueKey('ignored_import_i')), findsOneWidget);
        final undo = find.byKey(const ValueKey('ignored_import_undo_i'));
        expect(undo, findsOneWidget);
        expect(hasLabel(tester, undo, l10n.smsImportIgnoredUndo), isTrue);
      },
    ),
    (
      name: 'muted senders',
      pump: (tester, locale, theme, scale) async {
        final settings = FakeSmsImportSettingsRepository();
        addTearDown(settings.close);
        settings.mutedSenders.add('EXAMPLEBANK');
        await pumpSmsPage(
          tester,
          MutedSendersPage(
            cubit: MutedSendersCubit(
              WatchMutedSenders(settings),
              UnmuteSender(settings),
            ),
          ),
          locale: locale,
          theme: theme,
          textScale: scale,
        );
      },
      check: (tester, l10n) {
        expect(find.text(l10n.smsImportMuteTitle), findsWidgets);
        expect(
          find.bySemanticsLabel(RegExp('EXAMPLEBANK', caseSensitive: false)),
          findsWidgets,
        );
      },
    ),
    (
      name: 'learned categories',
      pump: (tester, locale, theme, scale) async {
        final settings = FakeSmsImportSettingsRepository();
        addTearDown(settings.close);
        final categories = FakeCategoryRepository([
          testCategory(
            'seed_groceries',
            FinanceEntryType.expense,
            name: 'Food',
          ),
        ]);
        final m = MerchantCategoryMapping(
          merchantKey: 'a very long example merchant name',
          entryType: FinanceEntryType.expense,
          categoryId: 'seed_groceries',
          updatedAt: DateTime(2026, 3, 4),
        );
        settings.mappings[(m.merchantKey, m.entryType.dbValue)] = m;
        await pumpSmsPage(
          tester,
          LearnedCategoriesPage(
            cubit: LearnedCategoriesCubit(
              WatchLearnedMappings(settings),
              RemoveLearnedMapping(settings),
              ClearLearnedMappings(settings),
              GetCategories(categories),
            ),
          ),
          locale: locale,
          theme: theme,
          textScale: scale,
        );
      },
      check: (tester, l10n) {
        expect(find.text(l10n.smsImportMappingsTitle), findsWidgets);
        expect(
          find.bySemanticsLabel(RegExp('a very long example merchant name')),
          findsWidgets,
        );
      },
    ),
    (
      name: 'home card (count)',
      pump: (tester, locale, theme, scale) async {
        final repository = FakeSmsImportRepository();
        final deps = HubScanDeps(
          capability: true,
          settings: FakeSmsImportSettingsRepository(
            settings: const SmsImportSettings(isEnabled: true),
          ),
        );
        addTearDown(repository.close);
        addTearDown(deps.settings.close);
        repository.seed([
          for (var i = 0; i < 12; i++)
            buildPendingImport(id: 'p$i', fingerprint: 'fp$i'),
        ]);
        await pumpSmsPage(
          tester,
          Scaffold(
            body: ListView(
              children: [
                BankMessagesHomeCard(
                  capabilityAvailable: () async =>
                      (await deps.capability()).available,
                  createCubit: () =>
                      buildHomeCubit(deps, repository: repository),
                ),
              ],
            ),
          ),
          locale: locale,
          theme: theme,
          textScale: scale,
        );
      },
      check: (tester, l10n) {
        final card = find.byKey(const ValueKey('bank_messages_home_count'));
        expect(card, findsOneWidget);
        expect(
          find.bySemanticsLabel(
            RegExp(RegExp.escape(l10n.smsImportHomeCardCount(12))),
          ),
          findsWidgets,
        );
      },
    ),
    (
      name: 'home card (onboarding)',
      pump: (tester, locale, theme, scale) async {
        final repository = FakeSmsImportRepository();
        final deps = HubScanDeps(capability: true);
        addTearDown(repository.close);
        addTearDown(deps.settings.close);
        await pumpSmsPage(
          tester,
          Scaffold(
            body: ListView(
              children: [
                BankMessagesHomeCard(
                  capabilityAvailable: () async =>
                      (await deps.capability()).available,
                  createCubit: () =>
                      buildHomeCubit(deps, repository: repository),
                ),
              ],
            ),
          ),
          locale: locale,
          theme: theme,
          textScale: scale,
        );
      },
      check: (tester, l10n) {
        expect(
          find.byKey(const ValueKey('bank_messages_home_onboarding')),
          findsOneWidget,
        );
        expect(find.text(l10n.smsImportHomeOnboardingSetUp), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            RegExp(RegExp.escape(l10n.smsImportHomeOnboardingDismiss)),
          ),
          findsWidgets,
        );
      },
    ),
  ];

  for (final screen in screens) {
    group(screen.name, () {
      for (final locale in smsLocales) {
        for (final theme in smsThemes) {
          testWidgets('${locale.name} / ${theme.name} at 200% text: no '
              'overflow, key semantics', (tester) async {
            final handle = tester.ensureSemantics();
            phoneSurface(tester);
            await screen.pump(tester, locale.locale, theme.theme, 2);
            expect(tester.takeException(), isNull);

            final l10n = lookupAppLocalizations(locale.locale);
            final scaffold = find.byType(Scaffold).first;
            expect(
              Directionality.of(tester.element(scaffold)),
              locale.locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            );
            expect(
              Theme.of(tester.element(scaffold)).brightness,
              theme.theme.brightness,
            );
            screen.check(tester, l10n);
            handle.dispose();
          });
        }
      }
    });
  }
}
