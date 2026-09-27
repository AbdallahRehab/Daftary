import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../error/failure.dart';
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

  /// The confirmed email of the current account, or null (anonymous). For
  /// display only, and only masked; it is never logged.
  String? get currentEmail;

  /// Returns the uid of a valid session, signing in anonymously when there
  /// is none and refreshing an expired one.
  Future<String> ensureSession();

  /// Refreshes the current session once (after a 401 / `PGRST301`).
  Future<void> refreshSession();

  /// Sends a one-time code to link [email] to the current (anonymous) uid
  /// (`updateUser(email)`).
  Future<void> requestEmailLinkCode(String email);

  /// Confirms the link code; the uid is unchanged.
  Future<void> confirmEmailLink(String email, String code);

  /// Sends a one-time sign-in code for an existing account
  /// (`signInWithOtp`).
  Future<void> requestSignInCode(String email);

  /// Confirms the sign-in code and returns the (new) uid, which makes the
  /// engine re-own local data.
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
  String? get currentEmail {
    final email = _auth.currentUser?.email;
    return (email == null || email.isEmpty) ? null : email;
  }

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

  // --- Email linking and sign-in (T078, research.md Decision 11) ---------
  //
  // One-time codes, never deep links. The raw email is passed to the auth
  // client only; it is never logged or kept in an error.

  @override
  Future<void> requestEmailLinkCode(String email) async {
    try {
      // Linking needs the anonymous session whose uid is kept.
      await ensureSession();
      await _auth.updateUser(UserAttributes(email: email));
    } catch (error) {
      throw mapEmailError(error, verifying: false);
    }
  }

  @override
  Future<void> confirmEmailLink(String email, String code) async {
    try {
      await _auth.verifyOTP(
        type: OtpType.emailChange,
        email: email,
        token: code,
      );
    } catch (error) {
      throw mapEmailError(error, verifying: true);
    }
  }

  @override
  Future<void> requestSignInCode(String email) async {
    try {
      // Only an existing account: signing in never creates a new one.
      await _auth.signInWithOtp(email: email, shouldCreateUser: false);
    } catch (error) {
      throw mapEmailError(error, verifying: false);
    }
  }

  @override
  Future<String> confirmSignIn(String email, String code) async {
    try {
      final response = await _auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: code,
      );
      final uid = response.user?.id ?? response.session?.user.id;
      if (uid == null) throw _noSession();
      // A different uid than before: the engine re-owns the local data on
      // its next cycle (T069).
      return uid;
    } catch (error) {
      throw mapEmailError(error, verifying: true);
    }
  }

  /// Classifies an email step failure. Refusals the user can fix (a wrong
  /// code, an address in use) become [EmailAuthFailure]; everything else
  /// (network, server) keeps the sync classification.
  @visibleForTesting
  static SyncRemoteException mapEmailError(
    Object error, {
    required bool verifying,
  }) {
    if (error is SyncRemoteException) return error;
    if (error is AuthException && error is! AuthRetryableFetchException) {
      final reason = _emailReason(error, verifying: verifying);
      if (reason != null) {
        return SyncRemoteException(
          EmailAuthFailure(reason),
          transient: false,
          errorCode: 'email_${reason.name}',
        );
      }
    }
    return SyncErrorMapper.map(error);
  }

  static EmailAuthErrorReason? _emailReason(
    AuthException error, {
    required bool verifying,
  }) {
    switch (error.code) {
      case 'otp_expired':
        return EmailAuthErrorReason.invalidCode;
      case 'email_exists':
      case 'user_already_exists':
      case 'identity_already_exists':
        return EmailAuthErrorReason.emailInUse;
      case 'email_address_invalid':
      case 'validation_failed':
        return EmailAuthErrorReason.invalidEmail;
      case 'otp_disabled':
      case 'user_not_found':
      case 'signup_disabled':
        return EmailAuthErrorReason.accountNotFound;
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return EmailAuthErrorReason.rateLimited;
    }
    final status = int.tryParse(error.statusCode ?? '');
    if (status == 429) return EmailAuthErrorReason.rateLimited;
    // A refused verification without a known code is a bad code.
    if (verifying && (status == 400 || status == 401 || status == 403)) {
      return EmailAuthErrorReason.invalidCode;
    }
    if (!verifying && (status == 400 || status == 422)) {
      return EmailAuthErrorReason.invalidEmail;
    }
    return null;
  }

  static AuthException _noSession() =>
      AuthSessionMissingException('no session after sign-in');
}
