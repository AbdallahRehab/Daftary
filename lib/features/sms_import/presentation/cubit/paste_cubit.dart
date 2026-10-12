import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_import_failures.dart';
import '../../domain/entities/sms_value_types.dart';
import '../../domain/usecases/import_pasted_text.dart';
import '../../domain/usecases/import_shared_text.dart';
import '../../domain/usecases/read_clipboard_text.dart';
import '../shared_text_inbox.dart';
import 'paste_state.dart';

/// The Paste screen (T090, ui-contract §3.5, US4).
///
/// - [pasteFromClipboard] is the only clipboard read and is called only
///   from the Paste button's `onPressed` (FR-015). [open] never reads it.
/// - [process] stages the field's text as `SmsSource.paste`.
/// - [open] consumes a share waiting in the [SharedTextInbox] (and every
///   later one while the screen is open) and stages it as
///   `SmsSource.share` after unlock (FR-016a).
///
/// It coordinates use cases only, never keeps the text in its state, and
/// can create nothing but pending suggestions (FR-022).
@injectable
class PasteCubit extends Cubit<PasteState> {
  PasteCubit(
    this._readClipboard,
    this._importPasted,
    this._importShared,
    this._inbox,
  ) : super(const PasteState());

  final ReadClipboardText _readClipboard;
  final ImportPastedText _importPasted;
  final ImportSharedText _importShared;
  final SharedTextInbox _inbox;

  StreamSubscription<void>? _arrivals;

  /// Starts consuming shares. Reads no clipboard.
  Future<void> open() async {
    await _arrivals?.cancel();
    _arrivals = _inbox.arrivals.listen((_) => consumeShared());
    await consumeShared();
  }

  /// Takes the waiting share, if any, once, and stages it.
  Future<void> consumeShared() async {
    if (isClosed || state.isProcessing) return;
    final shared = _inbox.take();
    if (shared == null) return;
    emit(const PasteState(status: PasteStatus.processing, fromShare: true));
    final result = await _importShared(shared);
    if (isClosed) return;
    emit(_stateFor(result, fromShare: true));
    _drainLaterShare();
  }

  /// The Paste button's tap: the only clipboard read (FR-015). Returns the
  /// text for the page to put into its field, or `null` and the "nothing
  /// to paste" state.
  Future<String?> pasteFromClipboard() async {
    if (state.isProcessing) return null;
    final text = await _readClipboard();
    if (isClosed) return null;
    if (text == null || text.trim().isEmpty) {
      emit(const PasteState(status: PasteStatus.clipboardEmpty));
      return null;
    }
    emit(const PasteState());
    return text;
  }

  /// Stages the field's [text] as a paste.
  Future<void> process(String text) async {
    if (state.isProcessing || text.trim().isEmpty) return;
    emit(const PasteState(status: PasteStatus.processing));
    final result = await _importPasted(text: text, source: SmsSource.paste);
    if (isClosed) return;
    emit(_stateFor(result, fromShare: false));
    _drainLaterShare();
  }

  /// A share that arrived while another import was running is consumed
  /// right after it, once the screen is open.
  void _drainLaterShare() {
    if (_arrivals != null && _inbox.hasPending) unawaited(consumeShared());
  }

  /// "Try again" and editing the field return to the ready state.
  void reset() {
    if (state.isProcessing || state.status == PasteStatus.ready) return;
    emit(const PasteState());
  }

  static PasteState _stateFor(
    Either<Failure, PasteImportResult> result, {
    required bool fromShare,
  }) => result.match(
    (failure) => switch (failure) {
      NotRecognizedFailure() => PasteState(
        status: PasteStatus.notRecognized,
        fromShare: fromShare,
      ),
      InputTooLargeFailure(:final limit) => PasteState(
        status: PasteStatus.tooLarge,
        fromShare: fromShare,
        tooLargeLimit: limit,
      ),
      _ => PasteState(
        status: PasteStatus.error,
        fromShare: fromShare,
        failure: failure,
      ),
    },
    (value) => PasteState(
      status: value.summary.recognized == 0
          ? PasteStatus.unreadableOnly
          : PasteStatus.recognized,
      fromShare: fromShare,
      result: value,
    ),
  );

  @override
  Future<void> close() async {
    await _arrivals?.cancel();
    _arrivals = null;
    return super.close();
  }
}
