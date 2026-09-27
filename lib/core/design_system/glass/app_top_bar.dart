import 'package:flutter/material.dart';

import 'app_glass_scope.dart';
import 'app_glass_surface.dart';

/// The app's top bar: a Material [AppBar] that turns to Liquid Glass when the
/// user enables it.
///
/// OFF (or no `AppGlassScope`) builds exactly `AppBar(...)` from these
/// arguments. ON builds the same `AppBar` made transparent, with one
/// [AppGlassSurface] as its `flexibleSpace`; title, actions, leading, back
/// navigation, tooltips, semantics and height are unchanged.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.centerTitle,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle;

  /// Identical to the equivalent [AppBar]'s.
  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    if (!AppGlassScope.enabledOf(context)) {
      return AppBar(
        title: title,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        bottom: bottom,
        centerTitle: centerTitle,
      );
    }
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: const AppGlassSurface(child: SizedBox.expand()),
    );
  }
}
