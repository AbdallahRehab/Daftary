import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_import_enums.dart';
import '../entities/sms_import_failures.dart';
import '../entities/sms_value_types.dart';
import '../services/lock_status.dart';
import '../services/shared_text_source.dart';
import 'import_pasted_text.dart';

/// The Android share path (domain-interfaces §5.2, FR-016, FR-016a).
///
/// - [unlockedShares] reads the cold-start share once
///   (`SharedTextSource.takeInitial`) and every warm share
///   (`SharedTextSource.stream`), and releases each one only while App Lock
///   is not showing. The text exists only in memory.
/// - [call] stages one share through exactly the paste pipeline
///   ([ImportPastedText] with `SmsSource.share`: no sender, no receipt time,
///   capped at Medium; nothing stored when not recognized). It waits for
///   unlock again first, so parsing never runs behind the lock screen even
///   if the lock lands late (discovery permissions-lifecycle L1).
///
/// Text the platform truncated (over 10,000 characters) is reported as too
/// long and never parsed in part.
@injectable
class ImportSharedText {
  ImportSharedText(this._source, this._lock, this._importPasted);

  final SharedTextSource _source;
  final LockStatus _lock;
  final ImportPastedText _importPasted;

  /// Shares in arrival order, each released only after unlock. Listen
  /// once (the platform stream is single-subscription).
  Stream<SharedText> unlockedShares() {
    late final StreamController<SharedText> controller;
    StreamSubscription<SharedText>? subscription;
    var queue = Future<void>.value();

    void enqueue(SharedText shared) {
      queue = queue.then((_) async {
        await _untilUnlocked();
        if (!controller.isClosed) controller.add(shared);
      });
    }

    controller = StreamController<SharedText>(
      onListen: () {
        subscription = _source.stream.listen(enqueue);
        unawaited(
          _source.takeInitial().then((initial) {
            if (initial != null) enqueue(initial);
          }),
        );
      },
      onCancel: () async {
        await subscription?.cancel();
        subscription = null;
      },
    );
    return controller.stream;
  }

  Future<Either<Failure, PasteImportResult>> call(SharedText shared) async {
    await _untilUnlocked();
    if (shared.truncated) {
      return const Left(InputTooLargeFailure(InputLimit.characters));
    }
    return _importPasted(text: shared.text, source: SmsSource.share);
  }

  /// Completes at once when unlocked, else on the first unlocked change.
  /// Subscribes before re-reading, so an unlock in between is not missed.
  Future<void> _untilUnlocked() async {
    if (!_lock.isLocked) return;
    final unlocked = Completer<void>();
    final subscription = _lock.changes.listen((locked) {
      if (!locked && !unlocked.isCompleted) unlocked.complete();
    });
    if (!_lock.isLocked && !unlocked.isCompleted) unlocked.complete();
    await unlocked.future;
    await subscription.cancel();
  }
}
