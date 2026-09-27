import 'package:daftary/core/design_system/glass/app_glass_surface.dart';
import 'package:daftary/core/design_system/glass/app_glass_tokens.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_test_harness.dart';

void main() {
  for (final (name, theme, alpha) in [
    ('light', buildLightTheme(), onStyle.tintAlphaLight),
    ('dark', buildDarkTheme(), onStyle.tintAlphaDark),
  ]) {
    testWidgets('builds one GlassContainer from the style ($name)', (
      tester,
    ) async {
      await tester.pumpWidget(
        glassApp(
          style: onStyle,
          theme: theme,
          home: const Scaffold(
            body: AppGlassSurface(
              borderRadius: AppRadius.lg,
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text('content'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassContainer), findsOneWidget);
      expect(find.text('content'), findsOneWidget);

      final glass = tester.widget<GlassContainer>(find.byType(GlassContainer));
      final settings = glass.settings!;
      expect(
        settings.glassColor,
        theme.colorScheme.surface.withValues(alpha: alpha),
      );
      expect(settings.blur, onStyle.blur);
      expect(settings.thickness, AppGlassTokens.thickness);
      expect(settings.bodyMode, GlassBodyMode.clear);
      expect(glass.quality, GlassQuality.standard);
      expect(glass.padding, const EdgeInsets.all(AppSpacing.sm));
      final shape = glass.shape as LiquidRoundedSuperellipse;
      expect(shape.borderRadius, AppRadius.lg);
    });
  }

  testWidgets('defaults to a full-bleed (radius 0) shape', (tester) async {
    await tester.pumpWidget(
      glassApp(
        style: onStyle,
        home: const AppGlassSurface(child: SizedBox.expand()),
      ),
    );

    final glass = tester.widget<GlassContainer>(find.byType(GlassContainer));
    expect((glass.shape as LiquidRoundedSuperellipse).borderRadius, 0);
  });

  testWidgets('nesting one surface inside another trips the debug assert '
      '(FR-012)', (tester) async {
    await tester.pumpWidget(
      glassApp(
        style: onStyle,
        home: const AppGlassSurface(
          child: AppGlassSurface(child: SizedBox.expand()),
        ),
      ),
    );

    final error = tester.takeException();
    expect(error, isA<AssertionError>());
    expect(error.toString(), contains('FR-012'));
  });
}
