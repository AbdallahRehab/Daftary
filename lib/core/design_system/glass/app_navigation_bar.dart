import 'package:flutter/material.dart';

import 'app_glass_scope.dart';
import 'app_glass_surface.dart';

/// The compact-layout bottom bar: a Material [NavigationBar] that turns to
/// Liquid Glass when the user enables it.
///
/// OFF (or no `AppGlassScope`) builds exactly the [NavigationBar]. ON puts one
/// [AppGlassSurface] behind the same bar, filling its bounds including the
/// bottom safe area, and makes the bar itself transparent. Destinations,
/// labels, selection and callbacks are unchanged.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    required this.destinations,
    super.key,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<Widget> destinations;

  @override
  Widget build(BuildContext context) {
    if (!AppGlassScope.enabledOf(context)) {
      return NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      );
    }
    return Stack(
      children: [
        const Positioned.fill(child: AppGlassSurface(child: SizedBox.expand())),
        NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ],
    );
  }
}
