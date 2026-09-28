import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_attachment.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_filter.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_summary.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/main.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';

/// T086 — end-to-end coverage of US1-US5 against the real app (real DI,
/// real on-device SQLite), following quickstart.md's Manual Validation
/// Scenarios 1-8.
///
/// The cross-feature assertions are the point of this file: that one
/// contribution is a single `MoneyTransaction` row visible from both the
/// occasion and the person (US2), that deleting an occasion actually moves
/// the affected person's balance (Scenario 6), and that a condolence
/// contribution deliberately does not (Scenario 7). Those are exactly the
/// guarantees no single-layer unit test can prove.
///
/// Each test suffixes the data it creates with a UUID, so repeated runs
/// against the same persisted on-device database never collide.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // `lib/main.dart`'s own `main()` is never invoked by an integration test,
  // so DI bootstrap has to happen explicitly before the first `pumpWidget`.
  setUpAll(() async => configureDependencies());

  const uuid = Uuid();
  String unique(String base) => '$base ${uuid.v4().substring(0, 8)}';

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  // Resolved per call rather than captured once, because DI is only
  // configured in `setUpAll` — after this scope is built.
  OccasionsRepository occasions() => getIt<OccasionsRepository>();
  TransactionsRepository transactions() => getIt<TransactionsRepository>();
  PeopleRepository people() => getIt<PeopleRepository>();

  Future<String> createPerson(String name) async {
    final result = await people().createPerson(name: name);
    return result.valueOrFail.id;
  }

  Future<String> createOccasion({
    required String name,
    String type = OccasionType.wedding,
    DateTime? date,
  }) async {
    final result = await occasions().createOccasion(
      idempotencyKey: uuid.v4(),
      name: name,
      date: date ?? DateTime(2026, 9, 15),
      type: type,
    );
    return result.valueOrFail.id;
  }

  Future<MoneyTransaction> contribute({
    required String occasionId,
    required String personId,
    required int minorUnits,
    TransactionDirection direction = TransactionDirection.received,
    bool? countsTowardBalance,
  }) async {
    final result = await occasions().addParticipantContribution(
      idempotencyKey: uuid.v4(),
      occasionId: occasionId,
      personId: personId,
      amount: Money.egp(minorUnits),
      direction: direction,
      date: DateTime(2026, 9, 15),
      countsTowardBalance: countsTowardBalance,
    );
    return result.valueOrFail;
  }

  Future<int> balanceOf(String personId) async {
    final result = await transactions().getPersonBalance(personId);
    return result.valueOrFail.net!.minorUnits;
  }

  group('User Story 1 — create an occasion and record participants', () {
    testWidgets('four contributions produce the right total received', (
      _,
    ) async {
      final occasionId = await createOccasion(name: unique("Ahmed's Wedding"));
      for (final amount in [200000, 100000, 50000, 150000]) {
        await contribute(
          occasionId: occasionId,
          personId: await createPerson(unique('Guest')),
          minorUnits: amount,
        );
      }

      final detail = (await occasions().getOccasionDetail(
        occasionId,
      )).valueOrFail;

      expect(detail.summary.totalReceived, Money.egp(500000));
      expect(detail.summary.participantCount, 4);
      expect(detail.participants, hasLength(4));
    });

    testWidgets('a zero amount is rejected (FR-004)', (_) async {
      final occasionId = await createOccasion(name: unique('Wedding'));
      final result = await occasions().addParticipantContribution(
        idempotencyKey: uuid.v4(),
        occasionId: occasionId,
        personId: await createPerson(unique('Guest')),
        amount: Money.zero(Currency.egp),
        direction: TransactionDirection.received,
        date: DateTime(2026, 9, 15),
      );
      expect(result.isLeft(), isTrue);
    });

    testWidgets('an occasion with no type is rejected (FR-002)', (_) async {
      final result = await occasions().createOccasion(
        idempotencyKey: uuid.v4(),
        name: unique('Wedding'),
        date: DateTime(2026, 9, 15),
        type: '   ',
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('User Story 2 — one row, two views', () {
    testWidgets('a contribution appears in the person\'s own history and '
        'counts once toward their balance (FR-005/FR-009)', (_) async {
      final personId = await createPerson(unique('Ahmed'));
      final occasionId = await createOccasion(name: unique("Ahmed's Wedding"));
      final contribution = await contribute(
        occasionId: occasionId,
        personId: personId,
        minorUnits: 200000,
      );

      final history = (await transactions().getPersonHistory(
        personId,
      )).valueOrFail;

      // The same row, not a copy of it.
      expect(
        history.map((MoneyTransaction t) => t.id),
        contains(contribution.id),
      );
      expect(history.single.occasionId, occasionId);
      expect(history.single.kind, TransactionKind.occasionContribution);
      // `received` is negative in the 001 formula (given − received).
      expect(await balanceOf(personId), -200000);
    });

    testWidgets('editing from the person side moves the occasion total, '
        'because it is the same row (FR-010)', (_) async {
      final personId = await createPerson(unique('Ahmed'));
      final occasionId = await createOccasion(name: unique('Wedding'));
      final contribution = await contribute(
        occasionId: occasionId,
        personId: personId,
        minorUnits: 200000,
      );

      // Edited through the transactions feature — the person's own screen —
      // and then read back through the occasion.
      await transactions().editTransaction(
        transactionId: contribution.id,
        amount: Money.egp(220000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 9, 15),
      );

      final detail = (await occasions().getOccasionDetail(
        occasionId,
      )).valueOrFail;
      expect(detail.summary.totalReceived, Money.egp(220000));
      expect(await balanceOf(personId), -220000);
    });

    testWidgets('removing a contribution clears it from both views', (_) async {
      final personId = await createPerson(unique('Ahmed'));
      final occasionId = await createOccasion(name: unique('Wedding'));
      final contribution = await contribute(
        occasionId: occasionId,
        personId: personId,
        minorUnits: 200000,
      );

      await occasions().removeParticipantContribution(contribution.id);

      final detail = (await occasions().getOccasionDetail(
        occasionId,
      )).valueOrFail;
      final history = (await transactions().getPersonHistory(
        personId,
      )).valueOrFail;

      expect(detail.participants, isEmpty);
      expect(history, isEmpty);
      expect(await balanceOf(personId), 0);
    });
  });

  group('User Story 3 — totals and settlement', () {
    testWidgets('an all-given occasion reports moreGiven, and balancing it '
        'reports settled (FR-008)', (_) async {
      final occasionId = await createOccasion(name: unique("Fatma's Wedding"));
      for (final amount in [100000, 50000, 200000]) {
        await contribute(
          occasionId: occasionId,
          personId: await createPerson(unique('Guest')),
          minorUnits: amount,
          direction: TransactionDirection.given,
        );
      }

      var detail = (await occasions().getOccasionDetail(
        occasionId,
      )).valueOrFail;
      expect(detail.summary.totalGiven, Money.egp(350000));
      expect(detail.summary.totalReceived, Money.zero(Currency.egp));
      expect(detail.summary.settlementStatus, SettlementStatus.moreGiven);
      expect(detail.summary.outstanding, Money.egp(350000));

      await contribute(
        occasionId: occasionId,
        personId: await createPerson(unique('Fifth')),
        minorUnits: 350000,
      );

      detail = (await occasions().getOccasionDetail(occasionId)).valueOrFail;
      expect(detail.summary.settlementStatus, SettlementStatus.settled);
      expect(detail.summary.net, Money.zero(Currency.egp));
    });

    testWidgets('a participant row shows the person\'s whole-history status, '
        'not an occasion-only one (FR-009)', (_) async {
      final personId = await createPerson(unique('Omar'));
      // An unrelated loan outside any occasion: he owes money overall.
      await transactions().addTransaction(
        idempotencyKey: uuid.v4(),
        personId: personId,
        amount: Money.egp(500000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 1),
      );
      final occasionId = await createOccasion(name: unique('Wedding'));
      await contribute(
        occasionId: occasionId,
        personId: personId,
        minorUnits: 100000,
      );

      final detail = (await occasions().getOccasionDetail(
        occasionId,
      )).valueOrFail;

      // Occasion-scoped, he only gave the user money. Overall, he is still
      // in debt — and the row must say so.
      expect(
        detail.participants.single.personOverallStatus,
        RelationshipStatus.theyOweYou,
      );
    });
  });

  group('User Story 4 — browse, filter, archive, delete', () {
    testWidgets('filters by type and by name (FR-015)', (_) async {
      final weddingName = unique('Wedding');
      await createOccasion(name: weddingName);
      await createOccasion(
        name: unique('Sebou'),
        type: OccasionType.newbornSebou,
      );

      final byType = (await occasions().getOccasionsList(
        filter: const OccasionFilter(type: OccasionType.newbornSebou),
      )).valueOrFail;
      expect(
        byType.every((Occasion o) => o.type == OccasionType.newbornSebou),
        isTrue,
      );

      final byName = (await occasions().getOccasionsList(
        filter: OccasionFilter(nameQuery: weddingName),
      )).valueOrFail;
      expect(byName.map((Occasion o) => o.name), contains(weddingName));
    });

    testWidgets('archiving hides an occasion without touching balances '
        '(FR-014)', (_) async {
      final personId = await createPerson(unique('Ahmed'));
      final occasionId = await createOccasion(name: unique('Wedding'));
      await contribute(
        occasionId: occasionId,
        personId: personId,
        minorUnits: 200000,
      );

      await occasions().archiveOccasion(occasionId);

      final active = (await occasions().getOccasionsList()).valueOrFail;
      final withArchived = (await occasions().getOccasionsList(
        includeArchived: true,
      )).valueOrFail;

      expect(active.map((Occasion o) => o.id), isNot(contains(occasionId)));
      expect(withArchived.map((Occasion o) => o.id), contains(occasionId));
      expect(await balanceOf(personId), -200000);

      await occasions().restoreOccasion(occasionId);
      final restored = (await occasions().getOccasionsList()).valueOrFail;
      expect(restored.map((Occasion o) => o.id), contains(occasionId));
    });

    testWidgets('deleting cascades to every contribution and moves the '
        'affected person\'s balance (FR-013)', (_) async {
      final occasionId = await createOccasion(name: unique('Wedding'));
      final personIds = <String>[];
      for (var i = 0; i < 5; i++) {
        final personId = await createPerson(unique('Guest'));
        personIds.add(personId);
        await contribute(
          occasionId: occasionId,
          personId: personId,
          minorUnits: 100000,
        );
      }

      // The count the confirmation names, read before anything is deleted.
      final before = (await occasions().getOccasionDetail(
        occasionId,
      )).valueOrFail;
      expect(before.summary.participantCount, 5);
      for (final personId in personIds) {
        expect(await balanceOf(personId), -100000);
      }

      await occasions().deleteOccasion(occasionId);

      expect(
        (await occasions().getOccasionDetail(occasionId)).isLeft(),
        isTrue,
      );
      final remaining = (await transactions().getContributionsForOccasion(
        occasionId,
      )).valueOrFail;
      expect(remaining, isEmpty);
      for (final personId in personIds) {
        expect(
          await balanceOf(personId),
          0,
          reason:
              'the cascade must actually move the balance, not just '
              'hide the row from the occasion',
        );
        expect(
          (await transactions().getPersonHistory(personId)).valueOrFail,
          isEmpty,
        );
      }
    });
  });

  group('User Story 5 — attachments', () {
    testWidgets('an attachment is persisted against the occasion and '
        'soft-deleted on removal (FR-017)', (_) async {
      final occasionId = await createOccasion(name: unique('Wedding'));

      final added = (await occasions().addOccasionAttachment(
        occasionId: occasionId,
        filePath: '/tmp/daftary_test_photo.jpg',
      )).valueOrFail;

      var detail = (await occasions().getOccasionDetail(
        occasionId,
      )).valueOrFail;
      expect(
        detail.attachments.map((OccasionAttachment a) => a.id),
        contains(added.id),
      );

      await occasions().removeOccasionAttachment(added.id);

      detail = (await occasions().getOccasionDetail(occasionId)).valueOrFail;
      expect(detail.attachments, isEmpty);
    });
  });

  group('Scenario 7 — the condolence balance default (FR-018)', () {
    testWidgets('a condolence contribution shows in the occasion total but '
        'leaves the person settled', (_) async {
      final personId = await createPerson(unique('Mourner'));
      final occasionId = await createOccasion(
        name: unique('Condolence'),
        type: OccasionType.condolence,
      );
      await contribute(
        occasionId: occasionId,
        personId: personId,
        minorUnits: 50000,
      );

      final detail = (await occasions().getOccasionDetail(
        occasionId,
      )).valueOrFail;

      expect(detail.summary.totalReceived, Money.egp(50000));
      expect(detail.participants.single.countsTowardBalance, isFalse);
      expect(
        await balanceOf(personId),
        0,
        reason: 'condolence money is not a reciprocal social debt',
      );
    });

    testWidgets('an explicit override makes it count like any other '
        'exchange', (_) async {
      final personId = await createPerson(unique('Mourner'));
      final occasionId = await createOccasion(
        name: unique('Condolence'),
        type: OccasionType.condolence,
      );
      await contribute(
        occasionId: occasionId,
        personId: personId,
        minorUnits: 50000,
        countsTowardBalance: true,
      );

      expect(await balanceOf(personId), -50000);
    });

    testWidgets('changing an occasion\'s type later never moves an existing '
        'contribution\'s balance (research.md Decision 3)', (_) async {
      final personId = await createPerson(unique('Guest'));
      final occasionId = await createOccasion(name: unique('Wedding'));
      await contribute(
        occasionId: occasionId,
        personId: personId,
        minorUnits: 100000,
      );
      expect(await balanceOf(personId), -100000);

      await occasions().editOccasion(
        occasionId: occasionId,
        name: unique('Now a condolence'),
        date: DateTime(2026, 9, 15),
        type: OccasionType.condolence,
      );

      expect(
        await balanceOf(personId),
        -100000,
        reason: 'an unrelated edit must never silently move a balance',
      );
    });
  });

  group('the app boots into the occasions section', () {
    testWidgets('the occasions list renders its own screen', (tester) async {
      final l10n = await english();
      appRouter.go('/occasions');
      await tester.pumpWidget(const DaftaryApp());
      await tester.pumpAndSettle();

      expect(find.text(l10n.occasionsTitle), findsWidgets);
      expect(find.text(l10n.occasionAddAction), findsWidgets);
    });
  });
}

/// Unwraps a repository result, failing the test with the typed reason
/// rather than the "Null check operator used on a null value" a bare `!`
/// would produce three frames away from the real cause.
extension _ResultValue<T> on Either<Failure, T> {
  T get valueOrFail => getOrElse((Failure f) => fail(f.message));
}
