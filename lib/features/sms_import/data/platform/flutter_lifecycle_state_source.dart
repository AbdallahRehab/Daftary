import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../domain/services/app_lifecycle_state_source.dart';

/// [AppLifecycleStateSource] over `WidgetsBinding.lifecycleState`. `null`
/// (no state reported yet) counts as the foreground, as the lock screen
/// does (discovery permissions-lifecycle §3.1).
@LazySingleton(as: AppLifecycleStateSource)
class FlutterLifecycleStateSource implements AppLifecycleStateSource {
  FlutterLifecycleStateSource({
    @ignoreParam AppLifecycleState? Function()? readState,
  }) : _readState = readState ?? (() => WidgetsBinding.instance.lifecycleState);

  final AppLifecycleState? Function() _readState;

  @override
  bool get isResumed {
    final state = _readState();
    return state == null || state == AppLifecycleState.resumed;
  }
}
