import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/undo_ignore.dart';
import 'package:daftary/features/sms_import/domain/usecases/unmute_sender.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_muted_senders.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_undo_list.dart';
import 'package:daftary/features/sms_import/presentation/cubit/ignored_imports_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/muted_senders_cubit.dart';
import 'package:daftary/features/sms_import/presentation/pages/bank_messages_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/bank_messages_settings_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/ignored_imports_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/import_review_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/muted_senders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/review_harness.dart';
import '../../helpers/scan_presentation.dart';
import '../../helpers/widget_harness.dart';

/// T135 — the screens of T132-T134: multi-select with batch Ignore on the
/// hub (no "Add all"), Ignore and "Stop suggesting from this sender" on
/// the review, the Ignored list with Undo and its §3.8 copy, the Muted
/// senders list with Unmute, and the Settings links. Each in RTL x LTR x
/// light x dark with semantics and 48 dp checks. Synthetic data only.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ar = lookupAppLocalizations(const Locale('ar'));
  late FixedClock clock;
  late FakeSmsImportRepository repository;

  setUp(() {
    clock = FixedClock(DateTime(2026, 3, 10, 12));
    repository = FakeSmsImportRepository(clock: clock);
  });
  tearDown(() => repository.close());

  List<PendingSmsImport> three() => [
    buildPendingImport(id: 'a', fingerprint: 'a'),
    buildPendingImport(id: 'b', fingerprint: 'b', merchant: 'Shop B'),
    buildPendingImport(id: 'c', fingerprint: 'c', merchant: 'Shop C'),
  ];

  // ------------------------------------------------------------------ hub

  group('hub multi-select (T132)', () {
    Future<void> pumpHub(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      ThemeData? theme,
    }) async {
      repository.seed(three());
      await pumpSmsPage(
        tester,
        BankMessagesPage(cubit: buildBankMessagesCubit(repository, clock)),
        locale: locale,
        theme: theme,
      );
    }

    Finder card(String id) => find.byKey(ValueKey('pending_import_card_$id'));

    testWidgets('long-press selects; the toolbar offers Ignore only', (
      tester,
    ) async {
      await pumpHub(tester);
      await tester.longPress(card('a'));
      await tester.pumpAndSettle();

      expect(find.text(en.smsImportPendingSelectedCount(1)), findsOneWidget);
      expect(
        find.byKey(const ValueKey('bank_messages_ignore_selected')),
        findsOneWidget,
      );
      expect(find.byType(Checkbox), findsNWidgets(3));
      // No batch Add anywhere (FR-046).
      expect(find.textContaining('Add'), findsNothing);
      expect(find.textContaining('add all'), findsNothing);
    });

    testWidgets('"Select" enters selection; tap toggles instead of opening', (
      tester,
    ) async {
      await pumpHub(tester);
      await tester.tap(find.byKey(const ValueKey('bank_messages_select')));
      await tester.pumpAndSettle();
      await tester.tap(card('b'));
      await tester.pumpAndSettle();
      expect(find.text('review-b'), findsNothing);
      expect(find.text(en.smsImportPendingSelectedCount(1)), findsOneWidget);
      await tester.tap(card('b'));
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportPendingSelectedCount(0)), findsOneWidget);
      // Ignore is disabled with nothing selected.
      final ignore = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('bank_messages_ignore_selected')),
      );
      expect(ignore.onPressed, isNull);
    });

    testWidgets('selected rows expose selected and checked semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpHub(tester);
      await tester.longPress(card('a'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(card('a')),
        isSemantics(isSelected: true, isChecked: true),
      );
      expect(
        tester.getSemantics(card('b')),
        isSemantics(isSelected: false, isChecked: false),
      );
      handle.dispose();
    });

    testWidgets('batch Ignore asks first; Cancel ignores nothing', (
      tester,
    ) async {
      await pumpHub(tester);
      await tester.longPress(card('a'));
      await tester.pumpAndSettle();
      await tester.tap(card('c'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('bank_messages_ignore_selected')),
      );
      await tester.pumpAndSettle();

      expect(find.text(en.smsImportPendingIgnoreConfirmTitle(2)), findsOne);
      expect(find.text(en.smsImportPendingIgnoreConfirmMessage), findsOne);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.rows.values.every((r) => r.isPending), isTrue);
      expect(find.text(en.smsImportPendingSelectedCount(2)), findsOneWidget);
    });

    testWidgets('confirmed batch Ignore ignores the selection and says so', (
      tester,
    ) async {
      await pumpHub(tester);
      await tester.longPress(card('a'));
      await tester.pumpAndSettle();
      await tester.tap(card('c'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('bank_messages_ignore_selected')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.smsImportPendingIgnoreConfirm).last);
      await tester.pumpAndSettle();

      expect(repository.rows['a']!.status, SmsImportStatus.ignored);
      expect(repository.rows['c']!.status, SmsImportStatus.ignored);
      expect(repository.rows['b']!.isPending, isTrue);
      expect(repository.confirmCalls, isEmpty);
      expect(find.text(en.smsImportPendingIgnoredCount(2)), findsOneWidget);
      expect(card('a'), findsNothing);
      expect(card('b'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('Back and the close button leave selection mode', (
      tester,
    ) async {
      await pumpHub(tester);
      await tester.longPress(card('a'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('bank_messages_cancel_selection')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text(en.smsImportPendingTitle), findsOneWidget);
    });

    testWidgets('the overflow links to Ignored items', (tester) async {
      await pumpHub(tester);
      await tester.tap(find.byKey(const ValueKey('bank_messages_overflow')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.smsImportPendingMenuIgnored));
      await tester.pumpAndSettle();
      expect(find.text('ignored-route'), findsOneWidget);
    });

    for (final locale in smsLocales) {
      for (final theme in smsThemes) {
        testWidgets('selection renders in ${locale.name} / ${theme.name}', (
          tester,
        ) async {
          await pumpHub(tester, locale: locale.locale, theme: theme.theme);
          await tester.longPress(card('a'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final l10n = locale.locale.languageCode == 'ar' ? ar : en;
          expect(
            find.text(l10n.smsImportPendingSelectedCount(1)),
            findsOneWidget,
          );
          expectTapTargets(tester, find.byType(BankMessagesPage));
          for (final box in find.byType(Checkbox).evaluate()) {
            final size = tester.getSize(find.byWidget(box.widget));
            expect(size.width, greaterThanOrEqualTo(48));
          }
        });
      }
    }
  });

  // --------------------------------------------------------------- review

  group('review Ignore and mute (T132)', () {
    late ReviewHarness h;

    setUp(() => h = ReviewHarness());
    tearDown(() => h.dispose());

    Future<void> pumpReview(
      WidgetTester tester,
      List<PendingSmsImport> items, {
      Locale locale = const Locale('en'),
      ThemeData? theme,
    }) async {
      tester.view.physicalSize = const Size(420 * 3, 3000 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      h.repository.seed(items);
      await pumpSmsPage(
        tester,
        ImportReviewPage(importId: items.first.id, cubit: h.build()),
        locale: locale,
        theme: theme,
      );
    }

    testWidgets('Ignore closes the item without adding and moves on', (
      tester,
    ) async {
      await pumpReview(tester, [
        buildPendingImport(id: 'a', fingerprint: 'a'),
        buildPendingImport(id: 'b', fingerprint: 'b'),
      ]);
      await tester.tap(find.byKey(const ValueKey('import_review_ignore')));
      await tester.pumpAndSettle();
      expect(h.repository.rows['a']!.status, SmsImportStatus.ignored);
      expect(h.repository.confirmCalls, isEmpty);
      expect(find.text('review-b'), findsOneWidget);
    });

    testWidgets('mute is offered only with a sender', (tester) async {
      await pumpReview(tester, [
        buildPendingImport(senderId: null, source: SmsSource.paste),
      ]);
      expect(
        find.byKey(const ValueKey('import_review_overflow')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('import_review_ignore')), findsOne);
    });

    testWidgets('mute confirms first, naming the removal; cancel keeps all', (
      tester,
    ) async {
      await pumpReview(tester, [
        buildPendingImport(id: 'a', fingerprint: 'a', senderId: 'BANKX'),
        buildPendingImport(id: 'b', fingerprint: 'b', senderId: 'BANKX'),
      ]);
      await tester.tap(find.byKey(const ValueKey('import_review_overflow')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.smsImportMuteAction));
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportMuteConfirmTitle), findsOneWidget);
      expect(
        find.textContaining('pending items will be removed'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(h.repository.rows, hasLength(2));
      expect(h.settings.mutedSenders, isEmpty);
    });

    testWidgets('confirmed mute removes the sender\'s items and leaves', (
      tester,
    ) async {
      await pumpReview(tester, [
        buildPendingImport(id: 'a', fingerprint: 'a', senderId: 'BANKX'),
        buildPendingImport(id: 'b', fingerprint: 'b', senderId: 'BANKX'),
      ]);
      await tester.tap(find.byKey(const ValueKey('import_review_overflow')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.smsImportMuteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.smsImportMuteConfirm));
      await tester.pumpAndSettle();
      expect(h.settings.mutedSenders, {'BANKX'});
      expect(h.repository.rows, isEmpty);
      expect(h.repository.tombstones, isEmpty);
      expect(h.repository.confirmCalls, isEmpty);
      // No next item: back to the hub.
      expect(find.text('hub-route'), findsOneWidget);
    });

    for (final locale in smsLocales) {
      for (final theme in smsThemes) {
        testWidgets('actions render in ${locale.name} / ${theme.name}', (
          tester,
        ) async {
          await pumpReview(
            tester,
            [buildPendingImport()],
            locale: locale.locale,
            theme: theme.theme,
          );
          expect(tester.takeException(), isNull);
          final ignore = find.byKey(const ValueKey('import_review_ignore'));
          expect(tester.getSize(ignore).height, greaterThanOrEqualTo(48));
          expect(
            find.byKey(const ValueKey('import_review_overflow')),
            findsOneWidget,
          );
        });
      }
    }
  });

  // -------------------------------------------------------------- ignored

  group('IgnoredImportsPage (T133)', () {
    late HubScanDeps deps;

    tearDown(() => deps.settings.close());

    Future<void> pumpIgnored(
      WidgetTester tester, {
      bool capability = true,
      Locale locale = const Locale('en'),
      ThemeData? theme,
      double textScale = 1,
      UndoIgnore? undo,
    }) async {
      deps = HubScanDeps(capability: capability);
      await pumpSmsPage(
        tester,
        IgnoredImportsPage(
          cubit: IgnoredImportsCubit(
            WatchUndoList(repository),
            undo ?? UndoIgnore(repository),
            GetSmsCapability(deps.gateway),
            clock,
          ),
        ),
        locale: locale,
        theme: theme,
        textScale: textScale,
      );
    }

    void seedIgnored() => repository.seed([
      buildPendingImport(
        id: 'i',
        fingerprint: 'i',
        status: SmsImportStatus.ignored,
        decidedAt: clock.now().subtract(const Duration(days: 3)),
        hasRawText: false,
      ),
      buildPendingImport(
        id: 'e',
        fingerprint: 'e',
        status: SmsImportStatus.expired,
        merchant: null,
        amount: null,
        decidedAt: clock.now().subtract(const Duration(days: 1)),
        hasRawText: false,
      ),
    ]);

    testWidgets('empty state', (tester) async {
      await pumpIgnored(tester);
      expect(find.text(en.smsImportIgnoredEmptyTitle), findsOneWidget);
    });

    testWidgets('rows show status, days left and the six fields only', (
      tester,
    ) async {
      seedIgnored();
      await pumpIgnored(tester);
      expect(find.text(en.smsImportIgnoredStatusIgnored), findsOneWidget);
      expect(find.text(en.smsImportIgnoredStatusExpired), findsOneWidget);
      expect(find.text(en.smsImportIgnoredDaysLeft(27)), findsOneWidget);
      expect(find.text(en.smsImportIgnoredDaysLeft(29)), findsOneWidget);
      expect(find.text(en.smsImportIgnoredNoAmount), findsOneWidget);
      expect(find.textContaining('Example Cafe'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ignored_imports_comes_back')),
        findsOne,
      );
      expect(find.text(en.smsImportIgnoredComesBack), findsOneWidget);
    });

    testWidgets('without the capability the copy leaves Scan out', (
      tester,
    ) async {
      seedIgnored();
      await pumpIgnored(tester, capability: false);
      expect(find.text(en.smsImportIgnoredComesBackPasteOnly), findsOne);
      expect(find.textContaining('Scan'), findsNothing);
    });

    testWidgets('Undo restores, removes the row and says how it returns', (
      tester,
    ) async {
      seedIgnored();
      await pumpIgnored(tester);
      await tester.tap(find.byKey(const ValueKey('ignored_import_undo_i')));
      await tester.pumpAndSettle();
      expect(repository.rows.containsKey('i'), isFalse);
      expect(find.text(en.smsImportIgnoredRestored), findsOneWidget);
      expect(find.byKey(const ValueKey('ignored_import_i')), findsNothing);
    });

    testWidgets('an Undo failure is shown; the row stays', (tester) async {
      seedIgnored();
      repository.rows['x'] = buildPendingImport(
        id: 'x',
        fingerprint: 'x',
        status: SmsImportStatus.ignored,
        decidedAt: clock.now(),
      );
      await pumpIgnored(tester, undo: _FailingUndo());
      await tester.tap(find.byKey(const ValueKey('ignored_import_undo_i')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ignored_import_i')), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('a row reads as one node with its status', (tester) async {
      final handle = tester.ensureSemantics();
      seedIgnored();
      await pumpIgnored(tester);
      expect(
        find.bySemanticsLabel(RegExp('^Ignored.*Example Cafe.*days left')),
        findsOneWidget,
      );
      handle.dispose();
    });

    for (final locale in smsLocales) {
      for (final theme in smsThemes) {
        testWidgets('renders in ${locale.name} / ${theme.name}', (
          tester,
        ) async {
          seedIgnored();
          await pumpIgnored(tester, locale: locale.locale, theme: theme.theme);
          expect(tester.takeException(), isNull);
          final l10n = locale.locale.languageCode == 'ar' ? ar : en;
          expect(find.text(l10n.smsImportIgnoredTitle), findsOneWidget);
          expectTapTargets(tester, find.byType(IgnoredImportsPage));
        });
      }
    }

    testWidgets('200% Arabic text does not overflow', (tester) async {
      seedIgnored();
      await pumpIgnored(tester, locale: const Locale('ar'), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------- muted

  group('MutedSendersPage (T134)', () {
    late FakeSmsImportSettingsRepository settings;

    setUp(() => settings = FakeSmsImportSettingsRepository());
    tearDown(() => settings.close());

    Future<void> pumpMuted(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      ThemeData? theme,
      double textScale = 1,
    }) => pumpSmsPage(
      tester,
      MutedSendersPage(
        cubit: MutedSendersCubit(
          WatchMutedSenders(settings),
          UnmuteSender(settings),
        ),
      ),
      locale: locale,
      theme: theme,
      textScale: textScale,
    );

    testWidgets('empty state', (tester) async {
      await pumpMuted(tester);
      expect(find.text(en.smsImportMuteEmptyTitle), findsOneWidget);
    });

    testWidgets('lists senders; Unmute removes one and says so', (
      tester,
    ) async {
      settings.mutedSenders.addAll({'CIB', 'QNB'});
      await pumpMuted(tester);
      expect(find.byKey(const ValueKey('muted_sender_CIB')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('muted_sender_unmute_CIB')));
      await tester.pumpAndSettle();
      expect(settings.mutedSenders, {'QNB'});
      expect(find.byKey(const ValueKey('muted_sender_CIB')), findsNothing);
      expect(find.text(en.smsImportMuteUnmuted), findsOneWidget);
    });

    testWidgets('Unmute has a label naming the sender', (tester) async {
      final handle = tester.ensureSemantics();
      settings.mutedSenders.add('CIB');
      await pumpMuted(tester);
      expect(find.bySemanticsLabel(RegExp('Unmute.*CIB')), findsOneWidget);
      handle.dispose();
    });

    for (final locale in smsLocales) {
      for (final theme in smsThemes) {
        testWidgets('renders in ${locale.name} / ${theme.name}', (
          tester,
        ) async {
          settings.mutedSenders.add('CIB');
          await pumpMuted(tester, locale: locale.locale, theme: theme.theme);
          expect(tester.takeException(), isNull);
          expectTapTargets(tester, find.byType(MutedSendersPage));
        });
      }
    }

    testWidgets('200% Arabic text does not overflow', (tester) async {
      settings.mutedSenders.add('BANQUEMISR');
      await pumpMuted(tester, locale: const Locale('ar'), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  // ------------------------------------------------------------- settings

  group('Settings Manage links', () {
    for (final capability in [true, false]) {
      testWidgets('Ignored and Muted senders open their screens '
          '(capability: $capability)', (tester) async {
        tester.view.physicalSize = const Size(420 * 3, 3000 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final deps = HubScanDeps(capability: capability);
        addTearDown(deps.settings.close);
        final router = await pumpSmsPage(
          tester,
          BankMessagesSettingsPage(cubit: buildSettingsCubit(deps)),
        );
        expect(find.byKey(const ValueKey('sms_settings_ignored')), findsOne);
        expect(find.byKey(const ValueKey('sms_settings_muted')), findsOne);
        await tester.tap(find.byKey(const ValueKey('sms_settings_ignored')));
        await tester.pumpAndSettle();
        expect(find.text('ignored-route'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('sms_settings_muted')));
        await tester.pumpAndSettle();
        expect(find.text('senders-route'), findsOneWidget);
      });
    }
  });
}

class _FailingUndo extends Mock implements UndoIgnore {
  @override
  Future<Either<Failure, UndoResult>> call(String id) async =>
      const Left(CacheFailure('x'));
}
