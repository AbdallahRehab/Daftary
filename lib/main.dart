import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/design_system/tokens.dart';
import 'core/di/injection.dart';
import 'core/l10n/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/security/app_lifecycle_observer.dart';
import 'core/security/app_lock_gate.dart';
import 'core/security/screenshot_protection_service.dart';
import 'features/app_lock/presentation/pages/lock_screen_page.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'features/settings/domain/entities/app_theme_mode.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/settings/presentation/cubit/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  // Resolved before the first frame so it already reflects the persisted/
  // first-launch-default language, rather than SettingsCubit's hardcoded
  // AppLanguage.english initial state (T025).
  await getIt<SettingsCubit>().initialize();
  // Resolved before the first frame so appRouter's redirect (FR-001/
  // FR-010a) already has a settled OnboardingCubit state on the very
  // first navigation — no async redirect/refreshListenable needed.
  await getIt<OnboardingCubit>().initialize();
  // 015 FR-020/FR-021: screenshot/recording protection is always on,
  // independent of whether App Lock is ever enabled.
  await getIt<ScreenshotProtectionService>().enable();
  // 015: registered unconditionally; locks the very first frame on a cold
  // launch when App Lock is enabled, and on resume past the timeout.
  await getIt<AppLifecycleObserver>().initialize();
  runApp(const DaftaryApp());
}

class DaftaryApp extends StatelessWidget {
  const DaftaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: getIt<SettingsCubit>()),
        BlocProvider<OnboardingCubit>.value(value: getIt<OnboardingCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: switch (state.themeMode) {
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
              AppThemeMode.system => ThemeMode.system,
            },
            routerConfig: appRouter,
            // 015 research.md Decision 5: the single app-wide lock gate,
            // above the router's Navigator so no route can bypass it.
            builder: (context, child) => AppLockGate(
              observer: getIt<AppLifecycleObserver>(),
              lockScreenBuilder: (_) => const LockScreenPage(),
              child: child ?? const SizedBox.shrink(),
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(state.language.code),
          );
        },
      ),
    );
  }
}
