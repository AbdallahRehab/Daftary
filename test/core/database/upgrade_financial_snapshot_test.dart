import 'dart:convert';
import 'dart:io';

import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_summary.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../helpers/catalogue_fixtures.dart';

/// 022 Phase 2 (T012) — upgrade-safety snapshot.
///
/// `fixtures/financial_world_v11.sql` is a committed, real schema-v11
/// database (every table, index and trigger, every row, `user_version` 11)
/// holding the T003 world. The test loads it into SQLite, opens it through
/// `AppDatabase` so the real `onUpgrade(11 -> current)` path runs, captures
/// every person balance, overview total, budget actual and savings figure,
/// and compares with the committed `fixtures/financial_snapshot_v11.json`.
/// A second test checks a freshly seeded database yields the same JSON.
///
/// Once a v12 migration exists this proves it did not move a single figure,
/// WITHOUT regenerating anything. To regenerate both files deliberately (only
/// when a financial figure is meant to change, and only while the schema is
/// still v11): `TZ=UTC UPDATE_FINANCIAL_SNAPSHOT=1 fvm flutter test
/// test/core/database/upgrade_financial_snapshot_test.dart`.
///
/// Dates are stored as instants of local midnight, so the dump is generated
/// under TZ=UTC (midnight UTC); it then reads identically in UTC and in any
/// zone at or east of UTC. A zone west of UTC would shift stored dates to the
/// previous local day and fail the month ranges.
void main() {
  final jsonFile = File(
    'test/core/database/fixtures/financial_snapshot_v11.json',
  );
  final sqlFile = File('test/core/database/fixtures/financial_world_v11.sql');

  Map<String, Object?> money(Money? m) => m == null
      ? {'blocked': true}
      : {'minor': m.minorUnits, 'currency': m.currency.code};

  Future<Map<String, Object?>> capture(CatalogueEnv env) async {
    final people = <String, Object?>{};
    final personRows = await env.db.select(env.db.people).get();
    final ids = [for (final p in personRows) p.id]..sort();
    for (final id in ids) {
      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance(id),
      );
      people[id] = {
        'net': money(balance.net),
        'status': balance.status?.name,
        'missingRatesFor': [for (final c in balance.missingRatesFor) c.code],
        'nativeNets': [for (final m in balance.nativeNets) money(m)],
        'archived': personRows.singleWhere((p) => p.id == id).isArchived,
      };
    }

    final overview = unwrapOrThrow(await env.transactions.getOverview());
    List<String> idsOf(List<PersonSummary> list) =>
        [for (final p in list) p.personId]..sort();

    final october = DateRange(
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 31),
    );
    final november = DateRange(
      start: DateTime(2026, 11, 1),
      end: DateTime(2026, 11, 30),
    );
    Map<String, Object?> financeOf(FinanceSummary s) => {
      'income': money(s.totalIncome),
      'expense': money(s.totalExpense),
      'net': money(s.net),
    };

    final budget = unwrapOrThrow(
      await env.budgets.getBudgetForMonth('2026-10'),
    ).summary!;

    final occasionList = unwrapOrThrow(await env.occasions.getOccasionsList());
    final occasions = <String, Object?>{};
    for (final occasion in occasionList) {
      final OccasionSummary summary = unwrapOrThrow(
        await env.occasions.getOccasionDetail(occasion.id),
      ).summary;
      occasions[occasion.name] = {
        'received': money(summary.totalReceived),
        'given': money(summary.totalGiven),
        'participants': summary.participantCount,
      };
    }

    final savings = unwrapOrThrow(await env.savings.getSavingsOverview());
    final goals = <String, Object?>{};
    for (final line in savings.goals) {
      final progress = line.progress;
      final estimate = progress.estimatedCompletion;
      goals[line.goal.name] = {
        'current': progress.currentAmountMinorUnits,
        'remaining': progress.remainingMinorUnits,
        'target': progress.targetAmountMinorUnits,
        'achieved': progress.isAchieved,
        'primaryCurrencyAmount': line.primaryCurrencyAmountMinorUnits,
        'estimatedMonths': estimate?.estimatedMonths,
        'estimatedDate': estimate?.estimatedDate?.toIso8601String(),
        'requiredMonthly': estimate?.requiredMonthlyContributionMinorUnits,
        'shortfallMonths': estimate?.shortfallMonths,
      };
    }

    return {
      'people': people,
      'overview': {
        'totalOwedToUser': money(overview.totalOwedToUser),
        'totalUserOwes': money(overview.totalUserOwes),
        'theyOweYou': idsOf(overview.peopleTheyOweYou),
        'youOweThem': idsOf(overview.peopleYouOweThem),
        'rateNeeded': idsOf(overview.peopleRateNeeded),
        'settledCount': overview.settledCount,
      },
      'finance': {
        '2026-10': financeOf(unwrapOrThrow(await env.financeSummary(october))),
        '2026-11': financeOf(unwrapOrThrow(await env.financeSummary(november))),
      },
      'budget_2026_10': {
        'lines': {
          for (final line in budget.categoryBreakdown)
            line.categoryId: {
              'planned': line.plannedAmountMinorUnits,
              'actual': line.actualAmountMinorUnits,
              'remaining': line.remainingMinorUnits,
              'status': line.status?.name,
            },
        },
        'totalPlanned': budget.totalPlannedMinorUnits,
        'totalActual': budget.totalActualMinorUnits,
        'totalUnbudgeted': budget.totalUnbudgetedMinorUnits,
        'unbudgeted': {
          for (final item in budget.unbudgetedSpending)
            item.categoryId: item.amountMinorUnits,
        },
      },
      'occasions': occasions,
      'savings': {'totalSaved': savings.totalSavedMinorUnits, 'goals': goals},
    };
  }

  String pretty(Map<String, Object?> data) =>
      '${const JsonEncoder.withIndent('  ').convert(data)}\n';

  /// Plain-SQL dump of [raw]: CREATE statements for tables first, then one
  /// INSERT per row, then indexes and triggers, then the user_version.
  String dump(Database raw) {
    final out = StringBuffer();
    final master = raw.select(
      "SELECT type, name, sql FROM sqlite_master "
      "WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' ORDER BY rowid",
    );
    final tables = [
      for (final r in master)
        if (r['type'] == 'table') r['name'] as String,
    ];
    for (final r in master) {
      if (r['type'] == 'table') out.writeln('${r['sql']};');
    }
    for (final table in tables) {
      final columns = [
        for (final c in raw.select('PRAGMA table_info("$table")'))
          c['name'] as String,
      ];
      final quoted = columns.map((c) => 'quote("$c")').join(", ");
      final names = columns.map((c) => '"$c"').join(', ');
      for (final row in raw.select(
        'SELECT $quoted FROM "$table" ORDER BY rowid',
      )) {
        out.writeln(
          'INSERT INTO "$table" ($names) VALUES (${row.values.join(', ')});',
        );
      }
    }
    for (final r in master) {
      if (r['type'] != 'table') out.writeln('${r['sql']};');
    }
    out.writeln('PRAGMA user_version = 11;');
    return out.toString();
  }

  test(
    'regenerate fixtures (UPDATE_FINANCIAL_SNAPSHOT=1 only)',
    () async {
      final raw = sqlite3.openInMemory();
      addTearDown(raw.close);
      final env = await CatalogueEnv.open(
        database: AppDatabase.forTesting(
          NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
        ),
      );
      addTearDown(env.close);
      expect(env.db.schemaVersion, 11, reason: 'dump is the v11 baseline');
      await env.seedSnapshotWorld();
      jsonFile.createSync(recursive: true);
      jsonFile.writeAsStringSync(pretty(await capture(env)));
      sqlFile.writeAsStringSync(dump(raw));
    },
    skip: Platform.environment['UPDATE_FINANCIAL_SNAPSHOT'] == '1'
        ? false
        : 'set UPDATE_FINANCIAL_SNAPSHOT=1 to regenerate',
  );

  test('a fresh seed produces the committed figures', () async {
    final env = await CatalogueEnv.open();
    addTearDown(env.close);
    await env.seedSnapshotWorld();
    expect(
      jsonDecode(pretty(await capture(env))),
      jsonDecode(jsonFile.readAsStringSync()),
    );
  });

  test(
    'the committed v11 database upgrades with every figure intact',
    () async {
      final raw = sqlite3.openInMemory();
      addTearDown(raw.close);
      raw.execute(sqlFile.readAsStringSync());
      expect(raw.select('PRAGMA user_version').single.values.single, 11);

      final env = await CatalogueEnv.open(
        database: AppDatabase.forTesting(
          NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
        ),
      );
      addTearDown(env.close);
      // Opening ran onUpgrade(11 -> schemaVersion), a no-op while both are 11.
      expect(env.db.schemaVersion, greaterThanOrEqualTo(11));
      expect(
        raw.select('PRAGMA user_version').single.values.single,
        env.db.schemaVersion,
      );

      expect(
        jsonDecode(pretty(await capture(env))),
        jsonDecode(jsonFile.readAsStringSync()),
      );
    },
  );
}
