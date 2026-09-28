import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../currency/domain/entities/conversion_result.dart';
import '../../../currency/domain/services/currency_converter.dart';
import '../../../currency/domain/usecases/get_conversion_context.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/entities/person_balance.dart';
import '../../../transactions/domain/repositories/transactions_repository.dart';
import '../../domain/entities/occasion.dart';
import '../../domain/entities/occasion_attachment.dart';
import '../../domain/entities/occasion_detail.dart';
import '../../domain/entities/occasion_failures.dart';
import '../../domain/entities/occasion_filter.dart';
import '../../domain/entities/occasion_participant_row.dart';
import '../../domain/entities/occasion_summary.dart';
import '../../domain/entities/occasion_type.dart';
import '../../domain/repositories/occasions_repository.dart';
import '../datasources/occasions_dao.dart';
import '../models/occasion_mapper.dart';

/// Carries a delegated [Failure] out of a `_db.transaction` body so the
/// whole DB transaction rolls back: a cascade that deleted half an
/// occasion's contributions and then gave up would leave exactly the
/// dangling state FR-013 forbids.
class _CascadeAbort implements Exception {
  const _CascadeAbort(this.failure);

  final Failure failure;
}

@LazySingleton(as: OccasionsRepository)
class OccasionsRepositoryImpl implements OccasionsRepository {
  OccasionsRepositoryImpl(
    this._dao,
    this._transactionsRepository,
    this._peopleRepository,
    this._db,
    this._getConversionContext,
    this._converter,
  );

  final OccasionsDao _dao;
  final TransactionsRepository _transactionsRepository;
  final PeopleRepository _peopleRepository;
  final db.AppDatabase _db;

  /// 018: an occasion's totals are converted into the primary currency,
  /// since its contributions may be in several.
  final GetConversionContext _getConversionContext;
  final CurrencyConverter _converter;
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, Occasion>> createOccasion({
    required String idempotencyKey,
    required String name,
    required DateTime date,
    required String type,
    String? notes,
  }) async {
    final trimmedName = name.trim();
    final trimmedType = type.trim();
    final validation = _validateNameAndType(trimmedName, trimmedType);
    if (validation != null) return Left(validation);
    try {
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final companion = db.OccasionsCompanion.insert(
        id: _uuid.v4(),
        idempotencyKey: idempotencyKey,
        name: trimmedName,
        date: occasionDateOnlyMillis(date),
        type: trimmedType,
        notes: db.Value(notes),
        createdAt: nowMillis,
        updatedAt: nowMillis,
      );
      final row = await _dao.insertOccasionIdempotent(companion);
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to create occasion: $e'));
    }
  }

