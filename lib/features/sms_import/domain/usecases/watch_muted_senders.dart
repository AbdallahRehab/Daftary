import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/sms_import_settings_repository.dart';

/// The muted senders, canonical upper-case, for the settings screen
/// (FR-056, FR-065).
@injectable
class WatchMutedSenders {
  WatchMutedSenders(this._settings);

  final SmsImportSettingsRepository _settings;

  Stream<Either<Failure, Set<String>>> call() => _settings.watchMutedSenders();
}
