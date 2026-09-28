import 'package:flutter/material.dart';

import 'app_glass_scope.dart';

/// The app's page scaffold: a [Scaffold] that lets content scroll beneath
/// glass bars when Liquid Glass is ON (research Decision 6).
///
/// ON: the body extends behind the app bar when there is one, and behind the
/// bottom bar when there is one, so the glass has moving content to frost.
/// Scrollables with an explicit `padding:` add `AppGlassInsets.of(context)`.
/// OFF (or no `AppGlassScope`): every argument reaches the [Scaffold]
/// unchanged, so OFF layouts are identical to a plain [Scaffold].
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final glassOn = AppGlassScope.enabledOf(context);
    final scaffold = Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: glassOn
          ? bottomNavigationBar != null || extendBody
          : extendBody,
      extendBodyBehindAppBar: glassOn
          ? appBar != null || extendBodyBehindAppBar
          : extendBodyBehindAppBar,
    );
    if (!glassOn || floatingActionButton == null) return scaffold;
    // ON, inside the shell: the shell's body extends behind its glass bottom
    // bar and reports the bar's height as bottom `padding`, but not as
    // `viewPadding` (Scaffold only re-adds `padding`). A floating FAB is
    // placed from `viewPadding`, so it would sit under the bar, where taps
    // reach the bar instead. Raising `viewPadding` to `padding` restores the
    // usual `viewPadding >= padding` and puts the FAB just above the bar,
    // where it is with glass OFF.
    final padding = MediaQuery.paddingOf(context).bottom;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    if (viewPadding.bottom >= padding) return scaffold;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(viewPadding: viewPadding.copyWith(bottom: padding)),
      child: scaffold,
    );
  }
}
