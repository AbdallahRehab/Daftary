import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_import_failures.dart';
import '../entities/sms_permission_status.dart';
import '../repositories/sms_import_settings_repository.dart';
import '../services/external_activity_runner.dart';
import '../services/sms_permission_service.dart';
import 'get_sms_capability.dart';

/// Shows the system READ_SMS dialog (domain-interfaces §5.1, FR-002,
/// FR-069). **The only caller of `SmsPermissionService.request()`**; it is
/// itself called only by `EnableSmsImport`, after the explanation was
/// acknowledged (FR-005).
///
/// 1. Refuses without the capability (`SmsCapabilityUnavailableFailure`):
///    no dialog, nothing persisted.
/// 2. Reads the persisted `permissionRequested` flag, then persists it
///    BEFORE the dialog, so the request is recorded even if the app is
///    killed while the dialog is up. A failed read or write stops here: the
///    dialog is never shown unrecorded. The value read first is passed to
///    the platform as `previouslyRequested`, so a first request is never
///    classified as `permanentlyDenied` (phase6b decision).
/// 3. Runs the request inside [ExternalActivityRunner], so App Lock does
///    not treat the dialog as leaving the app.
@injectable
class RequestSmsPermission {
  RequestSmsPermission(
    this._capability,
    this._permissions,
    this._settings,
    this._runner,
  );

  final GetSmsCapability _capability;
  final SmsPermissionService _permissions;
  final SmsImportSettingsRepository _settings;
  final ExternalActivityRunner _runner;

  Future<Either<Failure, SmsPermissionStatus>> call() async {
    final capability = await _capability();
    if (!capability.available) {
      return const Left(SmsCapabilityUnavailableFailure());
    }
    final before = await _settings.getSettings();
    if (before case Left(:final value)) return Left(value);
    final previouslyRequested = before
        .map((settings) => settings.permissionRequested)
        .getOrElse((_) => false);
    final marked = await _settings.markPermissionRequested();
    if (marked case Left(:final value)) return Left(value);
    return _runner.run(
      () => _permissions.request(previouslyRequested: previouslyRequested),
    );
  }
}
