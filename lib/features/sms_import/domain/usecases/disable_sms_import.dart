import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/sms_import_repository.dart';
import '../repositories/sms_import_settings_repository.dart';

/// Turns bank-message import off (FR-078, domain-interfaces §5.1).
///
/// The feature is switched off FIRST, so a running scan or catch-up stops
/// at its next page check (both re-read `isEnabled` between pages). Then,
/// only when the user chose "also delete pending imports", every pending
/// item is deleted with no tombstone. Muted senders, learned categories
/// and tombstones are always kept (FR-056), and saved records are never
/// touched. Returns how many pending items were deleted (0 when kept).
///
/// When switching off fails, nothing is deleted.
@injectable
class DisableSmsImport {
  DisableSmsImport(this._settings, this._repository);

  final SmsImportSettingsRepository _settings;
  final SmsImportRepository _repository;

  Future<Either<Failure, int>> call({required bool deletePending}) async {
    final disabled = await _settings.setEnabled(false);
    if (disabled case Left(:final value)) return Left(value);
    if (!deletePending) return const Right(0);
    return _repository.deleteAllPending();
  }
}
