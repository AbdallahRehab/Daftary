import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../domain/services/shared_text_source.dart';
import '../domain/usecases/import_shared_text.dart';
import 'routes.dart';
import 'shared_text_inbox.dart';

/// Routes text shared into the app (Android `ACTION_SEND text/plain`,
/// FR-016) to the Paste screen (T096, ui-contract §6).
///
/// Shape of `NotificationTapRouter` (idempotent [start], [dispose]), plus
/// an unlock wait: each share is released by [ImportSharedText] only while
/// App Lock is not showing, then put into the in-memory [SharedTextInbox]
/// and the router goes to [BankMessagesRoutes.paste]. The text is never
/// part of a route, a URL or a route `extra` (FR-016a, FR-080); the Paste
/// screen's cubit takes it from the inbox, once.
///
/// On iOS, macOS and the test host the source is empty, so this does
/// nothing.
@lazySingleton
class SharedTextRouter {
  SharedTextRouter(this._importShared, this._inbox);

  final ImportSharedText _importShared;
  final SharedTextInbox _inbox;
  StreamSubscription<SharedText>? _subscription;

  /// Starts listening; idempotent. [router] is the app's router.
  Future<void> start(GoRouter router) async {
    if (_subscription != null) return;
    _subscription = _importShared.unlockedShares().listen((shared) {
      _inbox.put(shared);
      router.go(BankMessagesRoutes.paste);
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
