import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/design_system/glass/app_glass_scope.dart';
import 'core/design_system/tokens.dart';
import 'core/di/injection.dart';
import 'core/l10n/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/routing/notification_tap_router.dart';
import 'core/security/app_lifecycle_observer.dart';
import 'core/security/app_lock_gate.dart';
import 'core/security/screenshot_protection_service.dart';
import 'core/sync/sync_scheduler.dart';
import 'features/app_lock/presentation/pages/lock_screen_page.dart';
import 'features/insights_notifications/presentation/notification_recompute_trigger.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'features/settings/domain/entities/app_theme_mode.dart';
import 'features/settings/domain/entities/glass_appearance.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/settings/presentation/cubit/settings_state.dart';
import 'features/settings/presentation/glass/glass_style_mapper.dart';
import 'features/startup/presentation/cubit/app_startup_cubit.dart';
import 'features/startup/presentation/cubit/app_startup_state.dart';
import 'features/startup/presentation/widgets/app_startup_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Registration only — no I/O (research.md Decision 1).
  await configureDependencies();
  // 015 FR-020/FR-021 (T065): screenshot/recording protection is always on,
  // independent of whether App Lock is ever enabled, and on before App
  // Lock's state is read at all — that read is a startup step below. One
  // non-throwing platform call, so awaiting it costs the splash nothing.
  await getIt<ScreenshotProtectionService>().enable();
  // Startup I/O (saved language/theme, onboarding gate) runs behind the
  // splash instead of before the first frame (019, FR-011). AppStartupGate
  // mounts the router only once it is ready, so appRouter's redirect still
  // sees a settled OnboardingCubit state on its very first navigation.
  final startup = getIt<AppStartupCubit>();
  unawaited(startup.start());
  // These already ran after both initializers; they still do. `whenReady`
  // resolves once (even after a failed-then-retried startup) and both
  // start() methods are idempotent, so each service starts exactly once.
  // `whenReady` also completes if the cubit closes first, hence the check.
  unawaited(
    startup.whenReady.then((_) {
      if (!startup.state.isReady) return;
      getIt<NotificationRecomputeTrigger>().start();
      unawaited(getIt<NotificationTapRouter>().start(appRouter));
      // 021: cloud sync starts only once startup is ready. It initializes
      // Supabase lazily, and never when unconfigured or switched off.
      unawaited(getIt<SyncScheduler>().start());
    }),
  );
  // 020: preload the glass shaders (async disk I/O, no GPU work) behind the
  // splash, so switching glass ON later never stalls (research.md
  // Decision 2). `wrap` without a theme only registers the accessibility
  // bridge and the Material brightness resolver — it adds no widgets.
  unawaited(LiquidGlassWidgets.initialize());
  runApp(
    LiquidGlassWidgets.wrap(
      child: const DaftaryApp(),
      brightnessResolver: Theme.maybeBrightnessOf,
    ),
  );
}

/// Until the saved language is known, follow the device the same way
/// `SettingsCubit`'s first-launch default does — Arabic when the device is
/// Arabic, otherwise English — so even a startup error reads in the user's
/// language (research.md Decision 10). Once resolved, [locale] is the saved
/// language and is returned unchanged.
Locale _resolveLocale(Locale? locale, Iterable<Locale> supportedLocales) =>
    locale?.languageCode == 'ar' ? const Locale('ar') : const Locale('en');

class DaftaryApp extends StatelessWidget {
  const DaftaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: getIt<SettingsCubit>()),
        BlocProvider<OnboardingCubit>.value(value: getIt<OnboardingCubit>()),
        BlocProvider<AppStartupCubit>.value(value: getIt<AppStartupCubit>()),
      ],
      child: BlocBuilder<AppStartupCubit, AppStartupState>(
        buildWhen: (previous, current) =>
            previous.appearanceResolved != current.appearanceResolved,
        builder: (context, startup) =>
            BlocBuilder<SettingsCubit, SettingsState>(
              // Only what MaterialApp itself reads: a glass change must not
              // rebuild the router, theme or localization (FR-022).
              buildWhen: (previous, current) =>
                  previous.language != current.language ||
                  previous.themeMode != current.themeMode,
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
                  scaffoldMessengerKey: appScaffoldMessengerKey,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: startup.appearanceResolved
                      ? Locale(state.language.code)
                      : null,
                  localeResolutionCallback: _resolveLocale,
                  // Only the glass components (and the Settings preview)
                  // depend on AppGlassScope, so a glass change rebuilds
                  // just them (research.md Decision 9).
                  builder: (context, child) =>
                      BlocSelector<
                        SettingsCubit,
                        SettingsState,
                        GlassAppearance
                      >(
                        selector: (state) => state.glassAppearance,
                        builder: (context, appearance) => AppGlassScope(
                          style: toAppGlassStyle(appearance),
                          child: AppStartupGate(
                            // 015 research.md Decision 5: the single
                            // app-wide lock gate, above the router's
                            // Navigator so no route can bypass it.
                            child: AppLockGate(
                              observer: getIt<AppLifecycleObserver>(),
                              lockScreenBuilder: (_) => const LockScreenPage(),
                              child: child!,
                            ),
                          ),
                        ),
                      ),
                );
              },
            ),
      ),
    );
  }
}
