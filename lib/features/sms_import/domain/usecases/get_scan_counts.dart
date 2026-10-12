import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_import_settings_repository.dart';

/// The content-free counters (FR-102): scanned, recognized, added,
/// ignored. Counts only, never content.
@injectable
class GetScanCounts {
  GetScanCounts(this._settings);

  final SmsImportSettingsRepository _settings;

  Future<Either<Failure, SmsImportCounts>> call() async {
    final settings = await _settings.getSettings();
    return settings.map(
      (s) => SmsImportCounts(
        scanned: s.scannedCount,
        recognized: s.recognizedCount,
        added: s.addedCount,
        ignored: s.ignoredCount,
      ),
    );
  }
}
