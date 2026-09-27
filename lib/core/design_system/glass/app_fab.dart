import 'package:flutter/material.dart';

import '../tokens.dart';
import 'app_glass_scope.dart';
import 'app_glass_surface.dart';

enum _AppFabVariant { regular, small, extended }

/// Marks "no heroTag argument", so the Material default tag is kept.
class _DefaultHeroTagSentinel {
  const _DefaultHeroTagSentinel();
}

/// The Material default hero tag (a private framework constant), read from a
/// FAB built without one so both modes keep the exact default.
final Object? _materialDefaultHeroTag = const FloatingActionButton(
  onPressed: null,
).heroTag;

/// The app's floating action button: a Material [FloatingActionButton] that
/// sits on Liquid Glass when the user enables it.
///
/// OFF (or no `AppGlassScope`) builds exactly the matching
/// `FloatingActionButton` constructor. ON builds the same button with a
/// transparent background, `colorScheme.primary` foreground and no elevation,
/// on one [AppGlassSurface] shaped like the FAB itself. Tooltip, callback,
/// hero tag, size and touch target are unchanged.
class AppFab extends StatelessWidget {
  /// Mirrors [FloatingActionButton.new].
  const AppFab({
    required this.onPressed,
    required Widget this.child,
    super.key,
    this.tooltip,
    this.heroTag = const _DefaultHeroTagSentinel(),
  }) : _variant = _AppFabVariant.regular,
       label = null;

  /// Mirrors [FloatingActionButton.small].
  const AppFab.small({
    required this.onPressed,
    required Widget this.child,
    super.key,
    this.tooltip,
    this.heroTag = const _DefaultHeroTagSentinel(),
  }) : _variant = _AppFabVariant.small,
       label = null;

  /// Mirrors [FloatingActionButton.extended]; [child] is its `icon`.
  const AppFab.extended({
    required this.onPressed,
    required Widget this.label,
    super.key,
    this.tooltip,
    this.heroTag = const _DefaultHeroTagSentinel(),
    Widget? icon,
  }) : _variant = _AppFabVariant.extended,
       child = icon;

  final VoidCallback? onPressed;
  final String? tooltip;
  final Object? heroTag;

  /// The icon (the `child` of the regular and small FABs, the `icon` of the
  /// extended one).
  final Widget? child;

  /// The extended FAB's label; `null` for the other variants.
  final Widget? label;

  final _AppFabVariant _variant;

  Object? get _heroTag =>
      heroTag is _DefaultHeroTagSentinel ? _materialDefaultHeroTag : heroTag;

  @override
  Widget build(BuildContext context) {
    if (!AppGlassScope.enabledOf(context)) {
      return switch (_variant) {
        _AppFabVariant.regular => FloatingActionButton(
          onPressed: onPressed,
          tooltip: tooltip,
          heroTag: _heroTag,
          child: child,
        ),
        _AppFabVariant.small => FloatingActionButton.small(
          onPressed: onPressed,
          tooltip: tooltip,
          heroTag: _heroTag,
          child: child,
        ),
        _AppFabVariant.extended => FloatingActionButton.extended(
          onPressed: onPressed,
          tooltip: tooltip,
          heroTag: _heroTag,
          icon: child,
          label: label!,
        ),
      };
    }

    final foreground = Theme.of(context).colorScheme.primary;
    final fab = switch (_variant) {
      _AppFabVariant.regular => FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        heroTag: _heroTag,
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        child: child,
      ),
      _AppFabVariant.small => FloatingActionButton.small(
        onPressed: onPressed,
        tooltip: tooltip,
        heroTag: _heroTag,
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        child: child,
      ),
      _AppFabVariant.extended => FloatingActionButton.extended(
        onPressed: onPressed,
        tooltip: tooltip,
        heroTag: _heroTag,
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        icon: child,
        label: label!,
      ),
    };
    return AppGlassSurface(borderRadius: _cornerRadius(context), child: fab);
  }

  /// The FAB's own corner radius: the theme's `floatingActionButtonTheme`
  /// shape when set, otherwise Material 3's defaults (16 regular and
  /// extended, 12 small), so the glass lines up with the ink and focus
  /// highlights the transparent FAB still paints.
  double _cornerRadius(BuildContext context) {
    final shape = Theme.of(context).floatingActionButtonTheme.shape;
    if (shape is StadiumBorder || shape is CircleBorder) {
      return AppRadius.pill;
    }
    if (shape is RoundedRectangleBorder) {
      return shape.borderRadius.resolve(Directionality.of(context)).topLeft.x;
    }
    return switch (_variant) {
      _AppFabVariant.regular || _AppFabVariant.extended => AppRadius.lg,
      _AppFabVariant.small => AppRadius.md,
    };
  }
}
