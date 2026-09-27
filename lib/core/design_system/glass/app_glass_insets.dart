import 'package:flutter/widgets.dart';

import 'app_glass_scope.dart';

/// Extra scroll padding for content that passes beneath glass chrome
/// (research Decision 6).
///
/// When glass is ON, an `AppScaffold` extends its body behind the top and
/// bottom bars, so a scrollable with its own explicit `padding:` adds
/// `AppGlassInsets.of(context)` to keep its first and last items clear of the
/// bars. When glass is OFF this is [EdgeInsets.zero], so OFF layouts are
/// unchanged (SC-003).
abstract final class AppGlassInsets {
  static EdgeInsets of(BuildContext context) => AppGlassScope.enabledOf(context)
      ? MediaQuery.paddingOf(context)
      : EdgeInsets.zero;
}
