import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/dashboard/presentation/widgets/finance_snapshot_card.dart';
import 'package:daftary/features/dashboard/presentation/widgets/insights_placeholder_card.dart';
import 'package:daftary/features/dashboard/presentation/widgets/overview_summary_card.dart';
import 'package:daftary/features/dashboard/presentation/widgets/quick_action_row.dart';
import 'package:daftary/features/dashboard/presentation/widgets/upcoming_placeholder_card.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/presentation/pages/finance_entry_form_page.dart';
import 'package:daftary/features/people/presentation/pages/person_form_page.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/get_overview.dart';
import 'package:daftary/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:daftary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 012 T025/T045 — end-to-end coverage of Home against the real app (real
/// DI, real on-device SQLite), following quickstart.md's Manual Validation
/// Scenarios 1, 2, 3, and 6.
///
/// Scenarios 4 (single-side and full failure + retry) need a faked data
/// source to fail on demand, which the real app never exposes; they are
/// covered by `test/widget/home_page_test.dart` and
/// `test/features/dashboard/presentation/cubit/dashboard_cubit_test.dart`.
///
/// The on-device database persists across runs, so every assertion here is
/// relative to what the owning use cases report right now, never to fixed
/// totals.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // `lib/main.dart`'s own `main()` is never invoked by an integration test,
  // so DI bootstrap has to happen explicitly before the first `pumpWidget`.
  setUpAll(() async => configureDependencies());

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  final formatter = EgpFormatter();

  Future<void> pumpHome(WidgetTester tester) async {
    // `appRouter` is a module-level singleton that keeps wherever the
    // previous test left it — reset explicitly so each test starts on Home.
    appRouter.go('/overview');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapQuickAction(WidgetTester tester, String location) async {
    final action = find.byKey(ValueKey(location));
    await scrollTo(tester, action);
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  testWidgets('Home shows the combined snapshot, quick actions, sections, '
      'and honest placeholders (Scenarios 1 and 3)', (tester) async {
    await pumpHome(tester);
    final l10n = await english();

    expect(find.text(l10n.homeTitle), findsWidgets);

    // A brand-new install shows the single combined empty state instead
    // of the snapshot; either way quick actions stay reachable.
    final isEmpty = find.text(l10n.homeEmptyTitle).evaluate().isNotEmpty;
    if (isEmpty) {
      expect(find.byType(OverviewSummaryCard), findsNothing);
      expect(find.byType(FinanceSnapshotCard), findsNothing);
      await scrollTo(tester, find.byType(QuickActionRow));
      return;
    }

    expect(find.text(l10n.homeFinancialSnapshotTitle), findsOneWidget);
    expect(find.byType(OverviewSummaryCard), findsOneWidget);
    expect(find.byType(FinanceSnapshotCard), findsOneWidget);

    await scrollTo(tester, find.byType(QuickActionRow));
    await scrollTo(tester, find.text(l10n.homeSectionsTitle));
    await scrollTo(tester, find.byType(InsightsPlaceholderCard));
    expect(find.text(l10n.homeInsightsPlaceholder), findsOneWidget);
    await scrollTo(tester, find.byType(UpcomingPlaceholderCard));
    expect(find.text(l10n.homeUpcomingPlaceholder), findsOneWidget);
  });

  testWidgets('each quick action opens its existing form, preset where the '
      'route supports it (Scenario 2)', (tester) async {
    await pumpHome(tester);

    await tapQuickAction(tester, QuickActionRow.addExpenseLocation);
    expect(
      tester
          .widget<FinanceEntryFormPage>(find.byType(FinanceEntryFormPage))
          .initialType,
      FinanceEntryType.expense,
    );
    await goBack(tester);

    await tapQuickAction(tester, QuickActionRow.addIncomeLocation);
    expect(
      tester
          .widget<FinanceEntryFormPage>(find.byType(FinanceEntryFormPage))
          .initialType,
      FinanceEntryType.income,
    );
    await goBack(tester);

    await tapQuickAction(tester, QuickActionRow.addPersonLocation);
    expect(find.byType(PersonFormPage), findsOneWidget);
    await goBack(tester);

    await tapQuickAction(tester, QuickActionRow.moneyReceivedLocation);
    expect(
      tester
          .widget<TransactionFormPage>(find.byType(TransactionFormPage))
          .initialDirection,
      TransactionDirection.received,
    );
    await goBack(tester);

    await tapQuickAction(tester, QuickActionRow.moneyGivenLocation);
    expect(
      tester
          .widget<TransactionFormPage>(find.byType(TransactionFormPage))
          .initialDirection,
      TransactionDirection.given,
    );
    await goBack(tester);

    // Back on Home after every round trip.
    expect(find.byType(QuickActionRow), findsOneWidget);
  });

  testWidgets('saving an expense from the quick action updates Home without '
      'a manual refresh (Scenario 2.4, FR-011)', (tester) async {
    await pumpHome(tester);
    final l10n = await english();

    await tapQuickAction(tester, QuickActionRow.addExpenseLocation);
    await tester.enterText(
      find.widgetWithText(TextField, l10n.amountLabel),
      '12.34',
    );
    await tester.pumpAndSettle();
    final chip = find.widgetWithText(ChoiceChip, 'Groceries');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final save = find.text(l10n.commonSave);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    // Home is back on screen, and its finance card already shows the
    // figure the owning use case now reports.
    final summary = (await getIt<GetFinanceSummary>()(
      DateRange.thisMonth(),
    )).getOrElse((f) => throw StateError(f.message));
    expect(find.byType(FinanceSnapshotCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FinanceSnapshotCard),
        matching: find.text(formatter.formatWithSymbol(summary.totalExpense!)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Home shows exactly what the owning use cases return '
      '(Scenario 6, FR-016)', (tester) async {
    await pumpHome(tester);
    final l10n = await english();
    if (find.text(l10n.homeEmptyTitle).evaluate().isNotEmpty) return;

    final overview = (await getIt<GetOverview>()()).getOrElse(
      (f) => throw StateError(f.message),
    );
    final finance = (await getIt<GetFinanceSummary>()(
      DateRange.thisMonth(),
    )).getOrElse((f) => throw StateError(f.message));

    Finder inCard(Type card, String text) =>
        find.descendant(of: find.byType(card), matching: find.text(text));

    expect(
      inCard(
        OverviewSummaryCard,
        formatter.formatWithSymbol(overview.totalOwedToUser!),
      ),
      findsWidgets,
    );
    expect(
      inCard(
        OverviewSummaryCard,
        formatter.formatWithSymbol(overview.totalUserOwes!),
      ),
      findsWidgets,
    );
    expect(
      inCard(
        FinanceSnapshotCard,
        formatter.formatWithSymbol(finance.totalIncome!),
      ),
      findsWidgets,
    );
    expect(
      inCard(
        FinanceSnapshotCard,
        formatter.formatWithSymbol(finance.totalExpense!),
      ),
      findsWidgets,
    );
  });
}
