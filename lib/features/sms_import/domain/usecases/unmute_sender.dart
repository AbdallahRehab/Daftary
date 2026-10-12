import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/sms_import_settings_repository.dart';

/// Lets a muted sender suggest again (FR-065). Nothing is re-created:
/// messages it sent come back only on the next scan.
@injectable
class UnmuteSender {
  UnmuteSender(this._settings);

  final SmsImportSettingsRepository _settings;

  Future<Either<Failure, Unit>> call(String senderId) =>
      _settings.unmuteSender(senderId);
}
