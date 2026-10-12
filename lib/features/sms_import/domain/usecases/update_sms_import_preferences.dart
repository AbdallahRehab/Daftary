import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_import_settings_repository.dart';

/// The settings writes the UI can make (domain-interfaces §5.1): the scan
/// window (FR-006), the cash-withdrawal toggle (FR-051b) and the permanent
/// dismissal of the Home onboarding card (FR-004). Thin, so cubits depend
/// on use cases only.
@injectable
class UpdateSmsImportPreferences {
  UpdateSmsImportPreferences(this._settings);

  final SmsImportSettingsRepository _settings;

  Future<Either<Failure, Unit>> call(SmsPreferenceChange change) =>
      switch (change) {
        ScanWindowChanged(:final window) => _settings.setScanWindow(window),
        CountCashChanged(:final countCashWithdrawals) =>
          _settings.setCountCashWithdrawals(countCashWithdrawals),
        OnboardingDismissed() => _settings.dismissOnboarding(),
      };
}
