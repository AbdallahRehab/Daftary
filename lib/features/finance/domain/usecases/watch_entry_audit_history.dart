import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/finance_entry_audit.dart';
import '../repositories/finance_repository.dart';

/// 022 D2: the live, read-only change history of one income or expense
/// entry, oldest first — what the "Edited" marker's history sheet shows.
@injectable
class WatchEntryAuditHistory {
  const WatchEntryAuditHistory(this._repository);

  final FinanceRepository _repository;

  Stream<Either<Failure, List<FinanceEntryAudit>>> call(String entryId) =>
      _repository.watchEntryAuditHistory(entryId);
}
