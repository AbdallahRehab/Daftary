import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app_glass_scope.dart';
import 'app_glass_tokens.dart';

/// The app's single Liquid Glass primitive, and the **only** place that
/// constructs the package's `GlassContainer` (research Decision 5).
///
/// The tint is the theme's `colorScheme.surface` at the scope's alpha for the
/// current brightness, composited directly (`GlassBodyMode.clear`) so the bar
/// is reliably lighter or darker than the content behind it. Quality is always
/// `standard`, for one predictable look across renderers.
///
/// Surfaces never nest (FR-012): a debug assertion fails if this is built
/// inside another [AppGlassSurface].
class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    required this.child,
    super.key,
    this.borderRadius = 0,
    this.padding,
  });

  final Widget child;

  /// Corner radius of the superellipse; 0 for full-bleed bars.
  final double borderRadius;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    assert(
      context.getInheritedWidgetOfExactType<_GlassSurfaceMarker>() == null,
      'An AppGlassSurface must not be placed inside another AppGlassSurface '
      '(FR-012).',
    );
    final theme = Theme.of(context);
    final style = AppGlassScope.of(context);
    final tintAlpha = theme.brightness == Brightness.dark
        ? style.tintAlphaDark
        : style.tintAlphaLight;

    return GlassContainer(
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
      quality: GlassQuality.standard,
      padding: padding,
      settings: LiquidGlassSettings(
        glassColor: theme.colorScheme.surface.withValues(alpha: tintAlpha),
        blur: style.blur,
        thickness: AppGlassTokens.thickness,
        bodyMode: GlassBodyMode.clear,
      ),
      child: _GlassSurfaceMarker(child: child),
    );
  }
}

/// Marks the subtree below an [AppGlassSurface] for the nesting assertion.
class _GlassSurfaceMarker extends InheritedWidget {
  const _GlassSurfaceMarker({required super.child});

  @override
  bool updateShouldNotify(_GlassSurfaceMarker oldWidget) => false;
}
