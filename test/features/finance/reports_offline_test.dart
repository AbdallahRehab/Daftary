import 'dart:io';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/get_spending_trend.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_daos.dart';
import '../transactions/helpers/currency_test_doubles.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/core/money/money.dart';

/// Any attempt to open an HTTP connection fails the test outright.
class _NoNetworkHttpOverrides extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Reports must never touch the network (FR-022)');
  }
}

/// 013 T050 (Reports part) / FR-022 — Reports works with no connectivity.
///
/// Two complementary checks: the Reports code path imports no networking
/// library at all, and running it end to end over a real database never
/// creates an HTTP client.
void main() {
  // Every file the Reports screen's own logic lives in.
  const reportsSources = [
    'lib/features/finance/domain/entities/spending_trend_point.dart',
    'lib/features/finance/domain/usecases/get_spending_trend.dart',
    'lib/features/finance/presentation/cubit/reports_cubit.dart',
    'lib/features/finance/presentation/cubit/reports_state.dart',
    'lib/features/finance/presentation/pages/reports_page.dart',
    'lib/features/finance/presentation/widgets/monthly_trend_chart.dart',
    'lib/features/finance/presentation/widgets/category_breakdown_chart.dart',
    // The 007 read path Reports composes.
    'lib/features/finance/domain/usecases/get_category_breakdown.dart',
    'lib/features/finance/domain/repositories/finance_repository.dart',
    'lib/features/finance/data/repositories/finance_repository_impl.dart',
    'lib/features/finance/data/datasources/finance_dao.dart',
  ];

  final networkImport = RegExp(
    r'''import\s+['"](dart:io|package:http/|package:dio/|'''
    r'''package:web_socket|package:grpc/|package:connectivity)''',
  );

  test('no Reports source imports a networking library', () {
    for (final path in reportsSources) {
      final source = File(path).readAsStringSync();
      expect(
        networkImport.hasMatch(source),
        isFalse,
        reason: '$path imports a networking library',
      );
    }
  });

  test('loading Reports and switching every period never opens an HTTP '
      'connection', () async {
    final overrides = _NoNetworkHttpOverrides();
    await HttpOverrides.runWithHttpOverrides(() async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = FinanceRepositoryImpl(testFinanceDao(db));
      await repository.addEntry(
        idempotencyKey: 'offline-1',
        categoryId: 'seed_groceries',
        type: FinanceEntryType.expense,
        amount: Money.egp(4575),
        date: DateTime.now(),
      );

      final cubit = ReportsCubit(
        GetSpendingTrend(
          GetFinanceSummary(
            repository,
            getConversionContextWith(),
            const CurrencyConverterImpl(),
          ),
        ),
        GetCategoryBreakdown(
          repository,
          getConversionContextWith(),
          const CurrencyConverterImpl(),
        ),
        repository,
      );
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.status, ReportsStatus.success);
      for (final period in ReportsPeriod.values) {
        await cubit.changeBreakdownPeriod(period);
        expect(cubit.state.breakdownStatus, ReportsBreakdownStatus.success);
      }
    }, overrides);

    expect(overrides.attempts, 0);
  });
}
