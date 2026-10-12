import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/usecases/add_imported_transaction.dart';
import 'package:daftary/features/sms_import/domain/usecases/check_duplicates.dart';
import 'package:daftary/features/sms_import/presentation/cubit/import_review_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/import_review_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/review_harness.dart';

/// T071 — `ImportReviewCubit` on in-memory fakes. Every value is synthetic.
void main() {
  late ReviewHarness harness;
  late ImportReviewCubit cubit;

  setUp(() {
    harness = ReviewHarness();
  });
  tearDown(() async {
    await cubit.close();
    await harness.dispose();
  });

  Future<ImportReviewCubit> open(
    List<Object> items, {
    String id = 'pending-1',
    ReviewHarness? using,
  }) async {
    final h = using ?? harness;
    h.repository.seed(items.cast());
    cubit = h.build();
    await cubit.load(id);
    return cubit;
  }

  group('load', () {
    test(
      'builds the draft from the suggestion; note never prefilled',
      () async {
        await open([
          buildPendingImport(suggestedType: SuggestedRecordType.expense),
        ]);
        final state = cubit.state;
        expect(state.status, ImportReviewStatus.ready);
        final draft = state.draft!;
        expect(draft.type, SuggestedRecordType.expense);
        expect(draft.amountMinorUnits, 12550);
        expect(draft.currencyCode, 'EGP');
        expect(draft.date, DateTime(2026, 3, 4));
        expect(draft.note, isNull);
        expect(state.amountInput, '125.50');
        expect(state.categories.map((c) => c.id), [
          'seed_groceries',
          'seed_other',
        ]);
        expect(state.isDirty, isFalse);
        expect(harness.leases.isLeased('pending-1'), isTrue);
        // Missing category is reported (none suggested).
        expect(state.missing, {ReviewField.category});
        expect(state.canAdd, isFalse);
      },
    );

    test('ignore/unset suggestions show no type selected', () async {
      await open([
        buildPendingImport(suggestedType: SuggestedRecordType.ignore),
      ]);
      expect(cubit.state.draft!.type, isNull);
      expect(cubit.state.missing, contains(ReviewField.type));
    });

    test('one amount candidate and no currency: amount pre-filled, '
        'currency required', () async {
      await open([
        buildPendingImport(amount: null, candidates: [4200]),
      ]);
      final draft = cubit.state.draft!;
      expect(draft.amountMinorUnits, 4200);
      expect(draft.currencyCode, isNull);
      expect(cubit.state.amountInput, '42.00');
      expect(cubit.state.missing, contains(ReviewField.currency));
      expect(cubit.state.missing, isNot(contains(ReviewField.amount)));
    });

    test('two candidates: no amount until a chip is chosen', () async {
      await open([
        buildPendingImport(amount: null, candidates: [4200, 9900]),
      ]);
      expect(cubit.state.draft!.amountMinorUnits, isNull);
      cubit.amountCandidateChosen(9900);
      expect(cubit.state.draft!.amountMinorUnits, 9900);
      expect(cubit.state.amountInput, '99.00');
    });

    test('an archived suggested category is cleared, not blocking', () async {
      final h = ReviewHarness(
        categories: [
          testCategory(
            'seed_groceries',
            FinanceEntryType.expense,
            archived: true,
          ),
          testCategory('seed_other', FinanceEntryType.expense),
        ],
      );
      await open([
        buildPendingImport(suggestedCategoryId: 'seed_groceries'),
      ], using: h);
      expect(cubit.state.draft!.categoryId, isNull);
      expect(cubit.state.isDirty, isFalse);
      await h.dispose();
    });

    test('a decided item opens as already handled', () async {
      await open([
        pendingWithDecision(
          buildPendingImport(),
          status: SmsImportStatus.ignored,
          decidedAt: DateTime(2026, 3, 4),
        ),
      ]);
      expect(cubit.state.status, ImportReviewStatus.alreadyHandled);
      expect(harness.leases.isLeased('pending-1'), isFalse);
    });

    test('a missing item opens as already handled', () async {
      await open([], id: 'gone');
      expect(cubit.state.status, ImportReviewStatus.alreadyHandled);
    });
  });

  group('edits', () {
    test('editing marks the draft dirty and drives validation', () async {
      await open([buildPendingImport()]);
      cubit.categorySelected('seed_groceries');
      expect(cubit.state.isDirty, isTrue);
      expect(cubit.state.canAdd, isTrue);
      cubit.amountChanged('abc');
      expect(cubit.state.draft!.amountMinorUnits, isNull);
      expect(cubit.state.canAdd, isFalse);
      cubit.amountChanged('١٥٠٫٢٥');
      expect(cubit.state.draft!.amountMinorUnits, 15025);
      cubit.amountChanged('1234567890123');
      expect(cubit.state.missing, contains(ReviewField.amount));
      cubit.amountChanged('0');
      expect(cubit.state.missing, contains(ReviewField.amount));
    });

    test(
      'type switch moves the required field between category and person',
      () async {
        await open([
          buildPendingImport(
            kind: SmsKind.transferOut,
            suggestedCategoryId: 'seed_other',
          ),
        ]);
        expect(cubit.state.draft!.categoryId, 'seed_other');
        expect(cubit.state.missing, isEmpty);

        await cubit.typeChanged(SuggestedRecordType.given);
        expect(cubit.state.draft!.categoryId, isNull);
        expect(cubit.state.missing, {ReviewField.person});
        cubit.personSelected(testPerson('person-1', 'Mona'));
        expect(cubit.state.missing, isEmpty);

        await cubit.typeChanged(SuggestedRecordType.income);
        expect(cubit.state.draft!.personId, isNull);
        expect(cubit.state.missing, {ReviewField.category});
        expect(cubit.state.categories.map((c) => c.id), ['seed_salary']);
      },
    );

    test('one-tap suggested person preselects the person', () async {
      await open([
        buildPendingImport(
          kind: SmsKind.transferIn,
          direction: SmsDirection.credit,
          suggestedType: SuggestedRecordType.income,
          suggestedPersonId: 'person-1',
          counterparty: 'Mona',
        ),
      ]);
      await cubit.acceptSuggestedPerson();
      expect(cubit.state.draft!.type, SuggestedRecordType.received);
      expect(cubit.state.draft!.personId, 'person-1');
      expect(cubit.state.selectedPerson?.name, 'Mona');
    });

    test('currency choice re-reads the typed amount', () async {
      await open([
        buildPendingImport(amount: null, candidates: [4200]),
      ]);
      cubit.currencyChanged(Currency.usd);
      expect(cubit.state.draft!.currencyCode, 'USD');
      expect(
        cubit.state.draft!.money,
        Money.fromMinorUnits(4200, Currency.usd),
      );
    });

    test('use merchant as note copies only on request', () async {
      await open([buildPendingImport()]);
      expect(cubit.state.draft!.note, isNull);
      cubit.useMerchantAsNote();
      expect(cubit.state.draft!.note, 'Example Cafe');
    });

    test('creating a similar-named person shows the existing choice', () async {
      await open([
        buildPendingImport(suggestedType: SuggestedRecordType.given),
      ]);
      await cubit.createPerson('mona');
      expect(cubit.state.personDuplicateMatches.single.id, 'person-1');
      await cubit.confirmCreatePersonDespiteDuplicate();
      expect(cubit.state.draft!.personId, startsWith('new-person'));
      expect(cubit.state.personDuplicateMatches, isEmpty);
    });
  });

  group('add', () {
    Future<void> ready() async {
      await open([
        buildPendingImport(),
        buildPendingImport(
          id: 'pending-2',
          fingerprint: 'fp-2',
          createdAt: DateTime(2026, 3, 5),
        ),
      ]);
      cubit.categorySelected('seed_groceries');
    }

    test('disabled until validate() is empty: add() does nothing', () async {
      await open([buildPendingImport()]);
      expect(cubit.state.canAdd, isFalse);
      await cubit.add();
      expect(harness.repository.confirmCalls, isEmpty);
      expect(cubit.state.status, ImportReviewStatus.ready);
    });

    test(
      'adds once, releases the lease and advances to the next item',
      () async {
        await ready();
        await cubit.add();
        expect(harness.repository.confirmCalls, hasLength(1));
        expect(cubit.state.status, ImportReviewStatus.success);
        expect(cubit.state.nextImportId, 'pending-2');
        expect(harness.leases.isLeased('pending-1'), isFalse);
      },
    );

    test('a double tap is single-flight', () async {
      final gate = Completer<void>();
      final slow = _SlowAdd(harness, gate.future);
      final h = ReviewHarness(addOverride: slow);
      h.repository.seed([buildPendingImport()]);
      cubit = h.build();
      await cubit.load('pending-1');
      cubit.categorySelected('seed_groceries');
      final first = cubit.add();
      final second = cubit.add();
      expect(cubit.state.status, ImportReviewStatus.submitting);
      gate.complete();
      await Future.wait([first, second]);
      expect(slow.calls, 1);
      await h.dispose();
    });

    test('ImportAlreadyDecided shows the already-handled state', () async {
      await ready();
      harness.repository.nextFailure = const ImportAlreadyDecidedFailure(
        SmsImportStatus.added,
      );
      await cubit.add();
      expect(cubit.state.status, ImportReviewStatus.alreadyHandled);
    });

    test('NotFound (deleted elsewhere) shows the already-handled state and '
        'releases the lease', () async {
      await ready();
      harness.repository.nextFailure = const NotFoundFailure('sms_not_found');
      await cubit.add();
      expect(cubit.state.status, ImportReviewStatus.alreadyHandled);
      expect(cubit.state.failure, isNull);
      expect(harness.leases.isLeased('pending-1'), isFalse);
    });

    test('a save failure keeps the item pending and is shown', () async {
      await ready();
      harness.repository.nextFailure = const CacheFailure('sms_confirm_failed');
      await cubit.add();
      expect(cubit.state.status, ImportReviewStatus.ready);
      expect(cubit.state.failure, isA<CacheFailure>());
      expect(harness.repository.rows['pending-1']!.isPending, isTrue);
    });

    test(
      'a probable duplicate raises a one-shot request; override adds',
      () async {
        harness.lookup.savedMatches = [
          DuplicateRecordRef(
            id: 'entry-9',
            recordType: SavedRecordType.financeEntry,
            type: SuggestedRecordType.expense,
            amount: const Money.egp(12550),
            date: DateTime(2026, 3, 4),
          ),
        ];
        await ready();
        await cubit.add();
        expect(cubit.state.duplicateRequest?.tier, DuplicateTier.probable);
        expect(harness.repository.confirmCalls, isEmpty);
        cubit.consumeDuplicateRequest();
        expect(cubit.state.duplicateRequest, isNull);
        await cubit.add(duplicateOverride: true);
        expect(harness.repository.confirmCalls, hasLength(1));
      },
    );
  });

  group('leaving', () {
    test('no edits: leaving is allowed and the item stays pending', () async {
      await open([buildPendingImport()]);
      expect(cubit.requestLeave(), isTrue);
      expect(harness.repository.rows['pending-1']!.isPending, isTrue);
    });

    test('with edits: the discard prompt flag is raised', () async {
      await open([buildPendingImport()]);
      cubit.noteChanged('x');
      expect(cubit.requestLeave(), isFalse);
      expect(cubit.state.requiresDiscardConfirmation, isTrue);
      cubit.keepEditing();
      expect(cubit.state.requiresDiscardConfirmation, isFalse);
      cubit.requestLeave();
      cubit.confirmDiscard();
      expect(cubit.state.leaveApproved, isTrue);
      expect(harness.repository.confirmCalls, isEmpty);
    });

    test('close releases the lease', () async {
      await open([buildPendingImport()]);
      await cubit.close();
      expect(harness.leases.isLeased('pending-1'), isFalse);
    });
  });

  group('original message', () {
    test('shown on expand, dropped on collapse', () async {
      harness.repository.seed([buildPendingImport()]);
      await harness.repository.insertPending(
        NewPendingImport(
          item: buildPendingImport(id: 'pending-9', fingerprint: 'fp-9'),
          rawMasked: 'Purchase EGP 1.00 at Example',
        ),
      );
      cubit = harness.build();
      await cubit.load('pending-9');
      await cubit.toggleOriginal();
      expect(cubit.state.originalSection, OriginalSection.shown);
      expect(cubit.state.original!.direction, TextDirectionHint.ltr);
      await cubit.toggleOriginal();
      expect(cubit.state.original, isNull);
    });

    test('unavailable when there is no original', () async {
      await open([buildPendingImport(hasRawText: false)]);
      await cubit.toggleOriginal();
      expect(cubit.state.originalSection, OriginalSection.unavailable);
    });
  });

  group('duplicates (T102, US5)', () {
    DuplicateRecordRef manualMatch() => DuplicateRecordRef(
      id: 'entry-9',
      recordType: SavedRecordType.financeEntry,
      type: SuggestedRecordType.expense,
      amount: const Money.egp(12550),
      date: DateTime(2026, 3, 4),
    );

    Future<void> readyWithMatch({List<Object>? extra}) async {
      harness.lookup.savedMatches = [manualMatch()];
      await open([
        buildPendingImport(),
        buildPendingImport(
          id: 'pending-2',
          fingerprint: 'fp-2',
          amount: const Money.egp(500),
          createdAt: DateTime(2026, 3, 5),
        ),
        ...?extra,
      ]);
      cubit.categorySelected('seed_groceries');
    }

    test(
      'checked when the review opens: probable finding, no request',
      () async {
        await readyWithMatch();
        expect(cubit.state.finding?.tier, DuplicateTier.probable);
        expect(cubit.state.finding?.matchedRecord?.id, 'entry-9');
        // The banner shows; the sheet only opens on Compare or on Add.
        expect(cubit.state.duplicateRequest, isNull);
        expect(harness.repository.confirmCalls, isEmpty);
      },
    );

    test(
      'Compare raises the one-shot request for the current finding',
      () async {
        await readyWithMatch();
        cubit.compareDuplicate();
        expect(cubit.state.duplicateRequest, cubit.state.finding);
        cubit.consumeDuplicateRequest();
        expect(cubit.state.duplicateRequest, isNull);
      },
    );

    test('Compare does nothing without a probable finding', () async {
      await open([buildPendingImport()]);
      expect(cubit.state.finding?.isProbable, isFalse);
      cubit.compareDuplicate();
      expect(cubit.state.duplicateRequest, isNull);
    });

    test('Add is raised late: the request opens instead of failing, and '
        'nothing is saved', () async {
      await readyWithMatch();
      await cubit.add();
      expect(cubit.state.status, ImportReviewStatus.ready);
      expect(cubit.state.duplicateRequest?.tier, DuplicateTier.probable);
      expect(cubit.state.failure, isNull);
      expect(harness.repository.confirmCalls, isEmpty);
    });

    test('"add anyway" adds with the override', () async {
      await readyWithMatch();
      await cubit.add();
      cubit.consumeDuplicateRequest();
      await cubit.add(duplicateOverride: true);
      expect(harness.repository.confirmCalls, hasLength(1));
      expect(cubit.state.status, ImportReviewStatus.success);
    });

    test(
      '"same" closes the item as a duplicate, adds nothing and advances',
      () async {
        await readyWithMatch();
        await cubit.add();
        cubit.consumeDuplicateRequest();
        await cubit.closeAsDuplicate();
        expect(cubit.state.status, ImportReviewStatus.closedAsDuplicate);
        expect(cubit.state.nextImportId, 'pending-2');
        expect(cubit.state.original, isNull);
        expect(harness.repository.confirmCalls, isEmpty);
        final row = harness.repository.rows['pending-1']!;
        expect(row.status, SmsImportStatus.duplicateClosed);
        expect(
          harness.repository.tombstones[row.fingerprint]?.outcome,
          TombstoneOutcome.duplicate,
        );
        expect(harness.leases.isLeased('pending-1'), isFalse);
        // Settled: leaving never asks.
        expect(cubit.requestLeave(), isTrue);
      },
    );

    test('"same" on the last item pops to the list', () async {
      harness.lookup.savedMatches = [manualMatch()];
      await open([buildPendingImport()]);
      await cubit.closeAsDuplicate();
      expect(cubit.state.status, ImportReviewStatus.closedAsDuplicate);
      expect(cubit.state.nextImportId, isNull);
    });

    test('"same" on an item decided elsewhere shows already handled', () async {
      await readyWithMatch();
      await harness.repository.closeAsDuplicate('pending-1');
      await cubit.closeAsDuplicate();
      expect(cubit.state.status, ImportReviewStatus.alreadyHandled);
    });

    test('a close failure keeps the item pending and is shown', () async {
      final h = ReviewHarness(repositoryOverride: _FailingClose());
      h.repository.seed([buildPendingImport()]);
      cubit = h.build();
      await cubit.load('pending-1');
      await cubit.closeAsDuplicate();
      expect(cubit.state.status, ImportReviewStatus.ready);
      expect(cubit.state.failure, isA<CacheFailure>());
      expect(h.repository.rows['pending-1']!.isPending, isTrue);
      expect(h.leases.isLeased('pending-1'), isTrue);
      await cubit.close();
      await h.dispose();
    });

    test('"same" is single-flight and blocked while adding', () async {
      final repository = _CountingClose();
      final h = ReviewHarness(repositoryOverride: repository);
      h.repository.seed([buildPendingImport()]);
      cubit = h.build();
      await cubit.load('pending-1');
      final first = cubit.closeAsDuplicate();
      final second = cubit.closeAsDuplicate();
      final add = cubit.add(duplicateOverride: true);
      expect(cubit.state.status, ImportReviewStatus.submitting);
      await Future.wait([first, second, add]);
      expect(repository.closeCalls, 1);
      expect(h.repository.confirmCalls, isEmpty);
      await cubit.close();
      await h.dispose();
    });

    test('a pending-pair finding loads the other pending item for the '
        'side-by-side card', () async {
      final other = buildPendingImport(
        id: 'pending-3',
        fingerprint: 'fp-3',
        createdAt: DateTime(2026, 3, 6),
      );
      harness.lookup.pendingPair = other;
      await open([buildPendingImport(), other]);
      expect(cubit.state.finding?.probableBasis, ProbableBasis.pendingPair);
      expect(cubit.state.duplicatePending?.id, 'pending-3');
    });

    test(
      'the pending pair is cleared when an edit removes the finding',
      () async {
        final other = buildPendingImport(
          id: 'pending-3',
          fingerprint: 'fp-3',
          createdAt: DateTime(2026, 3, 6),
        );
        harness.lookup.pendingPair = other;
        await open([buildPendingImport(), other]);
        harness.lookup.pendingPair = null;
        cubit.dateChanged(DateTime(2026, 2, 20));
        await cubit.runDuplicateCheck();
        expect(cubit.state.finding?.isProbable, isFalse);
        expect(cubit.state.duplicatePending, isNull);
      },
    );
  });

  test('duplicate check re-runs after edits settle', () async {
    await open([buildPendingImport()]);
    final calls = harness.lookup.savedMatchCalls.length;
    cubit.dateChanged(DateTime(2026, 3, 1));
    await Future<void>.delayed(
      ImportReviewCubit.duplicateCheckDebounce +
          const Duration(milliseconds: 50),
    );
    expect(harness.lookup.savedMatchCalls.length, greaterThan(calls));
    expect(harness.lookup.savedMatchCalls.last.date, DateTime(2026, 3, 1));
  });

  test('toString is redacted', () async {
    await open([buildPendingImport(merchant: 'Secret Shop')]);
    cubit.noteChanged('my private note');
    final text = cubit.state.toString();
    expect(text, isNot(contains('Secret')));
    expect(text, isNot(contains('private')));
    expect(text, isNot(contains('125')));
    expect(text, isNot(contains('pending-1')));
  });
}

