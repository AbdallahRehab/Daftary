import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:daftary/core/sync/connectivity_monitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

/// 021 T059: `[none]` → false, anything else → true, without repeats.
void main() {
  late _MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> changes;
  late ConnectivityPlusMonitor monitor;

  setUp(() {
    connectivity = _MockConnectivity();
    changes = StreamController<List<ConnectivityResult>>.broadcast();
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => changes.stream);
    monitor = ConnectivityPlusMonitor(connectivity);
  });

  tearDown(() => changes.close());

  test('maps results and suppresses repeats', () async {
    final seen = <bool>[];
    final sub = monitor.hasNetwork.listen(seen.add);
    changes
      ..add([ConnectivityResult.none])
      ..add([ConnectivityResult.wifi])
      ..add([ConnectivityResult.mobile, ConnectivityResult.vpn])
      ..add([ConnectivityResult.other])
      ..add([ConnectivityResult.none])
      ..add([])
      ..add([ConnectivityResult.ethernet]);
    await pumpEventQueue();
    expect(seen, [false, true, false, true]);
    await sub.cancel();
  });

  test('currentHasNetwork reads the current state', () async {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
    expect(await monitor.currentHasNetwork(), isFalse);
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    expect(await monitor.currentHasNetwork(), isTrue);
  });
}
