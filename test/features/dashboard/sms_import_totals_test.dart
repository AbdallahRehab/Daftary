import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/watch_conversion_context.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:daftary/features/dashboard/presentation/cubit/load_status.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/watch_finance_history.dart';
import 'package:daftary/features/finance/domain/usecases/watch_finance_summary.dart';
import 'package:daftary/features/savings/data/repositories/savings_repository_impl.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:daftary/features/savings/domain/usecases/watch_upcoming_savings_goals.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/usecases/ignore_import.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_overview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/test_daos.dart';
import '../sms_import/helpers/pipeline_harness.dart';

// Synthetic messages (generic and NBE profile phrasing; invented names,
// no real card numbers, phone numbers or references).
const _purchase =
    'NBE: Your card ending 4821 was charged EGP 250.00 at Example Market on '
    '05/03/2026 at 14:30. Available balance EGP 3,200.00';
const _purchaseWithFee =
    'Purchase of EGP 300.00 at Example Online Store. Foreign transaction fee '
    'EGP 7.50';
const _salary =
    'NBE: Salary of EGP 15,000.00 has been credited to your account ****4821 '
    'on 01/03/2026.';
const _transferOut =
    'NBE: Transfer of EGP 1,500.00 to Ahmed Example from your account '
    '****4821 on 05/03/2026. Ref 7731902';
const _transferIn =
    'NBE: Your account ****4821 was credited with EGP 3,000.00 from Mona '
    'Example on 05/03/2026.';
const _reversal =
    'Authorization reversed: the hold of EGP 450.00 at Example Hotel has been '
    'released.';
const _ownTransfer =
    'EGP 1,000.00 transferred between your accounts on 06/03/2026';

