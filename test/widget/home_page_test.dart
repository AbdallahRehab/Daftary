import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:daftary/features/dashboard/presentation/cubit/load_status.dart';
import 'package:daftary/features/dashboard/presentation/pages/home_page.dart';
import 'package:daftary/features/dashboard/presentation/widgets/finance_snapshot_card.dart';
import 'package:daftary/features/dashboard/presentation/widgets/insights_placeholder_card.dart';
import 'package:daftary/features/dashboard/presentation/widgets/overview_summary_card.dart';
import 'package:daftary/features/dashboard/presentation/widgets/quick_action_row.dart';
import 'package:daftary/features/dashboard/presentation/widgets/snapshot_error_card.dart';
import 'package:daftary/features/dashboard/presentation/widgets/upcoming_placeholder_card.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

/// T012, T038, T039, T044 — Home's rendering for every state the
/// `DashboardCubit` can be in.
void main() {
  late MockDashboardCubit cubit;
  late AppLocalizations en;

  final overview = OverviewSummary(
    totalOwedToUser: const Money.egp(150000),
    totalUserOwes: const Money.egp(20000),
    peopleTheyOweYou: const [
      PersonSummary(
        personId: 'p1',
        name: 'Mona',
        net: Money.egp(150000),
        isArchived: false,
      ),
    ],
    peopleYouOweThem: const [
      PersonSummary(
        personId: 'p2',
        name: 'Karim',
        net: Money.egp(-20000),
        isArchived: true,
      ),
    ],
    settledCount: 0,
  );
  final settled = OverviewSummary(
    totalOwedToUser: const Money.egp(0),
    totalUserOwes: const Money.egp(0),
    peopleTheyOweYou: const [],
    peopleYouOweThem: const [],
    settledCount: 2,
  );
  final finance = FinanceSummary(
    totalIncome: const Money.egp(500000),
    totalExpense: const Money.egp(125050),
    period: DateRange(start: DateTime(2026, 9), end: DateTime(2026, 9, 30)),
  );

  final success = DashboardState(
    overviewStatus: LoadStatus.success,
    overviewSummary: overview,
    financeStatus: LoadStatus.success,
    financeSummary: finance,
  );

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    cubit = MockDashboardCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.refresh()).thenAnswer((_) async {});
    when(() => cubit.retryOverview()).thenAnswer((_) async {});
    when(() => cubit.retryFinance()).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester,
    DashboardState state, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
    Size size = const Size(800, 3200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DashboardCubit>.value(
          value: cubit,
          child: const HomeView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double topOf(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  group('success (T012)', () {
    testWidgets('renders balances and this-month finance together inside '
        'one Financial snapshot section, above the rest of Home', (
      tester,
    ) async {
      await pump(tester, success);

      expect(find.text(en.homeTitle), findsOneWidget);
      expect(find.text(en.homeFinancialSnapshotTitle), findsOneWidget);
      expect(find.byType(OverviewSummaryCard), findsOneWidget);
      expect(find.byType(FinanceSnapshotCard), findsOneWidget);
      expect(find.byType(SnapshotErrorCard), findsNothing);

      // Progressive-disclosure order: snapshot → quick actions → sections →
      // per-person lists → Insights → Upcoming.
      final order = [
        find.text(en.homeFinancialSnapshotTitle),
        find.byType(OverviewSummaryCard),
        find.byType(FinanceSnapshotCard),
        find.text(en.homeQuickActionsTitle),
        find.byType(QuickActionRow),
        find.text(en.homeSectionsTitle),
        find.widgetWithText(ListTile, en.budgetsTitle),
        find.widgetWithText(ListTile, en.occasionsTitle),
        find.widgetWithText(ListTile, en.ocrCaptureTitle),
        find.text(en.overviewSectionTheyOweYou),
        find.text('Mona'),
        find.text(en.overviewSectionYouOweThem),
        find.text('Karim'),
        find.byType(InsightsPlaceholderCard),
        find.byType(UpcomingPlaceholderCard),
      ];
      for (var i = 1; i < order.length; i++) {
        expect(
          topOf(tester, order[i]),
          greaterThanOrEqualTo(topOf(tester, order[i - 1])),
          reason: 'item $i is out of order',
        );
      }
      // The two snapshot cards sit directly together (US1 AC2).
      expect(
        topOf(tester, find.byType(FinanceSnapshotCard)) -
            tester.getBottomLeft(find.byType(OverviewSummaryCard)).dy,
        lessThanOrEqualTo(AppSpacing.md),
      );

      expect(find.text(en.homeEmptyTitle), findsNothing);
      expect(find.text(en.overviewAllSettledTitle), findsNothing);
      expect(find.byTooltip(en.ocrHistoryTitle), findsOneWidget);
    });

    testWidgets('pull-to-refresh calls refresh()', (tester) async {
      await pump(tester, success);
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      verify(() => cubit.refresh()).called(1);
    });

    testWidgets('all settled shows a compact note inside the snapshot, '
        'not in place of it', (tester) async {
      await pump(tester, success.copyWith(overviewSummary: settled));

      expect(find.byType(OverviewSummaryCard), findsOneWidget);
      expect(find.byType(FinanceSnapshotCard), findsOneWidget);
      expect(find.text(en.overviewAllSettledTitle), findsOneWidget);
      expect(find.text(en.overviewSectionTheyOweYou), findsNothing);
      expect(
        topOf(tester, find.text(en.overviewAllSettledTitle)),
        lessThan(topOf(tester, find.text(en.homeQuickActionsTitle))),
      );
    });

    testWidgets('full loading shows only a spinner', (tester) async {
      when(() => cubit.state).thenReturn(const DashboardState());
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<DashboardCubit>.value(
            value: cubit,
            child: const HomeView(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(OverviewSummaryCard), findsNothing);
    });
  });

  group('combined empty state (T012, FR-005)', () {
    testWidgets('renders a single welcome state with a get-started action '
        'and keeps quick actions reachable', (tester) async {
      await pump(
        tester,
        DashboardState(
          overviewStatus: LoadStatus.success,
          overviewSummary: settled.copyWithZeroPeople(),
          financeStatus: LoadStatus.success,
          financeSummary: FinanceSummary.empty(finance.period),
          isCombinedEmpty: true,
        ),
      );

      expect(find.text(en.homeEmptyTitle), findsOneWidget);
      expect(find.text(en.homeEmptyMessage), findsOneWidget);
      expect(find.text(en.homeEmptyAction), findsOneWidget);
      expect(find.byType(QuickActionRow), findsOneWidget);
      // One combined state — never the snapshot cards next to it.
      expect(find.byType(OverviewSummaryCard), findsNothing);
      expect(find.byType(FinanceSnapshotCard), findsNothing);
      expect(find.text(en.overviewAllSettledTitle), findsNothing);
    });

    testWidgets('is not shown when only one side is empty', (tester) async {
      await pump(
        tester,
        success.copyWith(financeSummary: FinanceSummary.empty(finance.period)),
      );
      expect(find.text(en.homeEmptyTitle), findsNothing);
      expect(find.byType(FinanceSnapshotCard), findsOneWidget);
    });
  });

  group('partial failure (T038, FR-003)', () {
    testWidgets('finance failed: balances render, finance shows inline '
        'error, retry calls only retryFinance()', (tester) async {
      await pump(
        tester,
        DashboardState(
          overviewStatus: LoadStatus.success,
          overviewSummary: overview,
          financeStatus: LoadStatus.failure,
          financeError: 'db',
        ),
      );

      expect(find.byType(OverviewSummaryCard), findsOneWidget);
      expect(find.byType(FinanceSnapshotCard), findsNothing);
      expect(find.text(en.homeFinanceLoadError), findsOneWidget);
      expect(find.byType(QuickActionRow), findsOneWidget);
      expect(find.byType(InsightsPlaceholderCard), findsOneWidget);
      expect(find.byType(UpcomingPlaceholderCard), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(SnapshotErrorCard),
          matching: find.text(en.commonRetry),
        ),
      );
      verify(() => cubit.retryFinance()).called(1);
      verifyNever(() => cubit.retryOverview());
      verifyNever(() => cubit.load());
    });

    testWidgets('balances failed: finance renders, balances show inline '
        'error, retry calls only retryOverview()', (tester) async {
      await pump(
        tester,
        DashboardState(
          overviewStatus: LoadStatus.failure,
          overviewError: 'db',
          financeStatus: LoadStatus.success,
          financeSummary: finance,
        ),
      );

      expect(find.byType(OverviewSummaryCard), findsNothing);
      expect(find.byType(FinanceSnapshotCard), findsOneWidget);
      expect(find.text(en.homeOverviewLoadError), findsOneWidget);
      expect(find.byType(QuickActionRow), findsOneWidget);
      expect(find.byType(InsightsPlaceholderCard), findsOneWidget);
      expect(find.byType(UpcomingPlaceholderCard), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(SnapshotErrorCard),
          matching: find.text(en.commonRetry),
        ),
      );
      verify(() => cubit.retryOverview()).called(1);
      verifyNever(() => cubit.retryFinance());
      verifyNever(() => cubit.load());
    });
  });

  group('full failure (T039, FR-004)', () {
    testWidgets('one full-screen error whose single retry calls load()', (
      tester,
    ) async {
      await pump(
        tester,
        const DashboardState(
          overviewStatus: LoadStatus.failure,
          overviewError: 'a',
          financeStatus: LoadStatus.failure,
          financeError: 'b',
        ),
      );

      expect(find.text(en.homeFullErrorMessage), findsOneWidget);
      expect(find.byType(SnapshotErrorCard), findsNothing);
      expect(find.text(en.commonRetry), findsOneWidget);

      await tester.tap(find.text(en.commonRetry));
      verify(() => cubit.load()).called(1);
      verifyNever(() => cubit.retryOverview());
      verifyNever(() => cubit.retryFinance());
    });
  });

  group('Arabic RTL and themes (T044)', () {
    for (final theme in {
      'light': buildLightTheme(),
      'dark': buildDarkTheme(),
    }.entries) {
      testWidgets('Arabic + ${theme.key}: lays out RTL at phone width with '
          'no overflow', (tester) async {
        final ar = await AppLocalizations.delegate.load(const Locale('ar'));
        await pump(
          tester,
          success,
          locale: const Locale('ar'),
          theme: theme.value,
          size: const Size(360, 3200),
        );

        expect(tester.takeException(), isNull);
        expect(find.text(ar.homeTitle), findsOneWidget);
        expect(find.text(ar.homeFinancialSnapshotTitle), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byType(HomeView))),
          TextDirection.rtl,
        );
        // Section headers start from the right edge under RTL.
        final header = find.text(ar.homeQuickActionsTitle);
        expect(
          tester.getTopRight(header).dx,
          greaterThan(360 - AppSpacing.md - 1),
        );
        expect(find.byType(OverviewSummaryCard), findsOneWidget);
        expect(find.byType(FinanceSnapshotCard), findsOneWidget);
      });

      testWidgets('English + ${theme.key}: partial error renders without '
          'overflow at phone width', (tester) async {
        await pump(
          tester,
          DashboardState(
            overviewStatus: LoadStatus.failure,
            overviewError: 'x',
            financeStatus: LoadStatus.success,
            financeSummary: finance,
          ),
          theme: theme.value,
          size: const Size(360, 3200),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(SnapshotErrorCard), findsOneWidget);
      });
    }
  });
}

extension on OverviewSummary {
  /// Zero people at all — the "brand-new install" shape.
  OverviewSummary copyWithZeroPeople() => OverviewSummary(
    totalOwedToUser: totalOwedToUser,
    totalUserOwes: totalUserOwes,
    peopleTheyOweYou: const [],
    peopleYouOweThem: const [],
    settledCount: 0,
  );
}
