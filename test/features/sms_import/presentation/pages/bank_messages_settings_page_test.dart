import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_state.dart';
import 'package:daftary/features/settings/presentation/pages/settings_page.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/presentation/pages/bank_messages_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';
import '../../helpers/scan_presentation.dart';
import '../../helpers/widget_harness.dart';

class _MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

/// T121/T123 — Settings -> Bank messages (ui-contract §3.1) and the main
/// Settings entry. The page never prompts; the SMS rows exist only with
/// the capability (CHK013, CHK036); paste and the preferences are there
/// on every platform.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late HubScanDeps deps;

  tearDown(() => deps.settings.close());

  Future<void> pumpSettings(
    WidgetTester tester, {
    bool capability = true,
    SmsImportSettings settings = const SmsImportSettings(),
    SmsPermissionStatus permission = SmsPermissionStatus.denied,
    Locale locale = const Locale('en'),
    ThemeData? theme,
    double textScale = 1,
  }) async {
    deps = HubScanDeps(
      capability: capability,
      settings: FakeSmsImportSettingsRepository(settings: settings),
    );
    deps.permissions.status = permission;
    await pumpSmsPage(
      tester,
      BankMessagesSettingsPage(cubit: buildSettingsCubit(deps)),
      locale: locale,
      theme: theme,
      textScale: textScale,
    );
  }

  Finder byKey(String key) => find.byKey(ValueKey(key));

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  testWidgets('without the capability: no SMS rows, no permission mention', (
    tester,
  ) async {
    await pumpSettings(tester, capability: false);
    expect(byKey('sms_settings_status_section'), findsNothing);
    expect(byKey('sms_settings_scan_section'), findsNothing);
    expect(byKey('sms_settings_turn_on'), findsNothing);
    expect(find.text(en.smsImportPermissionDeniedBanner), findsNothing);
    expect(find.textContaining('permission'), findsNothing);
    expect(byKey('sms_settings_preferences_section'), findsOneWidget);
    await scrollTo(tester, byKey('sms_settings_paste'));
    expect(byKey('sms_settings_paste'), findsOneWidget);
    expect(deps.permissions.statusChecks, 0);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('without the capability: Pending bank messages leads back to '
      'the hub, first in Manage', (tester) async {
    await pumpSettings(tester, capability: false);
    await scrollTo(tester, byKey('sms_settings_pending'));
    expect(find.text(en.smsImportSettingsPending), findsOneWidget);
    expect(
      tester.getTopLeft(byKey('sms_settings_pending')).dy,
      lessThan(tester.getTopLeft(byKey('sms_settings_paste')).dy),
    );
    await tester.tap(byKey('sms_settings_pending'));
    await tester.pumpAndSettle();
    expect(find.text('hub-route'), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('off: status Off and Turn on, which opens the enable flow', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(find.text(en.smsImportSettingsStatusLabel('off')), findsOneWidget);
    expect(byKey('sms_settings_scan_section'), findsNothing);
    await tester.tap(byKey('sms_settings_turn_on'));
    await tester.pumpAndSettle();
    expect(find.text('enable-route'), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('on and granted: window, Scan now, last scan and counts', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      permission: SmsPermissionStatus.granted,
      settings: const SmsImportSettings(
        isEnabled: true,
        scannedCount: 12,
        recognizedCount: 5,
        addedCount: 3,
        ignoredCount: 1,
      ),
    );
    expect(find.text(en.smsImportSettingsStatusLabel('on')), findsOneWidget);
    expect(byKey('sms_settings_turn_on'), findsNothing);
    expect(byKey('sms_settings_scan_section'), findsOneWidget);
    for (final days in [7, 30, 90]) {
      expect(byKey('sms_scan_window_$days'), findsOneWidget);
    }
    expect(find.text(en.smsImportSettingsNeverScanned), findsOneWidget);
    await scrollTo(tester, find.text(en.smsImportSettingsCountIgnored(1)));
    expect(find.text(en.smsImportSettingsCountScanned(12)), findsOneWidget);
    expect(find.text(en.smsImportSettingsCountRecognized(5)), findsOneWidget);
    expect(find.text(en.smsImportSettingsCountAdded(3)), findsOneWidget);
    expect(find.text(en.smsImportSettingsCountIgnored(1)), findsOneWidget);
  });

  testWidgets('the window radio writes through the preferences', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      permission: SmsPermissionStatus.granted,
      settings: const SmsImportSettings(isEnabled: true),
    );
    await tester.tap(byKey('sms_scan_window_90'));
    await tester.pumpAndSettle();
    expect(deps.settings.settings.scanWindow, ScanWindow.days90);
  });

  testWidgets('Scan now opens the hub with a scan', (tester) async {
    await pumpSettings(
      tester,
      permission: SmsPermissionStatus.granted,
      settings: const SmsImportSettings(isEnabled: true),
    );
    await scrollTo(tester, byKey('sms_settings_scan_now'));
    await tester.tap(byKey('sms_settings_scan_now'));
    await tester.pumpAndSettle();
    expect(find.text('hub-route'), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('the cash-withdrawal switch writes; a failure is shown', (
    tester,
  ) async {
    await pumpSettings(tester);
    await scrollTo(tester, byKey('sms_settings_count_cash'));
    await tester.tap(byKey('sms_settings_count_cash'));
    await tester.pumpAndSettle();
    expect(deps.settings.settings.countCashWithdrawals, isTrue);

    deps.settings.nextFailure = const CacheFailure('x');
    await tester.tap(byKey('sms_settings_count_cash'));
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportSettingsSaveFailed), findsOneWidget);
    expect(deps.settings.settings.countCashWithdrawals, isTrue);
  });

  testWidgets('revoked: Permission off, the banner and paste', (tester) async {
    await pumpSettings(
      tester,
      permission: SmsPermissionStatus.revoked,
      settings: const SmsImportSettings(isEnabled: true),
    );
    expect(
      find.text(en.smsImportSettingsStatusLabel('permissionOff')),
      findsOneWidget,
    );
    expect(find.text(en.smsImportPermissionRevokedBanner), findsOneWidget);
    expect(byKey('sms_settings_scan_section'), findsNothing);
    await tester.tap(find.text(en.smsImportPermissionOpenAppInfo));
    await tester.pumpAndSettle();
    expect(deps.permissions.appInfoOpens, 1);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('restricted: Blocked by Android and Show me how', (tester) async {
    await pumpSettings(
      tester,
      permission: SmsPermissionStatus.restrictedBlocked,
    );
    expect(
      find.text(en.smsImportSettingsStatusLabel('blocked')),
      findsOneWidget,
    );
    await tester.tap(find.text(en.smsImportPermissionShowMeHow));
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportRestrictedStep3), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('a resume re-reads the permission without prompting', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      permission: SmsPermissionStatus.granted,
      settings: const SmsImportSettings(isEnabled: true),
    );
    deps.permissions.status = SmsPermissionStatus.revoked;
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportPermissionRevokedBanner), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  for (final locale in smsLocales) {
    for (final theme in smsThemes) {
      testWidgets('renders in ${locale.name} / ${theme.name}', (tester) async {
        await pumpSettings(
          tester,
          permission: SmsPermissionStatus.granted,
          settings: const SmsImportSettings(isEnabled: true),
          locale: locale.locale,
          theme: theme.theme,
        );
        expect(tester.takeException(), isNull);
        expectTapTargets(tester, find.byType(BankMessagesSettingsPage));
      });
    }
  }

  testWidgets('200% text renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpSettings(
      tester,
      permission: SmsPermissionStatus.revoked,
      settings: const SmsImportSettings(isEnabled: true),
      textScale: 2,
      locale: const Locale('ar'),
    );
    expect(tester.takeException(), isNull);
  });

  group('Settings entry', () {
    setUp(() => deps = HubScanDeps());

    testWidgets('the Bank messages tile is shown (paste works everywhere) '
        'after Notifications, and opens the bank-messages settings', (
      tester,
    ) async {
      final cubit = _MockSettingsCubit();
      when(() => cubit.state).thenReturn(const SettingsState());
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => BlocProvider<SettingsCubit>.value(
              value: cubit,
              child: const SettingsPage(),
            ),
          ),
          GoRoute(
            path: '/settings/bank-messages',
            builder: (_, _) => const Scaffold(body: Text('sms-settings')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      final entry = find.byKey(const Key('settings_bank_messages_entry'));
      await tester.scrollUntilVisible(entry, 200);
      expect(entry, findsOneWidget);
      final notifications = find.byKey(
        const Key('settings_notifications_entry'),
      );
      expect(
        tester.getTopLeft(notifications).dy,
        lessThan(tester.getTopLeft(entry).dy),
      );
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.text('sms-settings'), findsOneWidget);
      expect(deps.permissions.requests, 0);
    });
  });
}
