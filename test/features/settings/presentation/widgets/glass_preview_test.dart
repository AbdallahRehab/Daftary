import 'package:daftary/core/design_system/glass/app_glass_scope.dart';
import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/glass/app_glass_surface.dart';
import 'package:daftary/core/design_system/glass/app_glass_tokens.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/settings/presentation/widgets/glass_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/design_system/glass/glass_test_harness.dart';

void main() {
  /// Like the core `glassApp` harness, plus app localizations.
  Widget localizedPreview({
    AppGlassStyle style = onStyle,
    ThemeData? theme,
    TextDirection textDirection = TextDirection.ltr,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      theme: theme ?? buildLightTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => AppGlassScope(
        style: style,
        child: Directionality(textDirection: textDirection, child: child!),
      ),
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: GlassPreview(),
        ),
      ),
    );
  }

  testWidgets('contains one AppGlassSurface and the localized sample title', (
    tester,
  ) async {
    await tester.pumpWidget(localizedPreview());

    expect(find.byType(AppGlassSurface), findsOneWidget);
    expect(find.byType(GlassContainer), findsOneWidget);
    expect(find.text('Liquid Glass'), findsOneWidget);
    expect(find.text('Preview'), findsNWidgets(2));
  });

  testWidgets('a new scope style reaches the glass within one pump', (
    tester,
  ) async {
    await tester.pumpWidget(localizedPreview());
    const stronger = AppGlassStyle(
      enabled: true,
      tintAlphaLight: AppGlassTokens.tintAlphaLightHigh,
      tintAlphaDark: AppGlassTokens.tintAlphaDarkHigh,
      blur: AppGlassTokens.blurHigh,
    );
    // pumpWidget is a single frame: no settling needed.
    await tester.pumpWidget(localizedPreview(style: stronger));

    final glass = tester.widget<GlassContainer>(find.byType(GlassContainer));
    expect(glass.settings!.blur, AppGlassTokens.blurHigh);
  });

  testWidgets('the dark backdrop uses colorScheme colours', (tester) async {
    final dark = buildDarkTheme();
    await tester.pumpWidget(localizedPreview(theme: dark));

    final blobColors = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(GlassPreview),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.shape == BoxShape.circle)
        .map((d) => d.color)
        .toSet();
    expect(blobColors, {
      dark.colorScheme.primary,
      dark.colorScheme.tertiary,
      dark.colorScheme.secondary,
    });
  });

  testWidgets('the sample icon is on the leading (right) side in RTL', (
    tester,
  ) async {
    await tester.pumpWidget(localizedPreview(textDirection: TextDirection.rtl));

    final previewRect = tester.getRect(find.byType(GlassPreview));
    final iconCenter = tester.getCenter(
      find.byKey(const Key('glass_preview_icon')),
    );
    final titleCenter = tester.getCenter(find.text('Liquid Glass'));
    expect(iconCenter.dx, greaterThan(previewRect.center.dx));
    expect(iconCenter.dx, greaterThan(titleCenter.dx));
  });

  testWidgets('exposes one semantics label and is excluded from focus', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(localizedPreview());

    expect(
      find.bySemanticsLabel(
        'Sample of the Liquid Glass effect with your current settings',
      ),
      findsOneWidget,
    );
    final excludeFocus = tester.widget<ExcludeFocus>(
      find
          .ancestor(
            of: find.byType(AppGlassSurface),
            matching: find.byType(ExcludeFocus),
          )
          .first,
    );
    expect(excludeFocus.excluding, isTrue);
    semantics.dispose();
  });

  testWidgets('renders the Arabic sample strings', (tester) async {
    await tester.pumpWidget(
      localizedPreview(
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('الزجاج السائل'), findsOneWidget);
    expect(find.text('معاينة'), findsNWidgets(2));
  });
}
