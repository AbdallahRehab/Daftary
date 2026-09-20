import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/people/presentation/pages/archived_people_page.dart';
import '../../features/people/presentation/pages/people_list_page.dart';
import '../../features/people/presentation/pages/person_edit_page.dart';
import '../../features/people/presentation/pages/person_form_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transactions/presentation/pages/overview_page.dart';
import '../../features/transactions/presentation/pages/person_detail_page.dart';
import '../../features/transactions/presentation/pages/repayment_form_page.dart';
import '../../features/transactions/presentation/pages/transaction_edit_page.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import 'main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _peopleBranchNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'peopleBranch');
final GlobalKey<NavigatorState> _overviewBranchNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'overviewBranch');
final GlobalKey<NavigatorState> _settingsBranchNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settingsBranch');

/// The app's single declarative router (constitution: centralized navigation,
/// no per-widget navigation decisions). Three `StatefulShellRoute.indexedStack`
/// branches — People (home), Overview, Settings — each keep their own
/// `Navigator`/state automatically (research.md Decision 1), so switching
/// tabs or the app language never discards a branch's navigation position
/// (FR-014). No route paths were removed from the prior flat route list.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _peopleBranchNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const PeopleListPage(),
            ),
            GoRoute(
              path: '/people',
              builder: (context, state) => const PeopleListPage(),
            ),
            GoRoute(
              path: '/people/new',
              builder: (context, state) => const PersonFormPage(),
            ),
            GoRoute(
              path: '/people/archived',
              builder: (context, state) => const ArchivedPeoplePage(),
            ),
            GoRoute(
              path: '/people/:id/edit',
              builder: (context, state) =>
                  PersonEditPage(personId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/transactions/new',
              builder: (context, state) => TransactionFormPage(
                personId: state.uri.queryParameters['personId'],
              ),
            ),
            GoRoute(
              path: '/transactions/:id/edit',
              builder: (context, state) => TransactionEditPage(
                transactionId: state.pathParameters['id']!,
                args: state.extra as TransactionEditArgs?,
              ),
            ),
            GoRoute(
              path: '/people/:id',
              builder: (context, state) =>
                  PersonDetailPage(personId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/people/:id/repayment',
              builder: (context, state) =>
                  RepaymentFormPage(personId: state.pathParameters['id']!),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _overviewBranchNavigatorKey,
          routes: [
            GoRoute(
              path: '/overview',
              builder: (context, state) => const OverviewPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _settingsBranchNavigatorKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
