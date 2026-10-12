import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/pending_sms_import.dart';
import '../repositories/sms_import_repository.dart';

/// The Undo list: items ignored or expired in the last 30 days, newest
/// decision first (FR-067). Each carries only the six fields kept for it
/// (amount, currency, date, merchant or counterparty, bank, kind).
@injectable
class WatchUndoList {
  WatchUndoList(this._repository);

  final SmsImportRepository _repository;

  Stream<Either<Failure, List<PendingSmsImport>>> call() =>
      _repository.watchUndoList();
}
