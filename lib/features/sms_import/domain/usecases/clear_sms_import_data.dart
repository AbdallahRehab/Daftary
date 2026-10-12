import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_import_repository.dart';
import '../repositories/sms_import_settings_repository.dart';

/// Clears one kind of bank-message data (domain-interfaces §5.4):
///
/// - [ClearScope.pending]: every pending item, with no tombstone (the
///   disable flow, FR-078);
/// - [ClearScope.learnedMappings]: "Clear learned categories" (FR-056);
/// - [ClearScope.mutedSenders]: every mute (FR-056).
///
/// Tombstones are never cleared here: they are what stops a decided
/// message from coming back. A full wipe is Delete all data. Saved records
/// are never touched.
@injectable
class ClearSmsImportData {
  ClearSmsImportData(this._repository, this._settings);

  final SmsImportRepository _repository;
  final SmsImportSettingsRepository _settings;

  Future<Either<Failure, Unit>> call(ClearScope scope) async {
    switch (scope) {
      case ClearScope.pending:
        return (await _repository.deleteAllPending()).map((_) => unit);
      case ClearScope.learnedMappings:
        return _settings.clearMappings();
      case ClearScope.mutedSenders:
        final muted = await _settings.watchMutedSenders().first;
        if (muted case Left(:final value)) return Left(value);
        for (final sender in muted.getOrElse((_) => const {})) {
          final removed = await _settings.unmuteSender(sender);
          if (removed case Left(:final value)) return Left(value);
        }
        return const Right(unit);
    }
  }
}
