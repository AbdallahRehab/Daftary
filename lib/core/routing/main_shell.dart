import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/glass/app_navigation_bar.dart';
import '../design_system/glass/app_scaffold.dart';
import '../design_system/tokens.dart';
import '../../features/cloud_sync/presentation/widgets/sync_notice_sheet.dart';
import '../l10n/app_localizations.dart';

/// The app shell for the three top-level sections: People (home),
/// Overview, Settings. Built on `StatefulShellRoute`'s
/// `StatefulNavigationShell`, so each branch keeps its own navigator/state
/// across tab switches (FR-014).
///
/// Structure follows the Material window size class, measured from the
/// available width (so split-screen and foldables adapt too):
/// - compact (< 600dp): a bottom `NavigationBar`, content full width;
/// - medium and up: a `NavigationRail` on the leading edge, and every page
///   in a centered column capped at [AppBreakpoints.maxContentWidth] on a
///   tinted canvas — never a phone layout stretched across a tablet.
///
/// Both Material widgets lay out by the ambient `Directionality`, so the
/// rail and tab order mirror under RTL with no custom logic (research.md
/// Decision 6).
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) =>
      // 021 T081: the shell mounts only once startup is ready, so the
      // one-time sync notice is hosted here. The host is always the root,
      // so its state survives a layout switch.
      SyncNoticeHost(child: Builder(builder: _buildShell));

  Widget _buildShell(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = [
      (Icons.people_outline, Icons.people, l10n.peopleListTitle),
      (Icons.pie_chart_outline, Icons.pie_chart, l10n.overviewTitle),
      (Icons.settings_outlined, Icons.settings, l10n.settingsTitle),
    ];

    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.medium) {
      return AppScaffold(
        body: navigationShell,
        bottomNavigationBar: AppNavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final (icon, selectedIcon, label) in destinations)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(selectedIcon),
                label: label,
              ),
          ],
        ),
      );
    }

    final canvas = Theme.of(context).colorScheme.surfaceContainerLow;
    return Scaffold(
      backgroundColor: canvas,
      // Horizontal insets only: in landscape the display cutout sits on a
      // side edge, while each page's own app bar and FAB already handle
      // the top and bottom.
      body: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            NavigationRail(
              backgroundColor: canvas,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -1,
              destinations: [
                for (final (icon, selectedIcon, label) in destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selectedIcon),
                    label: Text(label),
                  ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.maxContentWidth,
                  ),
                  // Each page's own Scaffold paints `surface`, so the
                  // column reads as a sheet on the tinted canvas.
                  child: navigationShell,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
