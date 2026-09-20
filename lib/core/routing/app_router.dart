import 'package:go_router/go_router.dart';

import '../../features/people/presentation/pages/archived_people_page.dart';
import '../../features/people/presentation/pages/people_list_page.dart';
import '../../features/people/presentation/pages/person_edit_page.dart';
import '../../features/people/presentation/pages/person_form_page.dart';
import '../../features/transactions/presentation/pages/overview_page.dart';
import '../../features/transactions/presentation/pages/person_detail_page.dart';
import '../../features/transactions/presentation/pages/repayment_form_page.dart';
import '../../features/transactions/presentation/pages/transaction_edit_page.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';

/// The app's single declarative router (constitution: centralized navigation,
/// no per-widget navigation decisions). `PeopleListPage` is the app's home/
/// landing route (US5, T093).
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const PeopleListPage()),
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
      builder: (context, state) =>
          TransactionFormPage(personId: state.uri.queryParameters['personId']),
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
    GoRoute(
      path: '/overview',
      builder: (context, state) => const OverviewPage(),
    ),
  ],
);
