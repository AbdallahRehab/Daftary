import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_settings_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_settings_state.dart';
import 'package:daftary/features/sms_import/presentation/pages/bank_messages_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/scan_presentation.dart';
import '../../helpers/widget_harness.dart';

/// T142 (and the T139 Manage link) — "Turn off" on Settings -> Bank
/// messages (FR-078, US8-1, ui-contract §3.1): the feature switches off,
/// and pending items are deleted only on the explicit destructive choice.
/// Muted senders and learned categories are always kept.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late HubScanDeps deps;

  void build({bool enabled = true, bool capability = true}) {
    deps = HubScanDeps(
      capability: capability,
      settings: FakeSmsImportSettingsRepository(
        settings: SmsImportSettings(isEnabled: enabled),
      ),
    );
    deps.permissions.status = SmsPermissionStatus.granted;
    deps.pending.seed([
      buildPendingImport(),
      buildPendingImport(id: 'pending-2', fingerprint: 'fp-2'),
    ]);
    deps.settings.mutedSenders.add('BANKX');
  }

  tearDown(() async {
    await deps.settings.close();
    await deps.pending.close();
  });

  group('BankMessagesSettingsCubit.turnOff', () {
    late BankMessagesSettingsCubit cubit;
    tearDown(() => cubit.close());

    test('keep: off, pending items kept', () async {
      build();
      cubit = buildSettingsCubit(deps);
      await cubit.open();
      await cubit.turnOff(deletePending: false);
      expect(deps.settings.settings.isEnabled, isFalse);
      expect(deps.pending.rows, hasLength(2));
      expect(cubit.state.turnedOff, isTrue);
      expect(cubit.state.deletedPendingCount, isNull);
      expect(cubit.state.submitting, isNull);
      cubit.turnedOffShown();
      expect(cubit.state.turnedOff, isFalse);
    });

    test('delete: off, pending items deleted; mutes kept', () async {
      build();
      cubit = buildSettingsCubit(deps);
      await cubit.open();
      await cubit.turnOff(deletePending: true);
      await pumpEventQueue();
      expect(deps.settings.settings.isEnabled, isFalse);
      expect(deps.pending.rows, isEmpty);
      expect(deps.settings.mutedSenders, {'BANKX'});
      expect(cubit.state.deletedPendingCount, 2);
      expect(cubit.state.statusLabel, SmsImportStatusLabel.off);
    });

    test('a failure keeps it on, deletes nothing and is shown once', () async {
      build();
      cubit = buildSettingsCubit(deps);
      await cubit.open();
      deps.settings.nextFailure = const CacheFailure('sms_settings_write');
      await cubit.turnOff(deletePending: true);
      expect(deps.settings.settings.isEnabled, isTrue);
      expect(deps.pending.rows, hasLength(2));
      expect(cubit.state.saveFailed, isTrue);
      expect(cubit.state.turnedOff, isFalse);
    });

    test('ignored while already off', () async {
      build(enabled: false);
      cubit = buildSettingsCubit(deps);
      await cubit.open();
      await cubit.turnOff(deletePending: true);
      expect(deps.pending.rows, hasLength(2));
      expect(cubit.state.turnedOff, isFalse);
    });

    test('a double tap turns off once', () async {
      build();
      cubit = buildSettingsCubit(deps);
      await cubit.open();
      final first = cubit.turnOff(deletePending: false);
      expect(cubit.state.submitting, BankMessagesSettingsControl.turnOff);
      await cubit.turnOff(deletePending: true);
      await first;
      expect(deps.pending.rows, hasLength(2));
      expect(cubit.state.deletedPendingCount, isNull);
    });
  });

  group('BankMessagesSettingsPage', () {
    Future<void> pump(
      WidgetTester tester, {
      bool enabled = true,
      bool capability = true,
      Locale locale = const Locale('en'),
      ThemeData? theme,
      double textScale = 1,
    }) async {
      build(enabled: enabled, capability: capability);
      await pumpSmsPage(
        tester,
        BankMessagesSettingsPage(cubit: buildSettingsCubit(deps)),
        locale: locale,
        theme: theme,
        textScale: textScale,
      );
    }

    Finder turnOff() => find.byKey(const ValueKey('sms_settings_turn_off'));

    testWidgets('on: Turn off asks; "Keep them" turns off and keeps the '
        'items', (tester) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('sms_settings_turn_on')), findsNothing);
      await tester.tap(turnOff());
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportSettingsTurnOffTitle), findsOneWidget);
      expect(find.text(en.smsImportSettingsTurnOffMessage), findsOneWidget);
      await tester.tap(find.text(en.smsImportSettingsTurnOffKeep));
      await tester.pumpAndSettle();
      expect(deps.settings.settings.isEnabled, isFalse);
      expect(deps.pending.rows, hasLength(2));
      expect(find.text(en.smsImportSettingsTurnedOffKept), findsOneWidget);
      // Off now: Turn on is offered again, Turn off is gone.
      expect(find.byKey(const ValueKey('sms_settings_turn_on')), findsOne);
      expect(turnOff(), findsNothing);
      expect(deps.permissions.requests, 0);
    });

    testWidgets('"Delete them" deletes the pending items', (tester) async {
      await pump(tester);
      await tester.tap(turnOff());
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.smsImportSettingsTurnOffDelete));
      await tester.pumpAndSettle();
      expect(deps.settings.settings.isEnabled, isFalse);
      expect(deps.pending.rows, isEmpty);
      expect(find.text(en.smsImportSettingsTurnedOffDeleted(2)), findsOne);
    });

    testWidgets('dismissing the question keeps the items', (tester) async {
      await pump(tester);
      await tester.tap(turnOff());
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4)); // the barrier
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportSettingsTurnOffTitle), findsNothing);
      expect(deps.pending.rows, hasLength(2));
    });

    testWidgets('no Turn off without the capability', (tester) async {
      await pump(tester, capability: false);
      expect(turnOff(), findsNothing);
    });

    testWidgets('Manage links to Learned categories (with and without the '
        'capability)', (tester) async {
      await pump(tester, capability: false);
      final link = find.byKey(const ValueKey('sms_settings_learned'));
      await tester.scrollUntilVisible(
        link,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(en.smsImportMappingsTitle), findsOneWidget);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.text('learned-route'), findsOneWidget);
    });

    for (final locale in smsLocales) {
      for (final theme in smsThemes) {
        testWidgets('${locale.name} / ${theme.name}: Turn off and its '
            'question render', (tester) async {
          await pump(tester, locale: locale.locale, theme: theme.theme);
          expect(turnOff(), findsOneWidget);
          expect(tester.getSize(turnOff()).height, greaterThanOrEqualTo(48));
          await tester.tap(turnOff());
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('200% Arabic: the question renders without overflow', (
      tester,
    ) async {
      await pump(tester, locale: const Locale('ar'), textScale: 2);
      await tester.tap(turnOff());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
