import 'package:flutter/material.dart';

import '../tokens.dart';
import 'app_glass_scope.dart';
import 'app_glass_surface.dart';

/// Shows a modal bottom sheet that sits on Liquid Glass when the user enables
/// it.
///
/// OFF (or no `AppGlassScope`) is exactly
/// `showModalBottomSheet<T>(context:, isScrollControlled:, builder:)`. ON adds
/// a transparent, unelevated sheet whose body is wrapped in one
/// [AppGlassSurface]. The glass state is read from [context] once, before the
/// route is pushed, without subscribing the caller to glass changes.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  final glassOn =
      context.getInheritedWidgetOfExactType<AppGlassScope>()?.style.enabled ??
      false;
  if (!glassOn) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      builder: builder,
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (sheetContext) => AppGlassSurface(
      borderRadius: AppRadius.lg,
      child: builder(sheetContext),
    ),
  );
}