/// T169 — financial totals after SMS Adds (022 calculation rules, FR-052,
/// FR-024b): one item of each kind is added through
/// `AddImportedTransaction` over the real pipeline, and Home's
/// `DashboardCubit` (real repositories, the same database) shows:
/// - income = the salary only; expense = the purchase + the split
///   purchase + its fee, the fee counted exactly once;
/// - given / received only move the people totals, never income or
///   expense;
/// - an Ignored reversal and an Ignored own-account transfer change
///   nothing.
/// Every value is synthetic. Dates are "today" so the items fall in
/// Home's "this month".
void main() {
  late PipelineHarness h;
  late DateTime today;

  setUp(() async {
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    h = PipelineHarness(now: now);
    await h.open();
    for (final (id, name) in [
      ('person-ahmed', 'Ahmed Example'),
      ('person-mona', 'Mona Example'),
    ]) {
      await h.database
          .into(h.database.people)
          .insert(
            db.PeopleCompanion.insert(
              id: id,
              name: name,
              normalizedName: name.toLowerCase(),
              createdAt: 1,
              updatedAt: 1,
            ),
          );
    }
  });
  tearDown(() => h.close());

  DashboardCubit homeCubit() {
    final currency = CurrencyRepositoryImpl(
      testCurrencyDao(h.database),
      const SystemAppClock(),
    );
    final finance = FinanceRepositoryImpl(testFinanceDao(h.database));
    final transactions = TransactionsRepositoryImpl(
      testTransactionsDao(h.database),
      h.database,
      getConversionContext: GetConversionContext(currency),
    );
    final summary = GetFinanceSummary(
      finance,
      GetConversionContext(currency),
      const CurrencyConverterImpl(),
    );
    return DashboardCubit(
      WatchOverview(transactions),
      WatchFinanceSummary(finance, WatchConversionContext(currency), summary),
      WatchFinanceHistory(finance),
      WatchUpcomingSavingsGoals(
        SavingsRepositoryImpl(
          testSavingsDao(h.database),
          h.database,
          GetConversionContext(currency),
          const CurrencyConverterImpl(),
          const DefaultSavingsCalculator(),
          const SystemAppClock(),
        ),
      ),
    );
  }

  /// Home's state once both aggregates have loaded.
  Future<DashboardState> home() async {
    final cubit = homeCubit();
    addTearDown(cubit.close);
    final ready = cubit.stream.firstWhere(
      (s) =>
          s.overviewStatus != LoadStatus.loading &&
          s.financeStatus != LoadStatus.loading,
    );
    await cubit.load();
    final state = await ready;
    expect(state.overviewStatus, LoadStatus.success);
    expect(state.financeStatus, LoadStatus.success);
    return state;
  }

  Future<List<PendingSmsImport>> pasteAll(String text) async {
    final result = await h.pasteText(text);
    expect(result.newIds, isNotEmpty, reason: 'recognized');
    return [for (final id in result.newIds) await h.item(id)];
  }

  /// The explicit Add of ONE reviewed item with the user's chosen type.
  Future<void> addAs(
    PendingSmsImport item,
    SuggestedRecordType type, {
    String? categoryId,
    String? personId,
  }) async {
    final result = await h.add(
      pendingId: item.id,
      draft: ReviewDraft(
        type: type,
        amountMinorUnits: item.amount!.minorUnits,
        currencyCode: item.amount!.currency.code,
        date: today,
        categoryId: type.isFinanceEntry
            ? categoryId ?? item.suggestedCategoryId
            : null,
        personId: type.isPersonTransaction ? personId : null,
      ),
    );
    expect(
      result.isRight(),
      isTrue,
      reason: 'add ${item.kind.name} failed: ${result.getLeft()}',
    );
  }

  Money egp(int minor) => Money.egp(minor);

  test('an empty Home before any Add', () async {
    final state = await home();
    expect(state.financeSummary!.totalIncome, egp(0));
    expect(state.financeSummary!.totalExpense, egp(0));
    expect(state.overviewSummary!.totalOwedToUser, egp(0));
    expect(state.overviewSummary!.totalUserOwes, egp(0));
  });

  test('one Add of each kind: income, expense and people totals follow the '
      '022 rules', () async {
    final purchase = (await pasteAll(_purchase)).single;
    final split = await pasteAll(_purchaseWithFee);
    expect(split, hasLength(2), reason: 'the purchase and its fee');
    final parent = split.firstWhere((i) => i.kind != SmsKind.fee);
    final fee = split.firstWhere((i) => i.kind == SmsKind.fee);
    expect(fee.parentImportId, parent.id);
    final salary = (await pasteAll(_salary)).single;
    final transferOut = (await pasteAll(_transferOut)).single;
    final transferIn = (await pasteAll(_transferIn)).single;

    await addAs(purchase, SuggestedRecordType.expense);
    await addAs(parent, SuggestedRecordType.expense);
    await addAs(fee, SuggestedRecordType.expense);
    await addAs(salary, SuggestedRecordType.income);
    // The one-tap switch to a people-ledger type (FR-051a).
    await addAs(
      transferOut,
      SuggestedRecordType.given,
      personId: 'person-ahmed',
    );
    await addAs(
      transferIn,
      SuggestedRecordType.received,
      personId: 'person-mona',
    );

    // Each Add made exactly one record: 4 entries + 2 transactions.
    expect(
      await h.database.select(h.database.financeEntries).get(),
      hasLength(4),
    );
    expect(
      await h.database.select(h.database.moneyTransactions).get(),
      hasLength(2),
    );

    final state = await home();
    final finance = state.financeSummary!;
    final overview = state.overviewSummary!;

    // Income: the salary only (received never counts as income).
    expect(finance.totalIncome, egp(1500000));
    // Expense: 250.00 + 300.00 + the 7.50 fee once (given never counts).
    expect(finance.totalExpense, egp(25000 + 30000 + 750));
    expect(finance.net, egp(1500000 - 55750));
    // People: given -> they owe you; received -> you owe them.
    expect(overview.totalOwedToUser, egp(150000));
    expect(overview.totalUserOwes, egp(300000));
    expect(overview.peopleTheyOweYou.single.personId, 'person-ahmed');
    expect(overview.peopleYouOweThem.single.personId, 'person-mona');
    expect(state.isCombinedEmpty, isFalse);
  });

  test('an Ignored reversal and an Ignored own-account transfer change no '
      'total and create no record', () async {
    final purchase = (await pasteAll(_purchase)).single;
    await addAs(purchase, SuggestedRecordType.expense);
    final before = await home();
    final records = await h.savedRecords();

    final reversal = (await pasteAll(_reversal)).single;
    final own = (await pasteAll(_ownTransfer)).single;
    expect(reversal.kind, SmsKind.authorizationReversal);
    expect(own.kind, SmsKind.ownAccountTransfer);
    expect(reversal.suggestedType, SuggestedRecordType.ignore);
    expect(own.suggestedType, SuggestedRecordType.ignore);

    expect(
      await IgnoreImport(h.repository)(ids: {reversal.id, own.id}),
      const Right<Failure, Unit>(unit),
    );

    final after = await home();
    expect(await h.savedRecords(), records);
    expect(after.financeSummary, before.financeSummary);
    expect(after.overviewSummary, before.overviewSummary);
    expect(after.financeSummary!.totalExpense, egp(25000));
    expect(after.financeSummary!.totalIncome, egp(0));
  });
}
