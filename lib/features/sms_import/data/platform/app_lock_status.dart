import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/security/app_lifecycle_observer.dart';
import '../../domain/services/lock_status.dart';

/// [LockStatus] over the App Lock observer's `isLocked` notifier, so the
/// SMS domain never depends on Flutter (discovery permissions-lifecycle
/// §3.1). [changes] adds its listener only while someone listens and
/// removes it on cancel.
@LazySingleton(as: LockStatus)
class AppLockStatus implements LockStatus {
  AppLockStatus(this._observer);

  final AppLifecycleObserver _observer;

  @override
  bool get isLocked => _observer.isLocked.value;

  @override
  Stream<bool> get changes {
    late final StreamController<bool> controller;
    void onChange() => controller.add(_observer.isLocked.value);
    controller = StreamController<bool>(
      onListen: () => _observer.isLocked.addListener(onChange),
      onCancel: () => _observer.isLocked.removeListener(onChange),
    );
    return controller.stream;
  }
}
