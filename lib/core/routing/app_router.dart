import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/cloud_sync/presentation/pages/sync_settings_page.dart';
import '../../features/currency/presentation/pages/currency_settings_page.dart';
import '../../features/currency/presentation/pages/exchange_rate_form_page.dart';
import '../../features/currency/presentation/pages/exchange_rate_list_page.dart';
import '../../features/insights_notifications/presentation/pages/notification_settings_page.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../features/onboarding/presentation/cubit/onboarding_state.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/finance/domain/entities/finance_entry_type.dart';
import '../../features/finance/presentation/pages/category_form_page.dart';
import '../../features/finance/presentation/pages/category_management_page.dart';
import '../../features/finance/presentation/pages/finance_entry_form_page.dart';
import '../../features/finance/presentation/pages/finance_history_page.dart';
import '../../features/financial_education/presentation/pages/article_page.dart';
import '../../features/financial_education/presentation/pages/category_page.dart';
import '../../features/financial_education/presentation/pages/compound_growth_calculator_page.dart';
import '../../features/financial_education/presentation/pages/content_library_home_page.dart';
import '../../features/financial_education/presentation/pages/doubling_time_calculator_page.dart';
import '../../features/financial_education/presentation/pages/savings_rate_calculator_page.dart';
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
import '../di/injection.dart';
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
  // FR-001/FR-010a: `OnboardingCubit.initialize()` is settled before
  // `AppStartupGate` (019) mounts the Router, so its state is already final
  // by the time any redirect runs — no `refreshListenable`/async redirect is
  // needed (research.md Decision 1).
  redirect: (context, state) {
    final onboarding = getIt<OnboardingCubit>().state;
    final onOnboardingRoute = state.matchedLocation == '/onboarding';
    if (onboarding.status == OnboardingLoadStatus.showOnboarding &&
        !onOnboardingRoute) {
      return '/onboarding';
    }
    if (onboarding.status == OnboardingLoadStatus.mainApp &&
        onOnboardingRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
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
            // The finance section lives in the People branch rather than a
            // fourth bottom-nav tab (research.md Decision 9); it is reached
            // from the Overview summary card and from the quick actions.
            GoRoute(
              path: '/finance',
              builder: (context, state) => const FinanceHistoryPage(),
            ),
            GoRoute(
              path: '/finance/entries/new',
              builder: (context, state) => FinanceEntryFormPage(
                initialType: _financeEntryTypeFrom(
                  state.uri.queryParameters['type'],
                ),
              ),
            ),
            GoRoute(
              path: '/finance/entries/:id/edit',
              builder: (context, state) => FinanceEntryFormPage(
                editingEntryId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: '/finance/categories',
              builder: (context, state) => const CategoryManagementPage(),
            ),
            GoRoute(
              path: '/finance/categories/new',
              builder: (context, state) => CategoryFormPage(
                // The management screen passes the type it is currently
                // showing, so "add category" from the income tab opens an
                // income category rather than silently defaulting away.
                initialType: state.extra is CategoryType
                    ? state.extra! as CategoryType
                    : _financeEntryTypeFrom(state.uri.queryParameters['type']),
              ),
            ),
            GoRoute(
              path: '/finance/categories/:id/edit',
              builder: (context, state) => CategoryFormPage(
                editingCategoryId: state.pathParameters['id']!,
              ),
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
            // Notification settings (017) live under Settings, alongside
            // Language/Theme (spec.md Assumptions "Navigation placement").
            GoRoute(
              path: NotificationSettingsRoutes.settings,
              builder: (context, state) => const NotificationSettingsPage(),
            ),
            // Cloud backup and sync (021 US6).
            GoRoute(
              path: SyncSettingsRoutes.settings,
              builder: (context, state) => const SyncSettingsPage(),
            ),
            // Currency settings (018): primary currency and the manual
            // exchange rates. `new` is declared before `:code/edit`; the
            // segment counts differ anyway, so it can never be captured as
            // a currency code.
            GoRoute(
              path: CurrencyRoutes.settings,
              builder: (context, state) => const CurrencySettingsPage(),
            ),
            GoRoute(
              path: CurrencyRoutes.rates,
              builder: (context, state) => const ExchangeRateListPage(),
            ),
            GoRoute(
              path: CurrencyRoutes.newRate,
              builder: (context, state) => ExchangeRateFormPage(
                initialCode: state.uri.queryParameters['code'],
              ),
            ),
            GoRoute(
              path: '/settings/currency/rates/:code/edit',
              builder: (context, state) => ExchangeRateFormPage(
                editingCode: state.pathParameters['code']!,
                relativeToCode: state.uri.queryParameters['to'],
              ),
            ),
            // Financial Education (016) is reached from a Settings row
            // (research.md Decision 5), so it lives in the Settings branch.
            // The fixed calculator paths are declared before the
            // `:categoryId` routes so they can never be captured as a
            // category id.
            GoRoute(
              path: '/financial-education',
              builder: (context, state) => const ContentLibraryHomePage(),
            ),
            GoRoute(
              path: '/financial-education/calculators/compound-growth',
              builder: (context, state) => const CompoundGrowthCalculatorPage(),
            ),
            GoRoute(
              path: '/financial-education/calculators/doubling-time',
              builder: (context, state) => const DoublingTimeCalculatorPage(),
            ),
            GoRoute(
              path: '/financial-education/calculators/savings-rate',
              builder: (context, state) => const SavingsRateCalculatorPage(),
            ),
            GoRoute(
              path: '/financial-education/:categoryId',
              builder: (context, state) =>
                  CategoryPage(categoryId: state.pathParameters['categoryId']!),
            ),
            GoRoute(
              path: '/financial-education/:categoryId/:articleId',
              builder: (context, state) => ArticlePage(
                categoryId: state.pathParameters['categoryId']!,
                articleId: state.pathParameters['articleId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Resolves the `?type=` query parameter used by the Add Expense and Add
/// Income entry points. Anything unrecognized (or absent) falls back to
/// expense, the far more frequent entry — a bad URL should open a usable
/// form, not fail.
FinanceEntryType _financeEntryTypeFrom(String? value) =>
    value == 'income' ? FinanceEntryType.income : FinanceEntryType.expense;
