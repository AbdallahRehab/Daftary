import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/services/share_service.dart';
import '../../domain/usecases/export_user_data.dart';
import 'export_state.dart';

/// Drives the export screen (contracts/export_user_data.md): generating the
/// file is one explicit action, handing it to the OS share sheet is a
/// second, separate one (FR-012).
@injectable
class ExportCubit extends Cubit<ExportState> {
  ExportCubit(this._exportUserData, this._shareService)
    : super(const ExportState());

  final ExportUserData _exportUserData;
  final ShareService _shareService;

  /// idle/ready/error → generating → ready or error (FR-009, FR-011).
  /// Ignored while a generation is already running.
  Future<void> generate() async {
    if (state.status == ExportStatus.generating) return;
    emit(const ExportState(status: ExportStatus.generating));
    final result = await _exportUserData();
    if (isClosed) return;
    emit(
      result.match(
        (failure) => ExportState(
          status: ExportStatus.error,
          errorMessage: failure.message,
        ),
        (export) => ExportState(status: ExportStatus.ready, result: export),
      ),
    );
  }

  /// Re-runs [generate] from scratch after a failure (FR-011).
  Future<void> retry() => generate();

  /// Presents the OS share sheet for the generated file (FR-010). Dismissing
  /// the sheet is a success, so the screen simply stays ready (spec Edge
  /// Cases); only a sheet that could not be shown sets
  /// [ExportState.shareFailed]. Ignored unless ready and not already
  /// sharing.
  Future<void> share({String? subject}) async {
    final export = state.result;
    if (state.status != ExportStatus.ready || export == null) return;
    if (state.isSharing) return;
    emit(state.copyWith(isSharing: true, shareFailed: false));
    final result = await _shareService.shareFile(
      filePath: export.filePath,
      subject: subject,
    );
    if (isClosed) return;
    emit(state.copyWith(isSharing: false, shareFailed: result.isLeft()));
  }
}
