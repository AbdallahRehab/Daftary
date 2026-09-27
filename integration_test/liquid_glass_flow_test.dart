import 'package:daftary/core/design_system/glass/app_glass_scope.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:daftary/features/settings/domain/entities/glass_level.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// End-to-end Liquid Glass flow (020 US1/US2; quickstart.md scenarios 1, 2
/// and 4; FR-022). Runs against the real app (real DI, real on-device
/// SQLite), like theme_switch_flow_test.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Rebuilds GetIt from scratch and resolves startup exactly like `main()`,
  /// so calling it again simulates a restart that only knows what was
  /// actually persisted.
  Future<void> bootApp(WidgetTester tester) async {
    await getIt.reset();
    await configureDependencies();
    await getIt<OnboardingRepository>().completeOnboarding();
    await getIt<AppStartupCubit>().start();
    appRouter.go('/people');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  AppGlassScope scopeOf(WidgetTester tester) =>
      tester.widget<AppGlassScope>(find.byType(AppGlassScope));

  testWidgets(
    'toggling glass switches the chrome live, and a relaunch restores the '
    'saved on/off state and levels (US1, US2)',
    (tester) async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      await bootApp(tester);
      final cubit = getIt<SettingsCubit>();

      await cubit.setGlassEnabled(true);
      await tester.pumpAndSettle();
      expect(scopeOf(tester).style.enabled, isTrue);
      expect(find.byType(GlassContainer), findsWidgets);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(en.settingsTitle),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_liquid_glass_switch')));
      await tester.pumpAndSettle();

      expect(scopeOf(tester).style.enabled, isFalse);
      expect(find.byType(GlassContainer), findsNothing);

      await cubit.setGlassEnabled(true);
      await cubit.setGlassTransparency(GlassLevel.high);
      await cubit.setGlassIntensity(GlassLevel.low);
      await tester.pumpAndSettle();

      // Simulated restart: only the persisted row survives.
      await bootApp(tester);
      final restored = getIt<SettingsCubit>().state.glassAppearance;
      expect(restored.enabled, isTrue);
      expect(restored.transparency, GlassLevel.high);
      expect(restored.intensity, GlassLevel.low);
    },
  );

  testWidgets('a glass-only change does not rebuild MaterialApp (FR-022)', (
    tester,
  ) async {
    await bootApp(tester);
    final cubit = getIt<SettingsCubit>();
    await cubit.setGlassEnabled(true);
    await cubit.setGlassIntensity(GlassLevel.medium);
    await tester.pumpAndSettle();

    final appBefore = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final blurBefore = scopeOf(tester).style.blur;

    await cubit.setGlassIntensity(GlassLevel.high);
    await tester.pumpAndSettle();

    // The root BlocBuilder did not re-run: MaterialApp is the same instance.
    expect(
      identical(
        tester.widget<MaterialApp>(find.byType(MaterialApp)),
        appBefore,
      ),
      isTrue,
    );
    // …while the scope below it did pick up the new level.
    expect(scopeOf(tester).style.blur, isNot(blurBefore));
  });
}
