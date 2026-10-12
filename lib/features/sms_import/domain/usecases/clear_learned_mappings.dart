import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/sms_import_settings_repository.dart';

/// "Clear learned categories" (FR-056): forgets every learned merchant ->
/// category mapping. Categories, saved records, mutes and tombstones are
/// never touched. The UI confirms first.
@injectable
class ClearLearnedMappings {
  ClearLearnedMappings(this._settings);

  final SmsImportSettingsRepository _settings;

  Future<Either<Failure, Unit>> call() => _settings.clearMappings();
}
