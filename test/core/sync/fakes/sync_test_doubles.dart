import 'dart:async';

import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/sync/connectivity_monitor.dart';
import 'package:daftary/core/sync/remote/cloud_auth_data_source.dart';
import 'package:daftary/core/sync/remote/supabase_initializer.dart';
import 'package:daftary/core/sync/remote/sync_error_mapper.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A clock the test moves by hand.
class FakeClock implements AppClock {
  FakeClock([DateTime? start]) : _now = start ?? DateTime.utc(2026, 9, 27, 9);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

/// A clock that reads the fake-async aware `DateTime` via [Zone] timers:
/// it follows `FakeAsync.elapsed` when [elapsed] is wired to it.
class ElapsedClock implements AppClock {
  ElapsedClock(this.elapsed, [DateTime? start])
    : _start = start ?? DateTime.utc(2026, 9, 27, 9);

  final Duration Function() elapsed;
  final DateTime _start;

  @override
  DateTime now() => _start.add(elapsed());
}

/// A configured, never-networked Supabase gate.
class FakeSupabaseInitializer implements SupabaseInitializer {
  FakeSupabaseInitializer({this.configured = true});

  bool configured;
  int initializeCalls = 0;
  int stopRefreshCalls = 0;
  int startRefreshCalls = 0;
  bool _initialized = false;

  @override
  bool get isConfigured => configured;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<bool> ensureInitialized() async {
    if (!configured) return false;
    initializeCalls++;
    _initialized = true;
    return true;
  }

  @override
  SupabaseClient get client =>
      throw StateError('FakeSupabaseInitializer has no client');

  @override
  void stopAutoRefresh() => stopRefreshCalls++;

  @override
  void startAutoRefresh() => startRefreshCalls++;
}

/// An anonymous session that always exists, unless told to fail.
class FakeCloudAuth implements CloudAuthDataSource {
  String uid = '00000000-0000-4000-8000-000000000001';
  int ensureCalls = 0;
  int refreshCalls = 0;
  final List<SyncRemoteException> ensureFailures = [];
  final List<SyncRemoteException> refreshFailures = [];

  @override
  String? get currentUserId => uid;

  @override
  bool get isAnonymous => true;

  @override
  Future<String> ensureSession() async {
    ensureCalls++;
    if (ensureFailures.isNotEmpty) throw ensureFailures.removeAt(0);
    return uid;
  }

  @override
  Future<void> refreshSession() async {
    refreshCalls++;
    if (refreshFailures.isNotEmpty) throw refreshFailures.removeAt(0);
  }

  @override
  Future<void> requestEmailLinkCode(String email) async {}

  @override
  Future<void> confirmEmailLink(String email, String code) async {}

  @override
  Future<void> requestSignInCode(String email) async {}

  @override
  Future<String> confirmSignIn(String email, String code) async => uid;
}

/// A network the test switches on and off.
class FakeConnectivity implements ConnectivityMonitor {
  FakeConnectivity({bool online = true}) : _online = online;

  bool _online;
  final _changes = StreamController<bool>.broadcast();

  bool get online => _online;

  set online(bool value) {
    _online = value;
    _changes.add(value);
  }

  @override
  Stream<bool> get hasNetwork => _changes.stream;

  @override
  Future<bool> currentHasNetwork() async => _online;

  Future<void> close() => _changes.close();
}

/// Records every event, with its fields.
class RecordingSyncLogger implements SyncLogger {
  final List<(SyncEvent, Map<SyncLogField, Object>)> events = [];

  List<SyncEvent> get names => [for (final (e, _) in events) e];

  @override
  void event(SyncEvent e, {Map<SyncLogField, Object> fields = const {}}) =>
      events.add((e, fields));
}
