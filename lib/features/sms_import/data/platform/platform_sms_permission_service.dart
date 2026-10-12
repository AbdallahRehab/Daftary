import 'package:app_settings/app_settings.dart' as app_settings;
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sms_import_failures.dart';
import '../../domain/entities/sms_import_settings.dart';
import '../../domain/entities/sms_permission_status.dart';
import '../../domain/repositories/sms_import_settings_repository.dart';
import '../../domain/rules/classify_sms_permission.dart';
import '../../domain/services/sms_inbox_gateway.dart';
import '../../domain/services/sms_permission_service.dart';
import 'sms_channel_client.dart';

/// Opens this app's system App info screen.
typedef OpenAppInfoScreen = Future<void> Function();

/// The Android READ_SMS port (sms-platform-channel §2.2, §2.3, §2.7, §6).
/// The plugin reports facts; the status is decided here by the pure
/// `classifySmsPermission`.
///
/// - Every method short-circuits when READ_SMS is not declared (read
///   through [SmsInboxGateway.getCapability]): the status is
///   [SmsPermissionStatus.unavailable] and no permission call is made
///   (invariant 5).
/// - [getStatus] never prompts. Its `previouslyRequested` is the persisted
///   `permissionRequested`, and its `previouslyGranted` is `isEnabled`
///   (the import is only switched on after a grant), so a permission
///   turned off in system settings reads as
///   [SmsPermissionStatus.revoked]. No dialog is involved, so restricted
///   settings are never inferred here.
/// - The prompting call takes `previouslyRequested` from its only caller,
///   `RequestSmsPermission`, which reads the flag before persisting it.
///   Concurrent calls share one platform request (single flight, §3
///   `request_in_progress`).
/// - [openAppInfo] uses `app_settings` (default type: this app's details
///   screen). Imported with a prefix because its `AppSettings` collides
///   with the Drift table class.
///
/// Nothing is logged; failures are fixed tokens. No injectable
/// annotation: `SmsPlatformModule` chooses it, on Android only.
class PlatformSmsPermissionService implements SmsPermissionService {
  PlatformSmsPermissionService(
    this._channel,
    this._gateway,
    this._settings, {
    OpenAppInfoScreen? openAppInfoScreen,
  }) : _openAppInfoScreen =
           openAppInfoScreen ?? app_settings.AppSettings.openAppSettings;

  final SmsChannelClient _channel;
  final SmsInboxGateway _gateway;
  final SmsImportSettingsRepository _settings;
  final OpenAppInfoScreen _openAppInfoScreen;
  Future<Either<Failure, SmsPermissionStatus>>? _inFlight;

  /// Fixed token for an App info screen that could not be opened.
  static const Failure appInfoUnavailable = UnknownFailure(
    'sms_app_info_unavailable',
  );

  Future<bool> get _declared async =>
      (await _gateway.getCapability()).available;

  @override
  Future<Either<Failure, SmsPermissionStatus>> getStatus() async {
    if (!await _declared) return const Right(SmsPermissionStatus.unavailable);
    final reply = await _channel.getPermissionState();
    if (reply case Left(:final value)) return _failure(value);
    final map = reply.getOrElse((_) => const {});
    final granted = map['granted'];
    final rationale = map['shouldShowRationale'];
    if (granted is! bool || rationale is! bool) {
      return Left(SmsChannelErrorCode.malformedReply.failure);
    }
    final stored = (await _settings.getSettings()).getOrElse(
      (_) => const SmsImportSettings(),
    );
    return Right(
      classifySmsPermission(
        SmsPermissionResult(
          granted: granted,
          shouldShowRationale: rationale,
          // No request, so no dialog to miss: restricted settings are
          // only inferred from a request's result.
          dialogShown: true,
          sdkInt: 0,
          installSource: SmsInstallSource.unknown,
        ),
        previouslyRequested: stored.permissionRequested,
        previouslyGranted: stored.isEnabled,
      ),
    );
  }

  @override
  Future<Either<Failure, SmsPermissionStatus>> request({
    required bool previouslyRequested,
  }) {
    final running = _inFlight;
    if (running != null) return running;
    final started = _prompt(previouslyRequested);
    _inFlight = started;
    return started.whenComplete(() => _inFlight = null);
  }

  Future<Either<Failure, SmsPermissionStatus>> _prompt(
    bool previouslyRequested,
  ) async {
    if (!await _declared) return const Right(SmsPermissionStatus.unavailable);
    final reply = await _channel.requestPermission();
    if (reply case Left(:final value)) return _failure(value);
    final map = reply.getOrElse((_) => const {});
    final granted = map['granted'];
    final rationale = map['shouldShowRationale'];
    final dialogShown = map['dialogShown'];
    final sdkInt = map['sdkInt'];
    if (granted is! bool ||
        rationale is! bool ||
        dialogShown is! bool ||
        sdkInt is! int) {
      return Left(SmsChannelErrorCode.malformedReply.failure);
    }
    final installSource = map['installSource'];
    return Right(
      classifySmsPermission(
        SmsPermissionResult(
          granted: granted,
          shouldShowRationale: rationale,
          dialogShown: dialogShown,
          sdkInt: sdkInt,
          installSource: SmsInstallSource.fromWire(
            installSource is String ? installSource : null,
          ),
        ),
        previouslyRequested: previouslyRequested,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> openAppInfo() async {
    if (!await _declared) return const Right(unit);
    try {
      await _openAppInfoScreen();
      return const Right(unit);
    } on Exception {
      // Never e.toString(): a fixed token only.
      return const Left(appInfoUnavailable);
    }
  }

  /// A channel `unavailable` is the same answer as the short-circuit.
  static Either<Failure, SmsPermissionStatus> _failure(Failure failure) =>
      failure is SmsCapabilityUnavailableFailure
      ? const Right(SmsPermissionStatus.unavailable)
      : Left(failure);

  @override
  String toString() => 'PlatformSmsPermissionService()';
}
