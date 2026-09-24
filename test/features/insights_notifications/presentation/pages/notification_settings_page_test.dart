import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_preference.dart';
import 'package:daftary/features/insights_notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:daftary/features/insights_notifications/presentation/cubit/notification_settings_state.dart';
import 'package:daftary/features/insights_notifications/presentation/pages/notification_settings_page.dart';
import 'package:daftary/features/insights_notifications/presentation/widgets/permission_denied_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationSettingsCubit extends MockCubit<NotificationSettingsState>
    implements NotificationSettingsCubit {}

/// Widget coverage of the notification settings screen (US3), including
/// the T046 RTL/LTR × light/dark rendering pass (FR-020, SC-007).
void main() {
  late MockNotificationSettingsCubit cubit;
  late int openSettingsCalls;

  const off = NotificationPreference.defaults;
  const enabledDeniedWithQuietHours = NotificationPreference(
    isEnabled: true,
    budgetWarningsEnabled: true,
    savingsCheckInsEnabled: false,
    osPermissionGranted: false,
    quietHoursStart: 22 * 60,
    quietHoursEnd: 8 * 60,
  );
  const enabledGranted = NotificationPreference(
    isEnabled: true,
    budgetWarningsEnabled: true,
    savingsCheckInsEnabled: true,
    osPermissionGranted: true,
  );

  NotificationSettingsState ready(NotificationPreference preference) =>
      NotificationSettingsState(
        status: NotificationSettingsStatus.ready,
        preference: preference,
      );

  setUp(() {
    cubit = MockNotificationSettingsCubit();
    openSettingsCalls = 0;
    when(() => cubit.setEnabled(any())).thenAnswer((_) async {});
    when(() => cubit.setBudgetWarningsEnabled(any())).thenAnswer((_) async {});
    when(() => cubit.setSavingsCheckInsEnabled(any())).thenAnswer((_) async {});
    when(() => cubit.setQuietHoursEnabled(any())).thenAnswer((_) async {});
    when(() => cubit.refreshPermission()).thenAnswer((_) async {});
  });

  Widget wrap({
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      locale: locale,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<NotificationSettingsCubit>.value(
        value: cubit,
        child: NotificationSettingsView(
          onOpenDeviceSettings: () async => openSettingsCalls++,
        ),
      ),
    );
  }

  testWidgets('first open: feature off, no category toggles, no banner', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(ready(off));
    await tester.pumpWidget(wrap());

    expect(find.text('Budget & savings reminders'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('notification_master_switch')),
          )
          .value,
      isFalse,
    );
    expect(find.text('Budget warnings'), findsNothing);
    expect(find.byKey(PermissionDeniedBanner.rootKey), findsNothing);
  });

  testWidgets('enabling without permission explains why before asking', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(ready(off));
    await tester.pumpWidget(wrap());

    await tester.tap(find.byKey(const Key('notification_master_switch')));
    await tester.pumpAndSettle();

    expect(find.text('Allow notifications?'), findsOneWidget);
    verifyNever(() => cubit.setEnabled(any()));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    verify(() => cubit.setEnabled(true)).called(1);
  });

  testWidgets('dismissing the rationale does not enable the feature', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(ready(off));
    await tester.pumpWidget(wrap());

    await tester.tap(find.byKey(const Key('notification_master_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => cubit.setEnabled(any()));
  });

  testWidgets('disabling needs no rationale', (tester) async {
    when(() => cubit.state).thenReturn(ready(enabledGranted));
    await tester.pumpWidget(wrap());

    await tester.tap(find.byKey(const Key('notification_master_switch')));
    await tester.pumpAndSettle();

    verify(() => cubit.setEnabled(false)).called(1);
  });

  testWidgets('denied permission shows the banner with a settings link', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(ready(enabledDeniedWithQuietHours));
    await tester.pumpWidget(wrap());

    expect(find.byKey(PermissionDeniedBanner.rootKey), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('notification_open_device_settings')),
    );
    expect(openSettingsCalls, 1);
  });

  testWidgets('category toggles and quiet hours reach the cubit', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(ready(enabledGranted));
    await tester.pumpWidget(wrap());

    await tester.tap(
      find.byKey(const Key('notification_budget_warnings_toggle')),
    );
    await tester.tap(
      find.byKey(const Key('notification_savings_check_ins_toggle')),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('notification_quiet_hours_switch')),
      100,
    );
    await tester.tap(find.byKey(const Key('notification_quiet_hours_switch')));

    verify(() => cubit.setBudgetWarningsEnabled(false)).called(1);
    verify(() => cubit.setSavingsCheckInsEnabled(false)).called(1);
    verify(() => cubit.setQuietHoursEnabled(true)).called(1);
  });

  testWidgets('shows the configured quiet-hours window, ending next day', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(
      ready(enabledDeniedWithQuietHours.copyWith(osPermissionGranted: true)),
    );
    await tester.pumpWidget(wrap());
    await tester.scrollUntilVisible(
      find.byKey(const Key('notification_quiet_hours_end')),
      100,
    );

    expect(find.text('10:00 PM'), findsOneWidget);
    expect(find.text('8:00 AM'), findsOneWidget);
    expect(find.text('next day'), findsOneWidget);
  });

  testWidgets('a failed save shows a snackbar', (tester) async {
    whenListen(
      cubit,
      Stream.fromIterable([
        ready(enabledGranted).copyWith(isSaveFailing: true),
      ]),
      initialState: ready(enabledGranted),
    );
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(
      find.text("Couldn't save your notification settings. Please try again."),
      findsOneWidget,
    );
  });

  group('T046 RTL/LTR and light/dark rendering', () {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      for (final themeMode in const [ThemeMode.light, ThemeMode.dark]) {
        for (final (name, preference) in [
          ('off', off),
          ('enabled, denied, quiet hours', enabledDeniedWithQuietHours),
        ]) {
          testWidgets(
            '${locale.languageCode} / ${themeMode.name} / $name renders '
            'without overflow on a phone-sized screen',
            (tester) async {
              tester.view.physicalSize = const Size(360, 780);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              when(() => cubit.state).thenReturn(ready(preference));

              await tester.pumpWidget(
                wrap(locale: locale, themeMode: themeMode),
              );
              await tester.pumpAndSettle();

              expect(tester.takeException(), isNull);
              final context = tester.element(
                find.byType(NotificationSettingsView),
              );
              expect(
                Directionality.of(context),
                locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              );
              expect(
                Theme.of(context).brightness,
                themeMode == ThemeMode.dark
                    ? Brightness.dark
                    : Brightness.light,
              );
              if (preference.isEnabled) {
                expect(
                  find.byKey(PermissionDeniedBanner.rootKey),
                  findsOneWidget,
                );
                await tester.scrollUntilVisible(
                  find.byKey(const Key('notification_quiet_hours_end')),
                  100,
                );
                expect(tester.takeException(), isNull);
              }
            },
          );
        }
      }
    }
  });
}
