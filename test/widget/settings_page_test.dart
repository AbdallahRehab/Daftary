import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_state.dart';
import 'package:daftary/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

void main() {
  late MockSettingsCubit cubit;

  setUpAll(() {
    registerFallbackValue(AppLanguage.english);
    registerFallbackValue(AppThemeMode.system);
  });

  setUp(() {
    cubit = MockSettingsCubit();
    when(() => cubit.changeLanguage(any())).thenAnswer((_) async {});
    when(() => cubit.changeThemeMode(any())).thenAnswer((_) async {});
  });

  Widget wrap() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<SettingsCubit>.value(
        value: cubit,
        child: const SettingsPage(),
      ),
    );
  }

  testWidgets(
    'selecting Arabic invokes SettingsCubit.changeLanguage(AppLanguage.arabic)',
    (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const SettingsState(language: AppLanguage.english));
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Arabic'));
      await tester.pumpAndSettle();

      verify(() => cubit.changeLanguage(AppLanguage.arabic)).called(1);
    },
  );

  testWidgets(
    'selecting English invokes SettingsCubit.changeLanguage(AppLanguage.english)',
    (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const SettingsState(language: AppLanguage.arabic));
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      verify(() => cubit.changeLanguage(AppLanguage.english)).called(1);
    },
  );

  testWidgets(
    'selecting Dark invokes SettingsCubit.changeThemeMode(AppThemeMode.dark)',
    (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const SettingsState(themeMode: AppThemeMode.light));
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      verify(() => cubit.changeThemeMode(AppThemeMode.dark)).called(1);
    },
  );

  testWidgets(
    'selecting Light invokes SettingsCubit.changeThemeMode(AppThemeMode.light)',
    (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const SettingsState(themeMode: AppThemeMode.dark));
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      verify(() => cubit.changeThemeMode(AppThemeMode.light)).called(1);
    },
  );

  testWidgets('selecting System Default invokes '
      'SettingsCubit.changeThemeMode(AppThemeMode.system)', (tester) async {
    when(
      () => cubit.state,
    ).thenReturn(const SettingsState(themeMode: AppThemeMode.dark));
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('System Default'));
    await tester.pumpAndSettle();

    verify(() => cubit.changeThemeMode(AppThemeMode.system)).called(1);
  });

  group('Your data / Danger zone (013)', () {
    /// `/settings` with placeholder `export` / `delete-data` children, the
    /// same shape as the real Settings branch.
    Widget wrapWithRouter() {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (_, _) => BlocProvider<SettingsCubit>.value(
              value: cubit,
              child: const SettingsPage(),
            ),
            routes: [
              GoRoute(
                path: 'export',
                builder: (_, _) =>
                    const Scaffold(body: Text('EXPORT_PLACEHOLDER')),
              ),
              GoRoute(
                path: 'security',
                builder: (_, _) =>
                    const Scaffold(body: Text('SECURITY_PLACEHOLDER')),
              ),
              GoRoute(
                path: 'delete-data',
                builder: (_, _) =>
                    const Scaffold(body: Text('DELETE_PLACEHOLDER')),
              ),
            ],
          ),
        ],
      );
      return MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    }

    setUp(() => when(() => cubit.state).thenReturn(const SettingsState()));

    testWidgets('shows both sections below the existing ones', (tester) async {
      await tester.pumpWidget(wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Delete my data'), 100);
      expect(find.text('Your data'), findsOneWidget);
      expect(find.text('Export my data'), findsOneWidget);
      expect(find.text('Danger zone'), findsOneWidget);
      expect(
        find.text('Permanently erase everything stored in Daftary'),
        findsOneWidget,
      );
      // Additive: the existing sections are still there, above.
      expect(
        tester.getTopLeft(find.text('Dark')).dy,
        lessThan(tester.getTopLeft(find.text('Your data')).dy),
      );
    });

    testWidgets('"Export my data" opens /settings/export', (tester) async {
      await tester.pumpWidget(wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Export my data'), 100);
      await tester.ensureVisible(find.text('Export my data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export my data'));
      await tester.pumpAndSettle();

      expect(find.text('EXPORT_PLACEHOLDER'), findsOneWidget);
    });

    testWidgets('"Delete my data" opens /settings/delete-data', (tester) async {
      await tester.pumpWidget(wrapWithRouter());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Delete my data'), 100);
      await tester.ensureVisible(find.text('Delete my data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete my data'));
      await tester.pumpAndSettle();

      expect(find.text('DELETE_PLACEHOLDER'), findsOneWidget);
    });
  });

  group('Security (015)', () {
    Widget wrapWithRouter() {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (_, _) => BlocProvider<SettingsCubit>.value(
              value: cubit,
              child: const SettingsPage(),
            ),
            routes: [
              GoRoute(
                path: 'security',
                builder: (_, _) =>
                    const Scaffold(body: Text('SECURITY_PLACEHOLDER')),
              ),
            ],
          ),
        ],
      );
      return MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    }

    setUp(() => when(() => cubit.state).thenReturn(const SettingsState()));

    testWidgets('the Security entry opens /settings/security', (tester) async {
      await tester.pumpWidget(wrapWithRouter());
      await tester.pumpAndSettle();

      final entry = find.text('App lock');
      await tester.scrollUntilVisible(entry, 100);
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      expect(find.text('Security'), findsOneWidget);
      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(find.text('SECURITY_PLACEHOLDER'), findsOneWidget);
    });
  });
}
