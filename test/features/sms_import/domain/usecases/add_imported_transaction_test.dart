import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_repository.dart';
import 'package:daftary/features/sms_import/domain/usecases/add_imported_transaction.dart';
import 'package:daftary/features/sms_import/domain/usecases/check_duplicates.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';

void main() {
  late FakeSmsImportRepository repository;
  late FakeSmsDuplicateLookup lookup;
  late AddImportedTransaction add;

  final validExpense = ReviewDraft(
    type: SuggestedRecordType.expense,
    amountMinorUnits: 12550,
    currencyCode: 'EGP',
    date: DateTime(2026, 3, 4),
    categoryId: 'seed_groceries',
    note: '  coffee  ',
  );

  setUp(() {
    repository = FakeSmsImportRepository()..seed([buildPendingImport()]);
    lookup = FakeSmsDuplicateLookup();
    add = AddImportedTransaction(
      repository,
      CheckDuplicates(lookup, FakeBankReferencePolicy()),
    );
  });
  tearDown(() => repository.close());

  test('confirms an expense with trimmed note through the gate', () async {
    final result = await add(pendingId: 'pending-1', draft: validExpense);
    expect(
      result.getOrElse((f) => fail('$f')).type,
      SavedRecordType.financeEntry,
    );
    final call = repository.confirmCalls.single;
    expect(call.pendingId, 'pending-1');
    final confirmed = call.confirmed as ConfirmedFinanceEntry;
    expect(confirmed.type, FinanceEntryType.expense);
    expect(confirmed.amount, const Money.egp(12550));
    expect(confirmed.note, 'coffee');
  });

  test('income maps to a finance income entry', () async {
    await add(
      pendingId: 'pending-1',
      draft: validExpense.copyWith(type: SuggestedRecordType.income),
    );
    expect(
      (repository.confirmCalls.single.confirmed as ConfirmedFinanceEntry).type,
      FinanceEntryType.income,
    );
  });

  test('received maps to a people-ledger transaction', () async {
    await add(
      pendingId: 'pending-1',
      draft: validExpense.copyWith(
        type: SuggestedRecordType.received,
        personId: 'person-1',
        clearNote: true,
      ),
    );
    final confirmed =
        repository.confirmCalls.single.confirmed as ConfirmedPersonTransaction;
    expect(confirmed.direction, TransactionDirection.received);
    expect(confirmed.personId, 'person-1');
    expect(confirmed.note, isNull);
  });

  test(
    'an incomplete draft is refused with field codes; nothing confirmed',
    () async {
      final result = await add(
        pendingId: 'pending-1',
        draft: validExpense.copyWith(clearCategory: true, clearDate: true),
      );
      final failure = result.getLeft().toNullable();
      expect(failure, isA<ImportIncompleteFailure>());
      expect((failure! as ImportIncompleteFailure).fields, {
        ReviewField.category,
        ReviewField.date,
      });
      expect(repository.confirmCalls, isEmpty);
    },
  );

  test('a decided item is refused', () async {
    await repository.ignore({'pending-1'});
    final result = await add(pendingId: 'pending-1', draft: validExpense);
    expect(result.getLeft().toNullable(), isA<ImportAlreadyDecidedFailure>());
    expect(repository.confirmCalls, isEmpty);
  });

  test('an unknown item is NotFound', () async {
    final result = await add(pendingId: 'nope', draft: validExpense);
    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  group('duplicates', () {
    setUp(() {
      lookup.savedMatches = [
        DuplicateRecordRef(
          id: 'entry-9',
          recordType: SavedRecordType.financeEntry,
          type: SuggestedRecordType.expense,
          amount: const Money.egp(12550),
          date: DateTime(2026, 3, 4),
        ),
      ];
    });

    test(
      'a probable duplicate returns the finding and confirms nothing',
      () async {
        final result = await add(pendingId: 'pending-1', draft: validExpense);
        final failure = result.getLeft().toNullable();
        expect(failure, isA<ProbableDuplicateFailure>());
        expect(
          (failure! as ProbableDuplicateFailure).finding.tier,
          DuplicateTier.probable,
        );
        expect(repository.confirmCalls, isEmpty);
      },
    );

    test('duplicateOverride adds anyway and skips the check', () async {
      final result = await add(
        pendingId: 'pending-1',
        draft: validExpense,
        duplicateOverride: true,
      );
      expect(result.isRight(), isTrue);
      expect(lookup.savedMatchCalls, isEmpty);
      expect(repository.confirmCalls, hasLength(1));
    });
  });

  test('a confirm failure is passed on and the item stays pending', () async {
    repository.nextFailure = const CacheFailure('sms_confirm_failed');
    final result = await add(pendingId: 'pending-1', draft: validExpense);
    expect(result.getLeft().toNullable(), isA<CacheFailure>());
    expect(repository.rows['pending-1']!.isPending, isTrue);
  });
}
