import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/cloud_config.dart';
import 'secure_local_storage.dart';

/// 021: the single gate in front of the Supabase client (plan §4).
///
/// Nothing initializes Supabase except [ensureInitialized], which the
/// scheduler calls only when sync is configured **and** enabled — never
/// before `runApp`, so the 019 splash timing is unchanged. Until then no
/// request of any kind (including a token refresh) leaves the device.
abstract class SupabaseInitializer {
  /// Whether build-time cloud config was supplied ([CloudConfig]).
  bool get isConfigured;

  /// Whether [ensureInitialized] has completed successfully.
  bool get isInitialized;

  /// Initializes Supabase once. Returns false, doing nothing, when the app
  /// is not configured. Safe to call repeatedly and concurrently.
  Future<bool> ensureInitialized();

  /// The initialized client. Throws [StateError] before
  /// [ensureInitialized] has succeeded.
  SupabaseClient get client;

  /// Stops the background token refresh (sync switched off). No-op when
  /// not initialized.
  void stopAutoRefresh();

  /// Restarts the background token refresh (sync switched back on). No-op
  /// when not initialized.
  void startAutoRefresh();
}

/// The `Supabase.initialize` call, injectable so a test never initializes
/// the real singleton.
typedef SupabaseInitFunction =
    Future<SupabaseClient> Function({
      required String url,
      required String publishableKey,
      required FlutterAuthClientOptions authOptions,
    });

Future<SupabaseClient> _initializeSupabase({
  required String url,
  required String publishableKey,
  required FlutterAuthClientOptions authOptions,
}) async {
  final supabase = await Supabase.initialize(
    url: url,
    publishableKey: publishableKey,
    authOptions: authOptions,
    // Realtime is never subscribed (research.md Decision 5): the client
    // only opens a socket once a channel is joined, and none ever is.
  );
  return supabase.client;
}

@LazySingleton(as: SupabaseInitializer)
class DefaultSupabaseInitializer implements SupabaseInitializer {
  DefaultSupabaseInitializer(FlutterSecureStorage storage)
    : this.custom(
        storage: storage,
        configured: CloudConfig.isConfigured,
        url: CloudConfig.url,
        publishableKey: CloudConfig.publishableKey,
      );

  @visibleForTesting
  DefaultSupabaseInitializer.custom({
    required FlutterSecureStorage storage,
    required bool configured,
    required String url,
    required String publishableKey,
    SupabaseInitFunction initialize = _initializeSupabase,
  }) : _storage = storage,
       _configured = configured,
       _url = url,
       _publishableKey = publishableKey,
       _initialize = initialize;

  final FlutterSecureStorage _storage;
  final bool _configured;
  final String _url;
  final String _publishableKey;
  final SupabaseInitFunction _initialize;

  Future<bool>? _pending;
  SupabaseClient? _client;

  /// The auth options every initialization uses: the session and the PKCE
  /// verifier live in secure storage, tokens refresh automatically, and no
  /// deep link is ever read (the email flow uses one-time codes).
  @visibleForTesting
  FlutterAuthClientOptions get authOptions => FlutterAuthClientOptions(
    localStorage: SecureLocalStorage(_storage),
    pkceAsyncStorage: SecureGotrueAsyncStorage(_storage),
    autoRefreshToken: true,
    detectSessionInUri: false,
  );

  @override
  bool get isConfigured => _configured;

  @override
  bool get isInitialized => _client != null;

  @override
  Future<bool> ensureInitialized() {
    if (!_configured) return Future.value(false);
    if (_client != null) return Future.value(true);
    return _pending ??= _run();
  }

  Future<bool> _run() async {
    try {
      _client = await _initialize(
        url: _url,
        publishableKey: _publishableKey,
        authOptions: authOptions,
      );
      return true;
    } finally {
      // A failed attempt may be retried by the next cycle.
      _pending = null;
    }
  }

  @override
  SupabaseClient get client {
    final client = _client;
    if (client == null) {
      throw StateError(
        'SupabaseClient requested before SupabaseInitializer.ensureInitialized',
      );
    }
    return client;
  }

  @override
  void stopAutoRefresh() => _client?.auth.stopAutoRefresh();

  @override
  void startAutoRefresh() => _client?.auth.startAutoRefresh();
}
