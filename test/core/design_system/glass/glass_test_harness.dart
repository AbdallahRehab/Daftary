import 'package:daftary/core/design_system/glass/app_glass_scope.dart';
import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/glass/app_glass_tokens.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:flutter/material.dart';

/// Glass ON at the Medium levels, as the app's default preference maps.
const onStyle = AppGlassStyle(
  enabled: true,
  tintAlphaLight: AppGlassTokens.tintAlphaLightMedium,
  tintAlphaDark: AppGlassTokens.tintAlphaDarkMedium,
  blur: AppGlassTokens.blurMedium,
);

/// Pumps [home] the way production does: the app theme, and an
/// [AppGlassScope] (when [style] is non-null) inserted by
/// `MaterialApp.builder`, above the navigator. [style] `null` means "no scope",
/// which components treat as OFF.
Widget glassApp({
  required Widget home,
  AppGlassStyle? style,
  ThemeData? theme,
  TextDirection textDirection = TextDirection.ltr,
  double textScale = 1,
}) {
  return MaterialApp(
    theme: theme ?? buildLightTheme(),
    builder: (context, child) {
      Widget result = Directionality(
        textDirection: textDirection,
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      );
      if (style != null) {
        result = AppGlassScope(style: style, child: result);
      }
      return result;
    },
    home: home,
  );
}
