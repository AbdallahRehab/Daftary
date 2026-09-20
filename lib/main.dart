import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/design_system/tokens.dart';
import 'core/di/injection.dart';
import 'core/l10n/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/settings/presentation/cubit/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  // Resolved before the first frame so it already reflects the persisted/
  // first-launch-default language, rather than SettingsCubit's hardcoded
  // AppLanguage.english initial state (T025).
  await getIt<SettingsCubit>().initialize();
  runApp(const DaftaryApp());
}

class DaftaryApp extends StatelessWidget {
  const DaftaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>.value(
      value: getIt<SettingsCubit>(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            theme: buildAppTheme(),
            routerConfig: appRouter,
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
