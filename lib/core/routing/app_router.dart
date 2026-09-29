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
import '../../features/ai_assistant/presentation/pages/ai_settings_page.dart';
import '../../features/ai_assistant/presentation/pages/chat_page.dart';
import '../../features/app_lock/presentation/pages/security_settings_page.dart';
import '../../features/budgets/domain/entities/budget_month.dart';
import '../../features/budgets/presentation/pages/budget_form_page.dart';
import '../../features/budgets/presentation/pages/budget_month_page.dart';
import '../../features/budgets/presentation/pages/budget_trend_page.dart';
import '../../features/dashboard/presentation/pages/home_page.dart';
import '../../features/data_privacy/presentation/pages/data_export_page.dart';
import '../../features/data_privacy/presentation/pages/delete_data_confirmation_page.dart';
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
import '../../features/finance/presentation/pages/reports_page.dart';
import '../../features/occasions/presentation/pages/archived_occasions_page.dart';
import '../../features/occasions/presentation/pages/occasion_detail_page.dart';
import '../../features/occasions/presentation/pages/occasion_form_page.dart';
import '../../features/occasions/presentation/pages/occasions_list_page.dart';
import '../../features/occasions/presentation/pages/participant_form_page.dart';
import '../../features/savings/domain/entities/savings_contribution.dart';
import '../../features/savings/presentation/pages/archived_goals_page.dart';
import '../../features/savings/presentation/pages/contribution_form_page.dart';
import '../../features/savings/presentation/pages/goal_detail_page.dart';
import '../../features/savings/presentation/pages/goal_form_page.dart';
import '../../features/savings/presentation/pages/savings_overview_page.dart';
import '../../features/savings/presentation/pages/what_if_calculator_page.dart';
import '../../features/savings/presentation/savings_routes.dart';
import '../../features/ocr/presentation/pages/image_prep_page.dart';
import '../../features/ocr/presentation/pages/scan_capture_page.dart';
import '../../features/ocr/presentation/pages/scan_detail_page.dart';
import '../../features/ocr/presentation/pages/scan_history_page.dart';
import '../../features/ocr/presentation/pages/scan_review_page.dart';
import '../../features/people/presentation/pages/archived_people_page.dart';
import '../../features/people/presentation/pages/people_list_page.dart';
import '../../features/people/presentation/pages/person_edit_page.dart';
import '../../features/people/presentation/pages/person_form_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transactions/domain/entities/money_transaction.dart';
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
                initialDirection: _transactionDirectionFrom(
                  state.uri.queryParameters['direction'],
                ),
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
              path: '/finance/reports',
              builder: (context, state) => const ReportsPage(),
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
            // Occasions share the People branch for the same reason
            // finance does (research.md Decision 9): the section is reached
            // from People and the Overview rather than from a fourth
            // bottom-nav tab. The static `/occasions/...` paths are
            // declared before `/occasions/:id` so `new` and `archived` are
            // never captured as an occasion id.
            GoRoute(
              path: '/occasions',
              builder: (context, state) => const OccasionsListPage(),
            ),
            GoRoute(
              path: '/occasions/new',
              builder: (context, state) => const OccasionFormPage(),
            ),
            GoRoute(
              path: '/occasions/archived',
              builder: (context, state) => const ArchivedOccasionsPage(),
            ),
            GoRoute(
              path: '/occasions/:id/edit',
              builder: (context, state) => OccasionFormPage(
                editingOccasionId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: '/occasions/:id/participants/new',
              builder: (context, state) =>
                  ParticipantFormPage(occasionId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/occasions/:id/participants/:transactionId/edit',
              builder: (context, state) => ParticipantFormPage(
                occasionId: state.pathParameters['id']!,
                editingTransactionId: state.pathParameters['transactionId']!,
              ),
            ),
            GoRoute(
              path: '/occasions/:id',
              builder: (context, state) =>
                  OccasionDetailPage(occasionId: state.pathParameters['id']!),
            ),
            // Budgets live in the People branch for the same reason finance
            // does (research.md Decision 9): reached from the Overview, not
            // from a bottom-nav tab of their own. Static `/budgets/...`
            // paths (e.g. US5's `/budgets/trend`) MUST be declared above
            // `/budgets/:month` so a literal segment is never captured as a
            // month.
            GoRoute(
              path: '/budgets',
              redirect: (context, state) => '/budgets/${BudgetMonth.current()}',
            ),
            // `?month=YYYY-MM` anchors the trend window's last month to
            // the month page it was opened from; absent, it ends today.
            GoRoute(
              path: '/budgets/trend',
              builder: (context, state) {
                final month = state.uri.queryParameters['month'];
                return BudgetTrendPage(
                  endMonth: month != null && BudgetMonth.isValid(month)
                      ? month
                      : null,
                );
              },
            ),
            GoRoute(
              path: '/budgets/:month',
              builder: (context, state) => BudgetMonthPage(
                month: _budgetMonthFrom(state.pathParameters['month']),
              ),
            ),
            // `new` and `edit` open the same form: it switches itself into
            // edit mode when the month already has a budget, so neither
            // path can ever produce a second budget for one month.
            GoRoute(
              path: '/budgets/:month/new',
              builder: (context, state) => BudgetFormPage(
                month: _budgetMonthFrom(state.pathParameters['month']),
              ),
            ),
            GoRoute(
              path: '/budgets/:month/edit',
              builder: (context, state) => BudgetFormPage(
                month: _budgetMonthFrom(state.pathParameters['month']),
              ),
            ),
            // Savings goals (011) live in the People branch for the same
            // reason occasions and budgets do (research.md Decision 12):
            // reached from Home, not from a bottom-nav tab of their own.
            // Static `/savings/...` paths (`new`, `archived`) MUST be
            // declared above `/savings/:goalId` so a literal segment is
            // never captured as a goal id. `/savings/:goalId` is also 017's
            // notification deep-link target (`savingsGoalPath`).
            GoRoute(
              path: SavingsRoutes.overview,
              builder: (context, state) => const SavingsOverviewPage(),
            ),
            GoRoute(
              path: SavingsRoutes.archived,
              builder: (context, state) => const ArchivedGoalsPage(),
            ),
            GoRoute(
              path: SavingsRoutes.newGoal,
              builder: (context, state) => const GoalFormPage(),
            ),
            GoRoute(
              path: '/savings/:goalId/edit',
              builder: (context, state) =>
                  GoalFormPage(editingGoalId: state.pathParameters['goalId']!),
            ),
            // One form for logging and correcting entries:
            // `?type=withdrawal` opens it on a withdrawal, `?entry=<id>`
            // edits that entry.
            GoRoute(
              path: '/savings/:goalId/log',
              builder: (context, state) {
                final query = state.uri.queryParameters;
                return ContributionFormPage(
                  goalId: state.pathParameters['goalId']!,
                  type: query['type'] == SavingsRoutes.withdrawalType
                      ? ContributionType.withdrawal
                      : ContributionType.contribution,
                  editingContributionId: query['entry'],
                );
              },
            ),
            GoRoute(
              path: '/savings/:goalId/what-if',
              builder: (context, state) =>
                  WhatIfCalculatorPage(goalId: state.pathParameters['goalId']!),
            ),
            GoRoute(
              path: '/savings/:goalId',
              builder: (context, state) =>
                  GoalDetailPage(goalId: state.pathParameters['goalId']!),
            ),
            // The scan flow lives in the People branch for the same reason
            // finance and occasions do (research.md Decision 9): it is
            // reached from the quick actions and from People, not from a
            // bottom-nav tab of its own. As with occasions, the static
            // `/ocr/...` paths are declared before `/ocr/history/:scanId`
            // so no literal segment is ever captured as a scan id.
            GoRoute(
              path: '/ocr/scan',
              builder: (context, state) => const ScanCapturePage(),
            ),
            GoRoute(
              path: '/ocr/scan/prepare',
              // The capture step hands the picked image's path along as
              // `extra` rather than in the URL: it is a private sandbox
              // path, which has no business being in a shareable location.
              builder: (context, state) =>
                  ImagePrepPage(imagePath: state.extra! as String),
            ),
            GoRoute(
              path: '/ocr/scan/review',
              builder: (context, state) =>
                  ScanReviewPage(scanId: state.uri.queryParameters['scanId']!),
            ),
            GoRoute(
              path: '/ocr/history',
              builder: (context, state) => const ScanHistoryPage(),
            ),
            GoRoute(
              path: '/ocr/history/:scanId',
              builder: (context, state) =>
                  ScanDetailPage(scanId: state.pathParameters['scanId']!),
            ),
            // The AI assistant (014) lives in the People branch for the same
            // reason finance, occasions and budgets do (research.md
            // Decision 9): it is reached from Home's section entry points,
            // not from a bottom-nav tab of its own. Home opens the chat,
            // which shows its disabled state (linking to settings) until
            // the assistant is set up (FR-001).
            GoRoute(
              path: ChatPage.location,
              builder: (context, state) => const ChatPage(),
            ),
            GoRoute(
              path: AISettingsPage.location,
              builder: (context, state) => const AISettingsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _overviewBranchNavigatorKey,
          routes: [
            GoRoute(
              path: '/overview',
              builder: (context, state) => const HomePage(),
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
            GoRoute(
              path: '/settings/export',
              builder: (context, state) => const DataExportPage(),
            ),
            // The AI assistant's setup, also reachable from Settings so it
            // is found where people look for it; the same page as the
            // People-branch route the chat links to (014).
            GoRoute(
              path: '/settings/ai-assistant',
              builder: (context, state) => const AISettingsPage(),
            ),
            // 015 User Story 6. Only the settings screen is a route: the
            // lock screen and PIN setup are overlays/pushed pages, never
            // deep-linkable (research.md Decision 5).
            GoRoute(
              path: '/settings/security',
              builder: (context, state) => const SecuritySettingsPage(),
            ),
            GoRoute(
              path: '/settings/delete-data',
              builder: (context, state) => const DeleteDataConfirmationPage(),
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

/// Resolves a `direction` query parameter (e.g. from a Home quick action,
/// 012) to a preset [TransactionDirection]. Anything unrecognized yields
/// `null`, leaving the form on its own default.
TransactionDirection? _transactionDirectionFrom(String? value) =>
    switch (value) {
      'given' => TransactionDirection.given,
      'received' => TransactionDirection.received,
      _ => null,
    };

/// Resolves a `:month` path segment to a `'YYYY-MM'` budget month. A
/// malformed segment falls back to the current month — a bad URL should
/// open a usable budget screen, not throw inside a month parser.
String _budgetMonthFrom(String? value) =>
    value != null && BudgetMonth.isValid(value) ? value : BudgetMonth.current();
