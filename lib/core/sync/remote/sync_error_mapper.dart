import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../error/failure.dart';
import '../sync_models.dart';

/// 021: a failed cloud call, already classified (research.md Decision 20).
///
/// [transient] failures are retried with backoff. [errorCode] is a short
/// code that is safe to persist and log — it never contains record
/// content, a token or a server message.
class SyncRemoteException implements Exception {
  const SyncRemoteException(
    this.failure, {
    required this.transient,
    required this.errorCode,
  });

  final Failure failure;
  final bool transient;
  final String errorCode;

  /// The session is missing, expired or refused: the engine pauses with
  /// status `authRequired` instead of backing off.
  bool get requiresAuth =>
      failure is UnauthorizedFailure || failure is ForbiddenFailure;

  @override
  String toString() => 'SyncRemoteException($errorCode, transient: $transient)';
}

/// The error codes [SyncErrorMapper] produces.
abstract final class SyncErrorCode {
  static const network = 'network';
  static const timeout = 'timeout';
  static const server = 'server';
  static const unauthorized = 'unauthorized';
  static const forbidden = 'rls_denied';
  static const badResponse = 'bad_response';
  static const invalidRequest = 'invalid_request';
  static const unknown = 'unknown';

  /// A pulled row the local mappers cannot read (a newer server schema or
  /// a corrupt row). The page is not applied, the cursor stays, and the
  /// Settings sync page tells the user; the row is never skipped.
  static const downloadUnreadableRow = 'download_unreadable_row';
}

/// 021: maps every exception a cloud call can throw to a [Failure] plus a
/// transient/permanent classification (research.md Decision 20, plan §23).
abstract final class SyncErrorMapper {
  /// Postgres error codes that reject one operation by rule.
  static const _rejectCodes = {'23514', '23502', '22P02', 'P0001'};

  static SyncRemoteException map(Object error) {
    return switch (error) {
      SyncRemoteException() => error,
      TimeoutException() => _transient(
        const TimeoutFailure('cloud request timed out'),
        SyncErrorCode.timeout,
      ),
      // A network error inside the auth client (it retries these itself).
      AuthRetryableFetchException() => _network(),
      AuthException(:final statusCode) => _fromAuth(statusCode),
      PostgrestException(:final code) => _fromPostgrest(code),
      // Socket, handshake/TLS and other I/O errors.
      IOException() => _network(),
      http.ClientException() => _network(),
      // The response did not have the contracted shape.
      FormatException() || TypeError() => _permanent(
        const ServerFailure('unexpected cloud response'),
        SyncErrorCode.badResponse,
      ),
      // Unknown: retrying later with backoff is the safe default.
      _ => _transient(
        const UnknownFailure('unexpected cloud error'),
        SyncErrorCode.unknown,
      ),
    };
  }

  /// Whether a per-operation `rejected` [reason] is retried with backoff
  /// (`missing_parent`, from a `23503` foreign-key violation) rather than
  /// marked failed.
  static bool isTransientRejection(String reason) =>
      reason == PushRejectReason.missingParent;

  static SyncRemoteException _fromAuth(String? statusCode) {
    final status = int.tryParse(statusCode ?? '');
    if (status != null && (status >= 500 || status == 429)) {
      return _server();
    }
    return _permanent(
      const UnauthorizedFailure('cloud session invalid'),
      SyncErrorCode.unauthorized,
    );
  }

  static SyncRemoteException _fromPostgrest(String? code) {
    if (code == null) return _server();
    if (code == 'PGRST301' || code == '401') {
      return const SyncRemoteException(
        UnauthorizedFailure('cloud session expired'),
        // The session is refreshed once, then the engine pauses.
        transient: true,
        errorCode: SyncErrorCode.unauthorized,
      );
    }
    if (code == '42501' || code == '403') {
      return _permanent(
        const ForbiddenFailure('cloud access denied'),
        SyncErrorCode.forbidden,
      );
    }
    if (code == '23503') {
      return _transient(
        const SyncRejectedFailure(PushRejectReason.missingParent),
        PushRejectReason.missingParent,
      );
    }
    // `sync_push` refuses the whole call (bad device id or platform, more
    // than 100 operations): a client bug that retrying cannot fix.
    if (code == '22023') {
      return _permanent(
        const ServerFailure('cloud rejected the request'),
        SyncErrorCode.invalidRequest,
      );
    }
    if (_rejectCodes.contains(code)) {
      return _permanent(SyncRejectedFailure(code), code);
    }
    // PGRST000–PGRST003: PostgREST could not reach or pool the database.
    if (RegExp(r'^PGRST00\d$').hasMatch(code)) return _server();
    final status = int.tryParse(code);
    if (status != null && (status >= 500 || status == 429)) return _server();
    // Any other API error (for example a function that is not deployed):
    // retrying cannot fix it, but the whole batch stays queued.
    return _permanent(
      const ServerFailure('cloud request refused'),
      SyncErrorCode.server,
    );
  }

  static SyncRemoteException _network() => _transient(
    const NetworkFailure('cloud unreachable'),
    SyncErrorCode.network,
  );

  static SyncRemoteException _server() => _transient(
    const ServerFailure('cloud service error'),
    SyncErrorCode.server,
  );

  static SyncRemoteException _transient(Failure failure, String code) =>
      SyncRemoteException(failure, transient: true, errorCode: code);

  static SyncRemoteException _permanent(Failure failure, String code) =>
      SyncRemoteException(failure, transient: false, errorCode: code);
}
