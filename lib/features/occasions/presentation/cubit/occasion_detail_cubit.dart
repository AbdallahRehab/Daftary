import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/media/attachment_picker_service.dart';
import '../../domain/usecases/add_occasion_attachment.dart';
import '../../domain/usecases/archive_occasion.dart';
import '../../domain/usecases/delete_occasion.dart';
import '../../domain/usecases/get_occasion_detail.dart';
import '../../domain/usecases/remove_occasion_attachment.dart';
import '../../domain/usecases/remove_participant_contribution.dart';
import '../../domain/usecases/restore_occasion.dart';
import 'occasion_detail_state.dart';

/// Drives the occasion detail screen: totals, settlement, participant rows,
/// attachments, and the occasion-level archive/restore/delete actions.
///
/// Every mutation ends in a [load], rather than patching the in-memory list,
/// because the totals are a SQL aggregate over the same rows — recomputing
/// them from the source is what makes FR-007's "recalculated immediately"
/// true rather than approximately true.
@injectable
class OccasionDetailCubit extends Cubit<OccasionDetailState> {
  OccasionDetailCubit(
    this._getOccasionDetail,
    this._removeParticipantContribution,
    this._addOccasionAttachment,
    this._removeOccasionAttachment,
    this._archiveOccasion,
    this._restoreOccasion,
    this._deleteOccasion,
    this._pickerService,
  ) : super(const OccasionDetailState(occasionId: ''));

  final GetOccasionDetail _getOccasionDetail;
  final RemoveParticipantContribution _removeParticipantContribution;
  final AddOccasionAttachment _addOccasionAttachment;
  final RemoveOccasionAttachment _removeOccasionAttachment;
  final ArchiveOccasion _archiveOccasion;
  final RestoreOccasion _restoreOccasion;
  final DeleteOccasion _deleteOccasion;
  final AttachmentPickerService _pickerService;

  /// Loads [occasionId]. Call once when the page opens; later refreshes go
  /// through [reload], which keeps the id already in state.
  Future<void> load(String occasionId) {
    emit(
      OccasionDetailState(
        occasionId: occasionId,
        status: OccasionDetailStatus.loading,
      ),
    );
    return reload();
  }

  Future<void> reload() async {
    final result = await _getOccasionDetail(state.occasionId);
    if (isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(status: OccasionDetailStatus.failure, failure: failure),
      ),
      (detail) => emit(
        state.copyWith(
          status: OccasionDetailStatus.success,
          detail: detail,
          clearFailure: true,
        ),
      ),
    );
  }

  /// Removes one participant's contribution after the page has confirmed it
  /// (FR-011). The same row disappears from that person's own history too,
  /// because it is the same row.
  Future<bool> removeParticipant(String transactionId) async {
    final result = await _removeParticipantContribution(transactionId);
    if (isClosed) return false;

    return result.match(
      (failure) {
        emit(state.copyWith(failure: failure));
        return false;
      },
      (_) {
        reload();
        return true;
      },
    );
  }

  Future<void> attachFromCamera() => _attach(_pickerService.pickFromCamera);

  Future<void> attachFromGallery() => _attach(_pickerService.pickFromGallery);

  Future<void> _attach(Future<Either<Failure, String>> Function() pick) async {
    if (state.isAttachmentBusy) return;
    emit(
      state.copyWith(
        attachmentStatus: AttachmentStatus.picking,
        clearAttachmentFailure: true,
      ),
    );

    final picked = await pick();
    if (isClosed) return;

    await picked.match(
      (failure) async {
        // A cancellation is a normal outcome, not an error: the UI returns
        // to idle silently rather than apologizing for something the user
        // chose to do.
        emit(
          state.copyWith(
            attachmentStatus: AttachmentStatus.idle,
            attachmentFailure: failure is PickerCancelledFailure
                ? null
                : failure,
          ),
        );
      },
      (filePath) async {
        emit(state.copyWith(attachmentStatus: AttachmentStatus.saving));
        final saved = await _addOccasionAttachment(
          occasionId: state.occasionId,
          filePath: filePath,
        );
        if (isClosed) return;

        await saved.match(
          (failure) async => emit(
            state.copyWith(
              attachmentStatus: AttachmentStatus.idle,
              attachmentFailure: failure,
            ),
          ),
          (_) async {
            await reload();
            if (!isClosed) {
              emit(state.copyWith(attachmentStatus: AttachmentStatus.idle));
            }
          },
        );
      },
    );
  }

  /// Removes an attachment after the page has confirmed it (FR-017).
  Future<bool> removeAttachment(String attachmentId) async {
    final result = await _removeOccasionAttachment(attachmentId);
    if (isClosed) return false;

    return result.match(
      (failure) {
        emit(state.copyWith(attachmentFailure: failure));
        return false;
      },
      (_) {
        reload();
        return true;
      },
    );
  }

  /// Hides the occasion from the default list, leaving its contributions —
  /// and therefore everyone's balances — untouched (FR-014).
  Future<bool> archive() =>
      _occasionAction(() => _archiveOccasion(state.occasionId));

  Future<bool> restore() =>
      _occasionAction(() => _restoreOccasion(state.occasionId));

  /// Deletes the occasion and cascades to its contributions (FR-013). The
  /// page must already have confirmed, naming
  /// [OccasionDetailState.participantCount].
  Future<bool> delete() async {
    final result = await _deleteOccasion(state.occasionId);
    if (isClosed) return false;

    return result.match(
      (failure) {
        emit(state.copyWith(failure: failure));
        return false;
      },
      (_) {
        emit(state.copyWith(isDeleted: true));
        return true;
      },
    );
  }

  Future<bool> _occasionAction(
    Future<Either<Failure, Unit>> Function() action,
  ) async {
    final result = await action();
    if (isClosed) return false;

    return result.match(
      (failure) {
        emit(state.copyWith(failure: failure));
        return false;
      },
      (_) {
        reload();
        return true;
      },
    );
  }

  /// Clears a surfaced attachment error once the page has shown it, so it
  /// is explained once rather than on every rebuild.
  void attachmentFailureShown() {
    emit(state.copyWith(clearAttachmentFailure: true));
  }
}
