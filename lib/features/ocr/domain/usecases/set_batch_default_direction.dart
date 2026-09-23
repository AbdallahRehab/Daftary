import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../entities/ocr_scan.dart';
import '../repositories/ocr_repository.dart';

/// Sets the direction that applies to every entry in the batch that has not
/// been given one of its own (FR-005) — the common case, since a plain list
/// of names and amounts rarely says which way the money went.
///
/// Never overwrites an entry's own direction: a user who corrected one row
/// and then set the batch default should not find their correction undone.
@injectable
class SetBatchDefaultDirection {
  const SetBatchDefaultDirection(this._repository);

  final OcrRepository _repository;

  Future<Either<Failure, OcrScan>> call({
    required String scanId,
    required TransactionDirection direction,
  }) {
    return _repository.setBatchDefaultDirection(
      scanId: scanId,
      direction: direction,
    );
  }
}
