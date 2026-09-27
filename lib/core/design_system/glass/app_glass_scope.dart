import 'package:flutter/widgets.dart';

import 'app_glass_style.dart';

/// Provides the current [AppGlassStyle] to the adaptive glass components.
///
/// Inserted once at the app root. Only the components in this folder (and the
/// Settings preview) read it; screens never do (FR-014, FR-022), so changing
/// the style rebuilds just those components.
///
/// No scope in the tree means glass is OFF (research Decision 13), so widget
/// tests that pump a page without the app root see the plain Material widgets.
class AppGlassScope extends InheritedWidget {
  const AppGlassScope({required this.style, required super.child, super.key});

  final AppGlassStyle style;

  /// The nearest scope's style, or `null` when there is no scope.
  static AppGlassStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppGlassScope>()?.style;

  /// The nearest scope's style, or [AppGlassStyle.off] when there is none.
  static AppGlassStyle of(BuildContext context) =>
      maybeOf(context) ?? AppGlassStyle.off;

  /// Whether glass is ON for [context].
  static bool enabledOf(BuildContext context) => of(context).enabled;

  @override
  bool updateShouldNotify(AppGlassScope oldWidget) => oldWidget.style != style;
}
