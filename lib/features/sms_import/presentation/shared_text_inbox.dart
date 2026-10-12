import 'dart:async';

import 'package:injectable/injectable.dart';

import '../domain/services/shared_text_source.dart';

/// The one place a shared text waits between the share and the Paste
/// screen (ui-contract §6, FR-016a, FR-079, FR-080).
///
/// In memory only: never a route, a URL, a route `extra`, restoration
/// state, a notification or a file. It holds at most one text; a newer
/// share replaces an unconsumed older one. [take] returns it once and
/// clears it.
@lazySingleton
class SharedTextInbox {
  SharedText? _pending;
  final StreamController<void> _arrivals = StreamController<void>.broadcast();

  /// Whether a share is waiting to be consumed.
  bool get hasPending => _pending != null;

  /// Fires after every [put], so an already open Paste screen consumes a
  /// warm share. Carries no content.
  Stream<void> get arrivals => _arrivals.stream;

  void put(SharedText shared) {
    _pending = shared;
    if (!_arrivals.isClosed) _arrivals.add(null);
  }

  /// The waiting share, once; `null` when there is none.
  SharedText? take() {
    final shared = _pending;
    _pending = null;
    return shared;
  }

  @disposeMethod
  Future<void> dispose() async {
    _pending = null;
    await _arrivals.close();
  }

  @override
  String toString() => 'SharedTextInbox(pending: $hasPending)';
}
