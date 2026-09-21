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
}
