import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_import_enums.dart';
import '../entities/sms_permission_status.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_import_settings_repository.dart';
import 'get_sms_permission_status.dart';
import 'request_sms_permission.dart';

/// Turns the inbox import on (domain-interfaces §5.1, FR-003, FR-005).
///
/// - Precondition: the explanation screen was shown and acknowledged
///   (FR-005). Without it this returns a [ValidationFailure] and neither
///   prompts nor writes anything.
/// - A permission that is already granted is not requested again (no
///   needless system activity); otherwise `RequestSmsPermission` shows the
///   dialog once.
/// - Only `granted` saves [ScanWindow] and sets `isEnabled = true`. Every
///   other status leaves the feature off and is returned for the guidance
///   UI.
/// - It never starts the scan.
@injectable
class EnableSmsImport {
  EnableSmsImport(this._status, this._request, this._settings);

  final GetSmsPermissionStatus _status;
  final RequestSmsPermission _request;
  final SmsImportSettingsRepository _settings;

  static const Failure explanationRequired = ValidationFailure(
    'sms_import_explanation_required',
  );

  Future<Either<Failure, EnableResult>> call({
    required ScanWindow window,
    required bool explanationAcknowledged,
  }) async {
    if (!explanationAcknowledged) return const Left(explanationRequired);

    final current = await _status();
    if (current case Left(:final value)) return Left(value);
    var status = current.getOrElse((_) => SmsPermissionStatus.denied);
    if (status != SmsPermissionStatus.granted) {
      final requested = await _request();
      if (requested case Left(:final value)) return Left(value);
      status = requested.getOrElse((_) => SmsPermissionStatus.denied);
    }
    if (status != SmsPermissionStatus.granted) {
      return Right(EnableResult(status: status, enabled: false));
    }

    final windowSaved = await _settings.setScanWindow(window);
    if (windowSaved case Left(:final value)) return Left(value);
    final enabled = await _settings.setEnabled(true);
    if (enabled case Left(:final value)) return Left(value);
    return Right(EnableResult(status: status, enabled: true));
  }
}
