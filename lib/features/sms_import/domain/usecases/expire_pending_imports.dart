import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../repositories/sms_import_repository.dart';

/// Expires pending items older than 30 days, then purges decided rows past
/// their 30 days and tombstones past `purge_after` (FR-025, FR-066,
/// FR-067). Idempotent; run on opening the pending list, after every scan
/// and after unlock at app start. Returns how many items expired now.
@injectable
class ExpirePendingImports {
  ExpirePendingImports(this._repository, this._clock);

  final SmsImportRepository _repository;
  final AppClock _clock;

  Future<Either<Failure, int>> call({DateTime? now}) async {
    final at = now ?? _clock.now();
    final expired = await _repository.expireDue(at);
    return switch (expired) {
      Left() => expired,
      Right(:final value) => (await _repository.purgeDecided(
        at,
      )).map((_) => value),
    };
  }
}
