import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/media/attachment_picker_service.dart';
import '../../domain/entities/occasion_detail.dart';
import '../../domain/entities/occasion_failures.dart';
import '../../domain/usecases/add_occasion_attachment.dart';
import '../../domain/usecases/archive_occasion.dart';
import '../../domain/usecases/delete_occasion.dart';
import '../../domain/usecases/remove_occasion_attachment.dart';
import '../../domain/usecases/remove_participant_contribution.dart';
import '../../domain/usecases/restore_occasion.dart';
import '../../domain/usecases/watch_occasion_detail.dart';
import 'occasion_detail_state.dart';

/// Drives the occasion detail screen: totals, settlement, participant rows,
/// attachments, and the occasion-level archive/restore/delete actions.
///
/// 021: the detail is a live [WatchOccasionDetail] subscription, cancelled
/// in [close]. No mutation patches the in-memory detail or re-reads it by
/// hand: the totals are an aggregate over the same rows, so every change —
/// made here, from a person's own profile, or applied by sync — reaches the
/// page through the one re-read, which is what makes FR-007's "recalculated
/// immediately" true rather than approximately true (FR-031).
@injectable
class OccasionDetailCubit extends Cubit<OccasionDetailState> {
  OccasionDetailCubit(
    this._watchOccasionDetail,
    this._removeParticipantContribution,
    this._addOccasionAttachment,
    this._removeOccasionAttachment,
    this._archiveOccasion,
    this._restoreOccasion,
    this._deleteOccasion,
    this._pickerService,
  ) : super(const OccasionDetailState(occasionId: ''));

  final WatchOccasionDetail _watchOccasionDetail;
  final RemoveParticipantContribution _removeParticipantContribution;
  final AddOccasionAttachment _addOccasionAttachment;
  final RemoveOccasionAttachment _removeOccasionAttachment;
  final ArchiveOccasion _archiveOccasion;
  final RestoreOccasion _restoreOccasion;
  final DeleteOccasion _deleteOccasion;
  final AttachmentPickerService _pickerService;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;

  /// Subscribes to [occasionId], replacing any earlier subscription. The
  /// returned future completes once the first result has been emitted.
  Future<void> subscribe(String occasionId) {
    _cancelSubscription();
    emit(
      OccasionDetailState(
        occasionId: occasionId,
        status: OccasionDetailStatus.loading,
      ),
    );

    final firstResult = _firstResult = Completer<void>();
    _subscription = _watchOccasionDetail(occasionId).listen(_onDetail);
    return firstResult.future;
  }

  /// Retry and pull to refresh: subscribes again, from scratch, to the
  /// displayed occasion.
  Future<void> resubscribe() => subscribe(state.occasionId);

  void _onDetail(Either<Failure, OccasionDetail> result) {
    if (isClosed || state.isDeleted) return;
    result.match(
      (failure) {
        // An occasion that was on screen and is now unreadable as "not
        // found" was deleted — from its edit screen, or on another device
        // and applied by sync. It is marked gone, exactly like a delete
        // made here (FR-013), rather than reported as an error.
        if (failure is OccasionNotFoundFailure && state.detail != null) {
          _cancelSubscription();
          emit(state.copyWith(isDeleted: true));
          return;
        }
        emit(
          state.copyWith(
            status: OccasionDetailStatus.failure,
            failure: failure,
          ),
        );
      },
      (detail) => emit(
        state.copyWith(
          status: OccasionDetailStatus.success,
          detail: detail,
          clearFailure: true,
        ),
      ),
    );
    _completeFirstResult();
  }

  /// Removes one participant's contribution after the page has confirmed it
  /// (FR-011). The same row disappears from that person's own history too,
  /// because it is the same row; the live subscription drops it here and
  /// recalculates the totals.
  Future<bool> removeParticipant(String transactionId) async {
    final result = await _removeParticipantContribution(transactionId);
    if (isClosed) return false;

    return result.match((failure) {
      emit(state.copyWith(failure: failure));
      return false;
    }, (_) => true);
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
          // The live subscription brings the new photo in.
          (_) async =>
              emit(state.copyWith(attachmentStatus: AttachmentStatus.idle)),
        );
      },
    );
  }

  /// Removes an attachment after the page has confirmed it (FR-017); the
  /// live subscription drops it from the gallery.
  Future<bool> removeAttachment(String attachmentId) async {
    final result = await _removeOccasionAttachment(attachmentId);
    if (isClosed) return false;

    return result.match((failure) {
      emit(state.copyWith(attachmentFailure: failure));
      return false;
    }, (_) => true);
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
        // The tombstone must not be re-read into a "not found" failure.
        _cancelSubscription();
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

    return result.match((failure) {
      emit(state.copyWith(failure: failure));
      return false;
    }, (_) => true);
  }

  /// Clears a surfaced attachment error once the page has shown it, so it
  /// is explained once rather than on every rebuild.
  void attachmentFailureShown() {
    emit(state.copyWith(clearAttachmentFailure: true));
  }

  void _completeFirstResult() {
    final firstResult = _firstResult;
    if (firstResult != null && !firstResult.isCompleted) {
      firstResult.complete();
    }
  }

  void _cancelSubscription() {
    _subscription?.cancel();
    _subscription = null;
    // A superseded subscription will never deliver; release its waiter.
    _completeFirstResult();
  }

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }
}