/// Delays every Add until [gate] completes, counting calls.
class _SlowAdd extends AddImportedTransaction {
  _SlowAdd(ReviewHarness h, this.gate)
    : super(h.repository, CheckDuplicates(h.lookup, FakeBankReferencePolicy()));

  final Future<void> gate;
  int calls = 0;

  @override
  Future<Either<Failure, SavedRecordRef>> call({
    required String pendingId,
    required ReviewDraft draft,
    bool duplicateOverride = false,
  }) async {
    calls++;
    await gate;
    return const Right(
      SavedRecordRef(id: 'saved-1', type: SavedRecordType.financeEntry),
    );
  }
}

/// `closeAsDuplicate` always fails with a store failure.
class _FailingClose extends FakeSmsImportRepository {
  @override
  Future<Either<Failure, Unit>> closeAsDuplicate(String id) async =>
      const Left(CacheFailure('sms_import_store_failed'));
}

/// Counts `closeAsDuplicate` calls, each held for one event-loop turn.
class _CountingClose extends FakeSmsImportRepository {
  int closeCalls = 0;

  @override
  Future<Either<Failure, Unit>> closeAsDuplicate(String id) async {
    closeCalls++;
    await Future<void>.delayed(Duration.zero);
    return super.closeAsDuplicate(id);
  }
}
