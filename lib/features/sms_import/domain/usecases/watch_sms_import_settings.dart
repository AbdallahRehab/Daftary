import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_import_settings.dart';
import '../repositories/sms_import_settings_repository.dart';

/// The feature settings for the screens that show them (Settings ->
/// Bank messages, the hub's scan state, the Home onboarding card). Read
/// only: every write goes through its own use case. The settings hold
/// flags, the scan window, timestamps and content-free counters, never
/// message content.
@injectable
class WatchSmsImportSettings {
  WatchSmsImportSettings(this._settings);

  final SmsImportSettingsRepository _settings;

  /// Emits now and after every change.
  Stream<Either<Failure, SmsImportSettings>> call() =>
      _settings.watchSettings();

  /// The current value, once.
  Future<Either<Failure, SmsImportSettings>> current() =>
      _settings.getSettings();
}
