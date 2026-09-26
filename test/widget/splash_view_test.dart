import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/startup/presentation/widgets/splash_mark.dart';
import 'package:daftary/features/startup/presentation/widgets/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 019 US1: the splash surface in both themes, both languages/directions,
/// and across phone, landscape, tablet, and large-text layouts.
void main() {
  Future<void> pumpSplash(
    WidgetTester tester, {
    ThemeData? theme,
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const SplashView(intro: AlwaysStoppedAnimation(1.0)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color fieldColor(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    return (container.decoration! as BoxDecoration).color!;
  }

  testWidgets('light theme uses the brand field', (tester) async {
    await pumpSplash(tester, theme: buildLightTheme());
    expect(fieldColor(tester), AppBrandColors.field);
  });

  testWidgets('dark theme uses the deep brand field', (tester) async {
    await pumpSplash(tester, theme: buildDarkTheme());
    expect(fieldColor(tester), AppBrandColors.fieldDeep);
  });

  testWidgets('English shows the name and tagline left-to-right', (
    tester,
  ) async {
    await pumpSplash(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(SplashView)))!;
    expect(find.text('Daftary'), findsOneWidget);
    expect(find.text(l10n.splashTagline), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(SplashMark))),
      TextDirection.ltr,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic shows the name and tagline right-to-left', (
    tester,
  ) async {
    await pumpSplash(tester, locale: const Locale('ar'));
    expect(find.text('دفتري'), findsOneWidget);
    expect(find.text('كل أخذ وعطاء في دفتر واحد'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(SplashMark))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  group('layout never overflows', () {
    for (final (label, size) in [
      ('small phone 320x480', const Size(320, 480)),
      ('landscape phone 740x360', const Size(740, 360)),
      ('tablet 1024x1366', const Size(1024, 1366)),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$label at text scale $scale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final locale in [const Locale('en'), const Locale('ar')]) {
            await pumpSplash(tester, locale: locale, textScale: scale);
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  });

  testWidgets('announces the app name once, as a header; mark is decorative', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpSplash(tester);
    expect(
      tester.getSemantics(find.text('Daftary')),
      isSemantics(label: 'Daftary', isHeader: true),
    );
    expect(find.bySemanticsLabel('Daftary'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SplashMark),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
    semantics.dispose();
  });
}
