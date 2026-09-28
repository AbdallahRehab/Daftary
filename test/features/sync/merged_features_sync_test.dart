import 'dart:convert';

import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/budgets/data/models/budget_ids.dart';
import 'package:daftary/features/budgets/data/sync/budget_sync_mapper.dart';
import 'package:daftary/features/occasions/data/sync/occasion_sync_mapper.dart';
import 'package:daftary/features/transactions/data/sync/money_transaction_sync_mapper.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_daos.dart';

/// 022: the merged 008/010 records sync — their mappers round-trip through
/// JSON losslessly, and every DAO write queues the matching outbox op.
void main() {
  Map<String, Object?> overTheWire(Map<String, Object?> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, Object?>;

  group('mappers round-trip', () {
    test('occasion, soft-deleted', () {
      const mapper = OccasionSyncMapper();
      const row = Occasion(
        id: 'o1',
        idempotencyKey: 'ok1',
        name: "Ahmed's wedding",
        date: 1790000000000,
        type: 'wedding',
        notes: 'Hall B',
        isArchived: true,
        createdAt: 1790000001000,
        updatedAt: 1790000002000,
        deletedAt: 1790000003000,
      );
      final wire = overTheWire(mapper.toWire(row));
      expect(wire['client_updated_at'], '2026-09-21T14:13:23.000Z');
      expect(
        mapper.fromWire(wire),
        row.toCompanion(false).copyWith(updatedAt: const Value(1790000003000)),
      );
    });

    test('budget with and without an expected income', () {
      const mapper = BudgetSyncMapper();
      for (final income in [null, 1500000]) {
        final row = Budget(
          id: BudgetIds.budget('2026-10'),
          idempotencyKey: 'bk',
          month: '2026-10',
          expectedIncomeMinorUnits: income,
          currencyCode: 'USD',
          createdAt: 1790000001000,
          updatedAt: 1790000002000,
        );
        final wire = overTheWire(mapper.toWire(row));
        expect(wire['expected_income_minor'], income?.toString());
        expect(mapper.fromWire(wire), row.toCompanion(false));
      }
    });

    test('budget allocation', () {
      const mapper = BudgetAllocationSyncMapper();
      final row = BudgetCategoryAllocation(
        id: BudgetIds.allocation('budget_2026-10', 'seed_groceries'),
        idempotencyKey: 'ak',
        budgetId: 'budget_2026-10',
        categoryId: 'seed_groceries',
        plannedAmountMinorUnits: 250000,
        createdAt: 1790000001000,
        updatedAt: 1790000002000,
      );
      expect(
        mapper.fromWire(overTheWire(mapper.toWire(row))),
        row.toCompanion(false),
      );
    });

    test('a non-counting OCR-sourced occasion contribution keeps all four '
        'new fields', () {
      const mapper = MoneyTransactionSyncMapper();
      const row = MoneyTransaction(
        id: 't1',
        idempotencyKey: 'k1',
        personId: 'p1',
        amountMinorUnits: 50000,
        currencyCode: 'EGP',
        direction: 'given',
        kind: 'occasionContribution',
        date: 1790000000000,
        occasionId: 'o1',
        countsTowardBalance: false,
        source: 'ocr',
        ocrScanId: 's1',
        createdAt: 1790000000000,
      );
      final companion = mapper.fromWire(overTheWire(mapper.toWire(row)));
      expect(companion.occasionId, const Value('o1'));
      expect(companion.countsTowardBalance, const Value(false));
      expect(companion.source, const Value('ocr'));
      expect(companion.ocrScanId, const Value('s1'));
    });

    test('a row stored by the server before 022 reads as ordinary', () {
      const mapper = MoneyTransactionSyncMapper();
      final wire =
          overTheWire(
            mapper.toWire(
              const MoneyTransaction(
                id: 't1',
                idempotencyKey: 'k1',
                personId: 'p1',
                amountMinorUnits: 100,
                currencyCode: 'EGP',
                direction: 'given',
                kind: 'initialExchange',
                date: 1,
                countsTowardBalance: true,
                source: 'manual',
                createdAt: 1,
              ),
            ),
          )..removeWhere(
            (k, _) => const {
              'occasion_id',
              'counts_toward_balance',
              'source',
              'ocr_scan_id',
            }.contains(k),
          );
      final companion = mapper.fromWire(wire);
      expect(companion.countsTowardBalance, const Value(true));
      expect(companion.source, const Value('manual'));
      expect(companion.occasionId, const Value<String?>(null));
    });
  });

  group('DAO writes queue outbox ops', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<List<SyncOutboxRow>> outbox(SyncEntityType type) =>
        (db.select(db.syncOutboxEntries)
              ..where((o) => o.entityType.equals(type.wire))
              ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
            .get();

    test(
      'occasion insert, archive and soft delete each queue an upsert',
      () async {
        final dao = testOccasionsDao(db);
        final occasion = await dao.insertOccasionIdempotent(
          OccasionsCompanion.insert(
            id: 'o1',
            idempotencyKey: 'ok1',
            name: 'Wedding',
            date: 1,
            type: 'wedding',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
        // A retried insert returns the row and queues nothing more.
        await dao.insertOccasionIdempotent(
          OccasionsCompanion.insert(
            id: 'o2',
            idempotencyKey: 'ok1',
            name: 'Wedding',
            date: 1,
            type: 'wedding',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
        await dao.setArchived(occasion.id, true, DateTime(2026));
        await dao.softDeleteOccasion(occasion.id, DateTime(2026, 2));

        final ops = await outbox(SyncEntityType.occasion);
        expect(ops.map((o) => o.entityId).toSet(), {'o1'});
        final last = jsonDecode(ops.last.payloadJson) as Map<String, Object?>;
        expect(last['is_archived'], isTrue);
        expect(last['deleted_at'], isNotNull);
      },
    );

    test('budget and allocation writes queue upserts; removing an allocation '
        'queues a delete', () async {
      final dao = testBudgetsDao(db);
      await dao.insertBudgetIdempotent(
        BudgetsCompanion.insert(
          id: 'budget_2026-10',
          idempotencyKey: 'bk',
          month: '2026-10',
          createdAt: 1,
          updatedAt: 1,
        ),
      );
      final allocation = await dao.insertAllocationIdempotent(
        BudgetCategoryAllocationsCompanion.insert(
          id: 'alloc_budget_2026-10_seed_groceries',
          idempotencyKey: 'ak',
          budgetId: 'budget_2026-10',
          categoryId: 'seed_groceries',
          plannedAmountMinorUnits: 100,
          createdAt: 1,
          updatedAt: 1,
        ),
      );
      await dao.deleteAllocation(allocation.id);

      expect(await outbox(SyncEntityType.budget), isNotEmpty);
      final allocationOps = await outbox(SyncEntityType.budgetAllocation);
      expect(allocationOps.map((o) => o.entityId).toSet(), {allocation.id});
      expect(allocationOps.last.opType, 'delete');
    });
  });
}
