import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_initializer.dart';
import 'sync_error_mapper.dart';

/// 021: the cloud identity (research.md Decision 11). An anonymous session
/// is created on the first online sync; linking an email keeps its uid.
///
/// Every method throws [SyncRemoteException] on failure. The raw email is
/// never logged.
abstract class CloudAuthDataSource {
  /// The current `auth.uid()`, or null with no session.
  String? get currentUserId;

  /// Whether the current session is an anonymous one.
  bool get isAnonymous;

  /// Returns the uid of a valid session, signing in anonymously when there
  /// is none and refreshing an expired one.
  Future<String> ensureSession();

  /// Refreshes the current session once (after a 401 / `PGRST301`).
  Future<void> refreshSession();

  /// Sends a one-time code to link [email] to the current (anonymous) uid.
  /// Implemented by T078.
  Future<void> requestEmailLinkCode(String email);

  /// Confirms the link code; the uid is unchanged. Implemented by T078.
  Future<void> confirmEmailLink(String email, String code);

  /// Sends a one-time sign-in code for an existing account. Implemented by
  /// T078.
  Future<void> requestSignInCode(String email);

  /// Confirms the sign-in code and returns the (new) uid, which makes the
  /// engine re-own local data. Implemented by T078.
  Future<String> confirmSignIn(String email, String code);
}

@LazySingleton(as: CloudAuthDataSource)
class SupabaseCloudAuthDataSource implements CloudAuthDataSource {
  SupabaseCloudAuthDataSource(this._supabase);

  /// Resolved on each call: the client exists only after the scheduler has
  /// initialized Supabase.
  final SupabaseInitializer _supabase;

  GoTrueClient get _auth => _supabase.client.auth;

  @override
  String? get currentUserId => _auth.currentUser?.id;

  @override
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  @override
  Future<String> ensureSession() async {
    try {
      final session = _auth.currentSession;
      if (session != null) {
        if (session.isExpired) {
          final refreshed = await _auth.refreshSession();
          final uid = refreshed.user?.id ?? _auth.currentUser?.id;
          if (uid == null) throw _noSession();
          return uid;
        }
        return session.user.id;
      }
      final response = await _auth.signInAnonymously();
      final uid = response.user?.id;
      if (uid == null) throw _noSession();
      return uid;
    } catch (error) {
      throw SyncErrorMapper.map(error);
    }
  }

  @override
  Future<void> refreshSession() async {
    try {
      await _auth.refreshSession();
    } catch (error) {
      throw SyncErrorMapper.map(error);
    }
  }

  // The email methods belong to T078 (US6): only their contract is part of
  // US2. They throw until T078 implements them.

  @override
  Future<void> requestEmailLinkCode(String email) =>
      throw UnimplementedError('Email linking is implemented by T078');

  @override
  Future<void> confirmEmailLink(String email, String code) =>
      throw UnimplementedError('Email linking is implemented by T078');

  @override
  Future<void> requestSignInCode(String email) =>
      throw UnimplementedError('Email sign-in is implemented by T078');

  @override
  Future<String> confirmSignIn(String email, String code) =>
      throw UnimplementedError('Email sign-in is implemented by T078');

  static AuthException _noSession() =>
      AuthSessionMissingException('no session after sign-in');
}
