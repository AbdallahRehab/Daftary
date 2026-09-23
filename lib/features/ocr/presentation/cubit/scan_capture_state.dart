import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

/// Where the capture step is (009 FR-001/FR-016).
///
/// [unsupportedDevice] is deliberately terminal: it is reached only when
/// the device cannot do on-device preparation or recognition at all, and
/// the only honest next step is manual entry — never a retry that can
/// never work (spec Edge Cases, T060).
enum ScanCaptureStatus {
  idle,
  checkingAvailability,
  picking,
  picked,
  permissionDenied,
  unsupportedDevice,
  failure,
}

/// Immutable state for `ScanCaptureCubit` (constitution Principle IV —
/// replaced exclusively through [copyWith]).
class ScanCaptureState extends Equatable {
  const ScanCaptureState({
    this.status = ScanCaptureStatus.idle,
    this.imagePath,
    this.failure,
  });

  final ScanCaptureStatus status;

  /// The app-owned copy of the captured or picked image, set only in
  /// [ScanCaptureStatus.picked]. Always a local sandboxed path — the bytes
  /// never leave the device (FR-019).
  final String? imagePath;

  /// The typed failure behind [ScanCaptureStatus.permissionDenied] or
  /// [ScanCaptureStatus.failure]. Never a `PickerCancelledFailure`: backing
  /// out of the camera is a normal outcome and returns the screen silently
  /// to [ScanCaptureStatus.idle] instead.
  final Failure? failure;

  bool get isBusy =>
      status == ScanCaptureStatus.picking ||
      status == ScanCaptureStatus.checkingAvailability;
  bool get isPicked => status == ScanCaptureStatus.picked;
  bool get isUnsupported => status == ScanCaptureStatus.unsupportedDevice;
  bool get isPermissionDenied => status == ScanCaptureStatus.permissionDenied;

  ScanCaptureState copyWith({
    ScanCaptureStatus? status,
    String? imagePath,
    bool clearImagePath = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ScanCaptureState(
      status: status ?? this.status,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, imagePath, failure];
}
