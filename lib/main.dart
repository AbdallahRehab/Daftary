import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/design_system/tokens.dart';
import 'core/di/injection.dart';
import 'core/l10n/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/routing/notification_tap_router.dart';
import 'features/insights_notifications/presentation/notification_recompute_trigger.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'features/settings/domain/entities/app_theme_mode.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/settings/presentation/cubit/settings_state.dart';
import 'features/startup/presentation/cubit/app_startup_cubit.dart';
import 'features/startup/presentation/cubit/app_startup_state.dart';
import 'features/startup/presentation/widgets/app_startup_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Registration only — no I/O (research.md Decision 1).
  await configureDependencies();
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
    }),
  );
  runApp(const DaftaryApp());
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
                  builder: (context, child) => AppStartupGate(child: child!),
                );
              },
            ),
      ),
    );
  }
}
