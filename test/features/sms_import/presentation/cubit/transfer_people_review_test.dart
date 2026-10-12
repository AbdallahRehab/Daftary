import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/presentation/cubit/import_review_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/import_review_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';
import '../../helpers/review_harness.dart';

/// T140 (T138) — the transfer, people and cash-withdrawal suggestions of
/// `ImportReviewCubit` (FR-051a/b/c, FR-054, US7). Nobody is ever created
/// without an explicit call. Every name is synthetic.
void main() {
  late ReviewHarness harness;
  late ImportReviewCubit cubit;

  setUp(() {
    harness = ReviewHarness(
      people: [
        testPerson('person-1', 'Mona'),
        testPerson('person-2', 'Mona Adel'),
        testPerson('person-3', 'Karim'),
      ],
    );
  });
  tearDown(() async {
    await cubit.close();
    await harness.dispose();
  });

  Future<void> open(Object item) async {
    harness.repository.seed([item].cast());
    cubit = harness.build();
    await cubit.load('pending-1');
  }

  int peopleCount() => harness.people.people.length;

  group('named transfers (FR-051a, FR-054)', () {
    test('one exact match: Income stays the default, the one-tap Received '
        'pre-selects the person, nobody is created', () async {
      await open(
        buildPendingImport(
          kind: SmsKind.transferIn,
          direction: SmsDirection.credit,
          suggestedType: SuggestedRecordType.income,
          suggestedPersonId: 'person-3',
          counterparty: 'Karim',
          merchant: null,
        ),
      );
      expect(cubit.state.draft!.type, SuggestedRecordType.income);
      expect(cubit.state.draft!.personId, isNull);
      expect(cubit.state.similarPeople, isEmpty);
      await cubit.acceptSuggestedPerson();
      expect(cubit.state.draft!.type, SuggestedRecordType.received);
      expect(cubit.state.draft!.personId, 'person-3');
      expect(cubit.state.selectedPerson?.name, 'Karim');
      // Switching back is always available.
      await cubit.typeChanged(SuggestedRecordType.income);
      expect(cubit.state.draft!.personId, isNull);
      expect(peopleCount(), 3);
    });

    test('several people could match: the similar-name choice, then a pick; '
        'nobody is created', () async {
      await open(
        buildPendingImport(
          kind: SmsKind.transferOut,
          suggestedType: SuggestedRecordType.expense,
          counterparty: 'mona',
          merchant: null,
        ),
      );
      expect(cubit.state.draft!.type, SuggestedRecordType.expense);
      expect(
        cubit.state.similarPeople.map((p) => p.id),
        unorderedEquals(['person-1', 'person-2']),
      );
      await cubit.chooseFromSimilarPeople();
      expect(cubit.state.draft!.type, SuggestedRecordType.given);
      expect(cubit.state.personDuplicateMatches, hasLength(2));
      expect(cubit.state.pendingPersonName, 'mona');
      cubit.personSelected(cubit.state.personDuplicateMatches.last);
      expect(cubit.state.draft!.personId, isNotNull);
      expect(cubit.state.personDuplicateMatches, isEmpty);
      expect(peopleCount(), 3);
    });

    test('several matches: a new person only after "create anyway"', () async {
      await open(
        buildPendingImport(
          kind: SmsKind.transferIn,
          direction: SmsDirection.credit,
          suggestedType: SuggestedRecordType.income,
          counterparty: 'Mona',
          merchant: null,
        ),
      );
      await cubit.chooseFromSimilarPeople();
      expect(cubit.state.draft!.type, SuggestedRecordType.received);
      expect(peopleCount(), 3);
      await cubit.confirmCreatePersonDespiteDuplicate();
      expect(peopleCount(), 4);
      expect(cubit.state.draft!.personId, startsWith('new-person'));
    });

    test('no match: Income stays, no similar choice; switching to Received '
        'fills the search with the name and creates nobody', () async {
      await open(
        buildPendingImport(
          kind: SmsKind.transferIn,
          direction: SmsDirection.credit,
          suggestedType: SuggestedRecordType.income,
          counterparty: 'Example Sender',
          merchant: null,
        ),
      );
      expect(cubit.state.draft!.type, SuggestedRecordType.income);
      expect(cubit.state.similarPeople, isEmpty);
      await cubit.chooseFromSimilarPeople(); // not offered: a no-op
      expect(cubit.state.draft!.type, SuggestedRecordType.income);

      await cubit.typeChanged(SuggestedRecordType.received);
      expect(cubit.state.personQuery, 'Example Sender');
      expect(cubit.state.selectedPerson, isNull);
      expect(cubit.state.draft!.personId, isNull);
      expect(peopleCount(), 3);

      // Only the explicit tap creates, through CreatePerson.
      await cubit.createPerson('Example Sender');
      expect(peopleCount(), 4);
      expect(cubit.state.selectedPerson?.name, 'Example Sender');
    });

    test(
      'a single similar (not exact) name is not offered as a choice',
      () async {
        await open(
          buildPendingImport(
            kind: SmsKind.transferIn,
            direction: SmsDirection.credit,
            suggestedType: SuggestedRecordType.income,
            counterparty: 'Karim Example',
            merchant: null,
          ),
        );
        expect(cubit.state.similarPeople, isEmpty);
      },
    );

    test('a purchase never looks for people', () async {
      await open(buildPendingImport(counterparty: 'Mona'));
      expect(cubit.state.similarPeople, isEmpty);
    });
  });

  group('own-account and Ignore suggestions (FR-051a, FR-051c)', () {
    test('own-account: Ignore is suggested, no type is chosen', () async {
      await open(
        buildPendingImport(
          kind: SmsKind.ownAccountTransfer,
          suggestedType: SuggestedRecordType.ignore,
          warnings: {SmsWarning.ownAccountSuggestedIgnore},
        ),
      );
      expect(cubit.state.suggestedType, SuggestedRecordType.ignore);
      expect(cubit.state.draft!.type, isNull);
      expect(cubit.state.canAdd, isFalse);
    });
  });

  group('cash withdrawals (FR-051b)', () {
    PendingSmsImport atm({
      SuggestedRecordType type = SuggestedRecordType.ignore,
    }) => buildPendingImport(
      kind: SmsKind.atmWithdrawal,
      suggestedType: type,
      merchant: null,
      warnings: type == SuggestedRecordType.ignore
          ? {SmsWarning.atmIgnoredByDefault}
          : const {},
    );

    test('preference off: Ignore suggested, no type chosen', () async {
      await open(atm());
      expect(cubit.state.countCashWithdrawals, isFalse);
      expect(cubit.state.suggestedType, SuggestedRecordType.ignore);
      expect(cubit.state.draft!.type, isNull);
    });

    test('preference on: Expense, even for an item parsed while it was '
        'off', () async {
      await harness.settings.setCountCashWithdrawals(true);
      await open(atm());
      expect(cubit.state.suggestedType, SuggestedRecordType.expense);
      expect(cubit.state.draft!.type, SuggestedRecordType.expense);
      expect(cubit.state.isDirty, isFalse);
    });

    test('preference turned off after parsing: Ignore again', () async {
      await open(atm(type: SuggestedRecordType.expense));
      expect(cubit.state.suggestedType, SuggestedRecordType.ignore);
      expect(cubit.state.draft!.type, isNull);
    });

    test('back from the preference: the new default applies while the '
        'draft is untouched', () async {
      await open(atm());
      await harness.settings.setCountCashWithdrawals(true);
      await cubit.refreshCashPreference();
      expect(cubit.state.draft!.type, SuggestedRecordType.expense);
      expect(cubit.state.isDirty, isFalse);
      expect(cubit.state.categories, isNotEmpty);
    });

    test('back from the preference: edits are never replaced', () async {
      await open(atm());
      await cubit.typeChanged(SuggestedRecordType.income);
      await harness.settings.setCountCashWithdrawals(true);
      await cubit.refreshCashPreference();
      expect(cubit.state.draft!.type, SuggestedRecordType.income);
      expect(cubit.state.countCashWithdrawals, isTrue);
    });

    test('without the settings reader the parsed suggestion stays', () async {
      harness.repository.seed([atm(type: SuggestedRecordType.expense)]);
      cubit = harness.build(withSettings: false);
      await cubit.load('pending-1');
      expect(cubit.state.countCashWithdrawals, isNull);
      expect(cubit.state.draft!.type, SuggestedRecordType.expense);
    });
  });

  test('the state stays redacted with people loaded', () async {
    await open(
      buildPendingImport(
        kind: SmsKind.transferIn,
        direction: SmsDirection.credit,
        suggestedType: SuggestedRecordType.income,
        counterparty: 'Mona',
        merchant: null,
      ),
    );
    final text = cubit.state.toString();
    expect(text, isNot(contains('Mona')));
    expect(cubit.state, isA<ImportReviewState>());
  });
}
