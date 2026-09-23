import 'package:equatable/equatable.dart';

import '../../domain/entities/export_result.dart';

/// Where the export screen is in its one-way flow: explain → generate →
/// share (FR-009–FR-011).
enum ExportStatus { idle, generating, ready, error }

/// Immutable state for `ExportCubit` (constitution Principle IV).
class ExportState extends Equatable {
  const ExportState({
    this.status = ExportStatus.idle,
    this.result,
    this.isSharing = false,
    this.shareFailed = false,
    this.errorMessage,
  });

  final ExportStatus status;

  /// The generated file, present once [status] is [ExportStatus.ready].
  final ExportResult? result;

  /// The OS share sheet is being presented — guards against a double tap
  /// opening it twice.
  final bool isSharing;

  /// The last attempt to present the share sheet failed. The export itself
  /// is still [ExportStatus.ready]; the file is untouched and sharing can
  /// simply be tried again.
  final bool shareFailed;

  /// The failure's message once [status] is [ExportStatus.error].
  /// Diagnostic only — the page shows localized copy, never this string.
  final String? errorMessage;

  /// Nullable fields keep their current value unless replaced or explicitly
  /// cleared with the matching `clear*` flag.
  ExportState copyWith({
    ExportStatus? status,
    ExportResult? result,
    bool clearResult = false,
    bool? isSharing,
    bool? shareFailed,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ExportState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      isSharing: isSharing ?? this.isSharing,
      shareFailed: shareFailed ?? this.shareFailed,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    result,
    isSharing,
    shareFailed,
    errorMessage,
  ];
}
