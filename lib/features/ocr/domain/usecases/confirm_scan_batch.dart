import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../repositories/ocr_repository.dart';

/// **The one place scan data can become money** (constitution Principle X,
/// FR-007).
///
/// Everything else in this feature produces suggestions. This use case, and
/// only this use case, turns confirmed suggestions into `MoneyTransaction`
/// rows — and it does so by delegating to the very same repository methods
/// manual entry uses, never by writing a row itself.
///
/// Three properties are worth stating because they are what make the gate
/// real rather than nominal:
///
/// * It acts only on entries the user explicitly confirmed on the review
///   screen. There is no confidence level, however high, that promotes an
///   entry on its own, and no timer or background path that calls this.
/// * It is all-or-nothing. If any non-discarded entry is incomplete, it
///   creates nothing and says which entries are the problem (FR-011) —
///   a half-saved batch would leave the user unable to tell what was
///   recorded.
/// * A retried call with the same [idempotencyKey] returns the first
///   call's result instead of a second batch, so a double-tapped confirm
///   cannot double-save (FR-021, SC-006).
@injectable
class ConfirmScanBatch {
  const ConfirmScanBatch(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, List<MoneyTransaction>>> call({
    required String idempotencyKey,
    required String scanId,
  }) {
    return _repository.confirmScanBatch(
      idempotencyKey: idempotencyKey,
      scanId: scanId,
    );
  }
}