  @override
  Future<Either<Failure, Occasion>> editOccasion({
    required String occasionId,
    required String name,
    required DateTime date,
    required String type,
    String? notes,
  }) async {
    final trimmedName = name.trim();
    final trimmedType = type.trim();
    final validation = _validateNameAndType(trimmedName, trimmedType);
    if (validation != null) return Left(validation);
    try {
      final existing = await _activeOccasionOrNull(occasionId);
      if (existing == null) {
        return const Left(OccasionNotFoundFailure('Occasion not found'));
      }
      // Deliberately writes only the occasion's own fields: a type change
      // to or from `condolence` must never retroactively move an already
      // recorded contribution's `countsTowardBalance`, which would silently
      // change someone's balance (research.md Decision 3).
      final updated = await _dao.updateOccasion(
        occasionId,
        db.OccasionsCompanion(
          name: db.Value(trimmedName),
          date: db.Value(occasionDateOnlyMillis(date)),
          type: db.Value(trimmedType),
          notes: db.Value(notes),
          updatedAt: db.Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      return Right(updated.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to edit occasion: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> archiveOccasion(String occasionId) =>
      _setArchived(occasionId, true, 'Failed to archive occasion');

  @override
  Future<Either<Failure, Unit>> restoreOccasion(String occasionId) =>
      _setArchived(occasionId, false, 'Failed to restore occasion');

  @override
  Future<Either<Failure, Unit>> deleteOccasion(String occasionId) async {
    try {
      final existing = await _activeOccasionOrNull(occasionId);
      if (existing == null) {
        return const Left(OccasionNotFoundFailure('Occasion not found'));
      }
      final contributions = await _transactionsRepository
          .getContributionsForOccasion(occasionId);
      final rows = contributions.getOrElse((_) => const []);
      final loadFailure = contributions.getLeft().toNullable();
      if (loadFailure != null) return Left(loadFailure);

      await _db.transaction(() async {
        for (final row in rows) {
          final deleted = await _transactionsRepository.deleteTransaction(
            row.id,
          );
          final failure = deleted.getLeft().toNullable();
          if (failure != null) throw _CascadeAbort(failure);
        }
        await _dao.softDeleteOccasion(occasionId, DateTime.now());
      });
      return const Right(unit);
    } on _CascadeAbort catch (abort) {
      return Left(abort.failure);
    } catch (e) {
      return Left(CacheFailure('Failed to delete occasion: $e'));
    }
  }

  @override
  Future<Either<Failure, MoneyTransaction>> addParticipantContribution({
    required String idempotencyKey,
    required String occasionId,
    required String personId,
    required Money amount,
    required TransactionDirection direction,
    required DateTime date,
    bool? countsTowardBalance,
    String? note,
    String? ocrScanId,
  }) async {
    if (!amount.isPositive) {
      return const Left(ValidationFailure('Amount must be greater than zero'));
    }
    final db.Occasion? occasion;
    try {
      occasion = await _activeOccasionOrNull(occasionId);
    } catch (e) {
      return Left(CacheFailure('Failed to load occasion: $e'));
    }
    if (occasion == null) {
      return const Left(OccasionNotFoundFailure('Occasion not found'));
    }
    // FR-018: condolence money is not a reciprocal social debt in Egyptian
    // custom, so it defaults to not counting — but only as a default the
    // caller can override, never as a rule imposed on their entry.
    final counts =
        countsTowardBalance ?? occasion.type != OccasionType.condolence;
    // Delegated rather than inserted here: the contribution must be the
    // very same `money_transactions` row the person's own profile edits
    // (FR-005/FR-010), audit entry and idempotency included.
    return _transactionsRepository.addOccasionContribution(
      idempotencyKey: idempotencyKey,
      personId: personId,
      occasionId: occasionId,
      amount: amount,
      direction: direction,
      countsTowardBalance: counts,
      date: date,
      note: note,
      ocrScanId: ocrScanId,
    );
  }

  @override
  Future<Either<Failure, MoneyTransaction>> editParticipantContribution({
    required String transactionId,
    required Money amount,
    required TransactionDirection direction,
    required DateTime date,
    String? note,
  }) async {
    final result = await _transactionsRepository.editTransaction(
      transactionId: transactionId,
      amount: amount,
      direction: direction,
      date: date,
      note: note,
    );
    return result.mapLeft(_asParticipantFailure);
  }

  @override
  Future<Either<Failure, Unit>> removeParticipantContribution(
    String transactionId,
  ) async {
    final result = await _transactionsRepository.deleteTransaction(
      transactionId,
    );
    return result.mapLeft(_asParticipantFailure);
  }

  @override
  Future<Either<Failure, OccasionDetail>> getOccasionDetail(
    String occasionId,
  ) async {
    try {
      final occasionRow = await _activeOccasionOrNull(occasionId);
      if (occasionRow == null) {
        return const Left(OccasionNotFoundFailure('Occasion not found'));
      }
      final contributions = await _transactionsRepository
          .getContributionsForOccasion(occasionId);
      final loadFailure = contributions.getLeft().toNullable();
      if (loadFailure != null) return Left(loadFailure);
      final rows = contributions.getOrElse((_) => const []);

      final contextResult = await _getConversionContext();
      final contextFailure = contextResult.getLeft().toNullable();
      if (contextFailure != null) return Left(contextFailure);
      final context = contextResult.toNullable()!;
      SumResult sumOf(TransactionDirection direction) =>
          _converter.sumToTargetCurrency(
            amounts: [
              for (final row in rows)
                if (row.direction == direction) row.amount,
            ],
            targetCurrency: context.primary,
            rates: context.rates,
          );
      final received = sumOf(TransactionDirection.received);
      final given = sumOf(TransactionDirection.given);
      final personIds = rows.map((row) => row.personId).toSet();
      final names = <String, String>{};
      final statuses = <String, RelationshipStatus?>{};
      // Looked up once per distinct person rather than once per row: a
      // person may appear several times (an initial gift plus a top-up),
      // and their overall status is the same answer every time.
      for (final personId in personIds) {
        final person = await _peopleRepository.getPersonById(personId);
        names[personId] = person
            .map((p) => p.name)
            .getOrElse((_) => '')
            .toString();
        final balance = await _transactionsRepository.getPersonBalance(
          personId,
        );
        statuses[personId] = balance.match((_) => null, (b) => b.status);
      }

      final participants = [
        for (final row in rows)
          OccasionParticipantRow(
            transactionId: row.id,
            personId: row.personId,
            personName: names[row.personId] ?? '',
            amount: row.amount,
            direction: row.direction,
            countsTowardBalance: row.countsTowardBalance,
            // FR-009: the person's whole-history status, never an
            // occasion-scoped one — the two views must never disagree.
            personOverallStatus: statuses[row.personId],
            note: row.note,
          ),
      ];
      final attachments = await _dao.getAttachmentsForOccasion(occasionId);

      return Right(
        OccasionDetail(
          occasion: occasionRow.toDomain(),
          summary: switch ((received, given)) {
            (SumTotal(value: final received), SumTotal(value: final given)) =>
              OccasionSummary(
                occasionId: occasionId,
                totalReceived: received,
                totalGiven: given,
                participantCount: personIds.length,
              ),
            _ => OccasionSummary.blocked(
              occasionId: occasionId,
              participantCount: personIds.length,
              currency: context.primary,
              missingRatesFor: {
                if (received case SumBlocked(:final missingRatesFor))
                  ...missingRatesFor,
                if (given case SumBlocked(:final missingRatesFor))
                  ...missingRatesFor,
              }.toList(),
            ),
          },
          participants: participants,
          attachments: attachments.map((row) => row.toDomain()).toList(),
        ),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to load occasion detail: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Occasion>>> getOccasionsList({
    OccasionFilter? filter,
    bool includeArchived = false,
  }) async {
    try {
      final fromDate = filter?.fromDate;
      final toDate = filter?.toDate;
      final rows = await _dao.getOccasions(
        nameQuery: filter?.nameQuery,
        type: filter?.type,
        fromDateMillis: fromDate == null
            ? null
            : occasionDateOnlyMillis(fromDate),
        toDateMillis: toDate == null ? null : occasionDateOnlyMillis(toDate),
        includeArchived: includeArchived,
      );
      return Right(rows.map((row) => row.toDomain()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to load occasions: $e'));
    }
  }

  @override
  Future<Either<Failure, OccasionAttachment>> addOccasionAttachment({
    required String occasionId,
    required String filePath,
  }) async {
    if (filePath.trim().isEmpty) {
      return const Left(ValidationFailure('An attachment path is required'));
    }
    try {
      final occasion = await _activeOccasionOrNull(occasionId);
      if (occasion == null) {
        return const Left(OccasionNotFoundFailure('Occasion not found'));
      }
      final row = await _dao.insertAttachment(
        db.OccasionAttachmentsCompanion.insert(
          id: _uuid.v4(),
          occasionId: occasionId,
          filePath: filePath,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to add attachment: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeOccasionAttachment(
    String attachmentId,
  ) async {
    try {
      final existing = await _dao.getAttachmentById(attachmentId);
      if (existing == null || existing.deletedAt != null) {
        return const Left(NotFoundFailure('Attachment not found'));
      }
      await _dao.softDeleteAttachment(attachmentId, DateTime.now());
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to remove attachment: $e'));
    }
  }

  Future<Either<Failure, Unit>> _setArchived(
    String occasionId,
    bool isArchived,
    String errorPrefix,
  ) async {
    try {
      final existing = await _activeOccasionOrNull(occasionId);
      if (existing == null) {
        return const Left(OccasionNotFoundFailure('Occasion not found'));
      }
      await _dao.setArchived(occasionId, isArchived, DateTime.now());
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('$errorPrefix: $e'));
    }
  }

  /// A soft-deleted occasion is indistinguishable from one that never
  /// existed for every caller here — none of them may resurrect it.
  Future<db.Occasion?> _activeOccasionOrNull(String occasionId) async {
    final row = await _dao.getById(occasionId);
    if (row == null || row.deletedAt != null) return null;
    return row;
  }

  ValidationFailure? _validateNameAndType(String name, String type) {
    if (name.isEmpty) {
      return const ValidationFailure('Occasion name is required');
    }
    if (type.isEmpty) {
      return const ValidationFailure('Occasion type is required');
    }
    return null;
  }

  /// The delegated transactions call cannot know the row it was asked about
  /// is being read as an occasion participant, so the more specific message
  /// is applied here (FR-010: the same row is editable from both screens).
  Failure _asParticipantFailure(Failure failure) => failure is NotFoundFailure
      ? const ParticipantNotFoundFailure('Participant contribution not found')
      : failure;
}
