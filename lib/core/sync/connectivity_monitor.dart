import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

/// 021: whether the device reports any network (research.md Decision 13).
///
/// This is a **hint only**. "No network" pauses sync and a network coming
/// back triggers a cycle, but a network being present never proves the
/// cloud is reachable: only a successful request does, and failures go to
/// backoff.
abstract class ConnectivityMonitor {
  /// Emits on every change, without repeats.
  Stream<bool> get hasNetwork;

  Future<bool> currentHasNetwork();
}

@LazySingleton(as: ConnectivityMonitor)
class ConnectivityPlusMonitor implements ConnectivityMonitor {
  ConnectivityPlusMonitor(this._connectivity);

  final Connectivity _connectivity;

  /// `[none]` (or no interface at all) means no network; any other result
  /// (wifi, mobile, ethernet, vpn, other…) means there may be one.
  static bool hasAnyNetwork(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Stream<bool> get hasNetwork =>
      _connectivity.onConnectivityChanged.map(hasAnyNetwork).distinct();

  @override
  Future<bool> currentHasNetwork() async =>
      hasAnyNetwork(await _connectivity.checkConnectivity());
}
