import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/glass/app_glass_scope.dart';
import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/settings/domain/entities/glass_appearance.dart';
import 'package:daftary/features/settings/domain/entities/glass_level.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_state.dart';
import 'package:daftary/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/design_system/glass/glass_test_harness.dart';

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

const _switchKey = Key('settings_liquid_glass_switch');
const _transparencyKey = Key('settings_glass_transparency');
const _intensityKey = Key('settings_glass_intensity');
const _previewKey = Key('settings_glass_preview');

const _glassOn = SettingsState();
const _glassOff = SettingsState(
  glassAppearance: GlassAppearance(enabled: false),
);

void main() {
  late MockSettingsCubit cubit;

  setUpAll(() {
    registerFallbackValue(GlassLevel.medium);
  });

  setUp(() {
    cubit = MockSettingsCubit();
    when(() => cubit.setGlassEnabled(any())).thenAnswer((_) async {});
    when(() => cubit.setGlassTransparency(any())).thenAnswer((_) async {});
    when(() => cubit.setGlassIntensity(any())).thenAnswer((_) async {});
  });

  /// Pumps the page as production does: the scope's `enabled` follows the
  /// state's preference. A tall surface keeps every section built without
  /// scrolling.
  Future<void> pumpPage(
    WidgetTester tester,
    SettingsState state, {
    Locale locale = const Locale('en'),
    Stream<SettingsState>? stream,
  }) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (stream != null) {
      whenListen(cubit, stream, initialState: state);
    } else {
      when(() => cubit.state).thenReturn(state);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AppGlassScope(
          style: state.glassAppearance.enabled ? onStyle : AppGlassStyle.off,
          child: child!,
        ),
        home: BlocProvider<SettingsCubit>.value(
          value: cubit,
          child: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  SegmentedButton<GlassLevel> segmented(WidgetTester tester, Key key) {
    return tester.widget<SegmentedButton<GlassLevel>>(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(SegmentedButton<GlassLevel>),
      ),
    );
  }

  group('US1: Liquid Glass switch', () {
    testWidgets('reflects glassAppearance.enabled', (tester) async {
      await pumpPage(tester, _glassOn);
      expect(
        tester.widget<SwitchListTile>(find.byKey(_switchKey)).value,
        isTrue,
      );

      await pumpPage(tester, _glassOff);
      expect(
        tester.widget<SwitchListTile>(find.byKey(_switchKey)).value,
        isFalse,
      );
    });

    testWidgets('tapping it calls setGlassEnabled(!enabled)', (tester) async {
      await pumpPage(tester, _glassOn);
      await tester.tap(find.byKey(_switchKey));
      await tester.pump();
      verify(() => cubit.setGlassEnabled(false)).called(1);
    });

    testWidgets('tapping it while OFF calls setGlassEnabled(true)', (
      tester,
    ) async {
      await pumpPage(tester, _glassOff);
      await tester.tap(find.byKey(_switchKey));
      await tester.pump();
      verify(() => cubit.setGlassEnabled(true)).called(1);
    });

    testWidgets('shows glassSaveFailed once when isGlassPersistFailing '
        'flips false -> true', (tester) async {
      final states = StreamController<SettingsState>();
      addTearDown(states.close);
      await pumpPage(tester, _glassOn, stream: states.stream);

      const failing = SettingsState(isGlassPersistFailing: true);
      states.add(failing);
      await tester.pump();
      // A further emission that keeps the flag raised must not re-show it.
      states.add(
        failing.copyWith(
          glassAppearance: const GlassAppearance(transparency: GlassLevel.high),
        ),
      );
      await tester.pump();

      const message =
          "Couldn't save your glass setting. It will apply until you close "
          'the app.';
      expect(find.text(message), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('glass failure takes priority over theme failure', (
      tester,
    ) async {
      final states = StreamController<SettingsState>();
      addTearDown(states.close);
      await pumpPage(tester, _glassOn, stream: states.stream);

      states.add(
        const SettingsState(
          isGlassPersistFailing: true,
          isThemeModePersistFailing: true,
        ),
      );
      await tester.pump(); // deliver the emission to the listener
      await tester.pump(); // build the SnackBar

      expect(find.textContaining('glass setting'), findsOneWidget);
      expect(find.textContaining('theme choice'), findsNothing);
    });

    testWidgets('sits in an Appearance section directly after Theme', (
      tester,
    ) async {
      await pumpPage(tester, _glassOff);

      final themeY = tester.getTopLeft(find.text('Theme')).dy;
      final systemY = tester.getTopLeft(find.text('System default')).dy;
      final appearanceY = tester.getTopLeft(find.text('Appearance')).dy;
      final switchY = tester.getTopLeft(find.byKey(_switchKey)).dy;
      final currencyY = tester
          .getTopLeft(find.byKey(const Key('settings_currency_entry')))
          .dy;

      expect(themeY, lessThan(systemY));
      expect(systemY, lessThan(appearanceY));
      expect(appearanceY, lessThan(switchY));
      expect(switchY, lessThan(currencyY));
      expect(find.text('Liquid Glass'), findsOneWidget);
      expect(
        find.text('Frosted glass effect on bars and buttons'),
        findsOneWidget,
      );
    });

    testWidgets('renders the Arabic strings under the Arabic locale', (
      tester,
    ) async {
      await pumpPage(tester, _glassOn, locale: const Locale('ar'));

      // Distinct from the Arabic Theme heading ("المظهر").
      expect(find.text('التأثيرات المرئية'), findsOneWidget);
      expect(find.text('المظهر'), findsOneWidget);
      // The switch title, plus the preview's sample strip.
      expect(find.text('الزجاج السائل'), findsNWidgets(2));
      expect(
        find.text('تأثير زجاجي مصنفر على الأشرطة والأزرار'),
        findsOneWidget,
      );
      expect(find.text('شفافية الزجاج'), findsOneWidget);
      expect(find.text('قوة الزجاج'), findsOneWidget);
      expect(find.text('عالية'), findsNWidgets(2));
    });
  });

  group('US2: transparency and intensity', () {
    testWidgets('with glass ON both selectors show the current levels', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const SettingsState(
          glassAppearance: GlassAppearance(
            transparency: GlassLevel.low,
            intensity: GlassLevel.high,
          ),
        ),
      );

      expect(find.text('Glass transparency'), findsOneWidget);
      expect(find.text('Glass intensity'), findsOneWidget);
      expect(segmented(tester, _transparencyKey).selected, {GlassLevel.low});
      expect(segmented(tester, _intensityKey).selected, {GlassLevel.high});
      expect(segmented(tester, _transparencyKey).showSelectedIcon, isFalse);
    });

    testWidgets('selecting High calls setGlassTransparency(high)', (
      tester,
    ) async {
      await pumpPage(tester, _glassOn);
      await tester.tap(
        find.descendant(
          of: find.byKey(_transparencyKey),
          matching: find.text('High'),
        ),
      );
      await tester.pump();
      verify(() => cubit.setGlassTransparency(GlassLevel.high)).called(1);
      verifyNever(() => cubit.setGlassIntensity(any()));
    });

    testWidgets('selecting High calls setGlassIntensity(high)', (tester) async {
      await pumpPage(tester, _glassOn);
      await tester.tap(
        find.descendant(
          of: find.byKey(_intensityKey),
          matching: find.text('High'),
        ),
      );
      await tester.pump();
      verify(() => cubit.setGlassIntensity(GlassLevel.high)).called(1);
      verifyNever(() => cubit.setGlassTransparency(any()));
    });

    testWidgets('with glass OFF neither selector is in the tree', (
      tester,
    ) async {
      await pumpPage(tester, _glassOff);
      expect(find.byKey(_transparencyKey), findsNothing);
      expect(find.byKey(_intensityKey), findsNothing);
      expect(find.byType(SegmentedButton<GlassLevel>), findsNothing);
    });

    testWidgets('toggling OFF then ON shows the previously selected levels', (
      tester,
    ) async {
      const levels = GlassAppearance(
        transparency: GlassLevel.high,
        intensity: GlassLevel.low,
      );
      final states = StreamController<SettingsState>();
      addTearDown(states.close);
      const on = SettingsState(glassAppearance: levels);
      await pumpPage(tester, on, stream: states.stream);

      states.add(
        SettingsState(glassAppearance: levels.copyWith(enabled: false)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_transparencyKey), findsNothing);

      states.add(on);
      await tester.pumpAndSettle();
      expect(segmented(tester, _transparencyKey).selected, {GlassLevel.high});
      expect(segmented(tester, _intensityKey).selected, {GlassLevel.low});
    });
  });

  group('US3: preview', () {
    testWidgets('is present only when glass is ON', (tester) async {
      await pumpPage(tester, _glassOn);
      expect(find.byKey(_previewKey), findsOneWidget);

      await pumpPage(tester, _glassOff);
      expect(find.byKey(_previewKey), findsNothing);
    });
  });
}
