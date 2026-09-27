import 'dart:async';
import 'dart:io';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/sync/remote/sync_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// 021 T052: one test per row of research.md Decision 20.
void main() {
  void expectMapped(
    Object error,
    Matcher failure, {
    required bool transient,
    String? code,
  }) {
    final mapped = SyncErrorMapper.map(error);
    expect(mapped.failure, failure);
    expect(mapped.transient, transient, reason: '$error transient');
    if (code != null) expect(mapped.errorCode, code);
  }

  PostgrestException pg(String code) =>
      PostgrestException(message: 'secret row content', code: code);

  group('network → NetworkFailure, transient', () {
    test('SocketException', () {
      expectMapped(
        const SocketException('no route'),
        isA<NetworkFailure>(),
        transient: true,
        code: 'network',
      );
    });
    test('HandshakeException', () {
      expectMapped(
        const HandshakeException('tls'),
        isA<NetworkFailure>(),
        transient: true,
      );
    });
    test('http ClientException', () {
      expectMapped(
        http.ClientException('connection closed'),
        isA<NetworkFailure>(),
        transient: true,
      );
    });
    test('AuthRetryableFetchException', () {
      expectMapped(
        AuthRetryableFetchException(),
        isA<NetworkFailure>(),
        transient: true,
      );
    });
  });

  test('TimeoutException → TimeoutFailure, transient', () {
    expectMapped(
      TimeoutException('20 s'),
      isA<TimeoutFailure>(),
      transient: true,
      code: 'timeout',
    );
  });

  group('server → ServerFailure, transient', () {
    for (final code in ['500', '502', '503', '429', 'PGRST000', 'PGRST003']) {
      test(code, () {
        expectMapped(
          pg(code),
          isA<ServerFailure>(),
          transient: true,
          code: 'server',
        );
      });
    }
    test('auth 5xx', () {
      expectMapped(
        const AuthException('down', statusCode: '503'),
        isA<ServerFailure>(),
        transient: true,
      );
    });
  });

  group('auth → UnauthorizedFailure', () {
    test('AuthException', () {
      expectMapped(
        const AuthException('bad jwt', statusCode: '401'),
        isA<UnauthorizedFailure>(),
        transient: false,
        code: 'unauthorized',
      );
      expect(
        SyncErrorMapper.map(const AuthException('x')).requiresAuth,
        isTrue,
      );
    });
    test('PGRST301 (JWT expired) is refreshed once: transient', () {
      expectMapped(pg('PGRST301'), isA<UnauthorizedFailure>(), transient: true);
    });
  });

  test('42501 → ForbiddenFailure, permanent', () {
    final mapped = SyncErrorMapper.map(pg('42501'));
    expect(mapped.failure, isA<ForbiddenFailure>());
    expect(mapped.transient, isFalse);
    expect(mapped.requiresAuth, isTrue);
    expect(mapped.errorCode, 'rls_denied');
  });

  group('rule violations → SyncRejectedFailure, permanent', () {
    for (final code in ['23514', '23502', '22P02']) {
      test(code, () {
        expectMapped(
          pg(code),
          isA<SyncRejectedFailure>().having((f) => f.reason, 'reason', code),
          transient: false,
          code: code,
        );
      });
    }
  });

  test('23503 / rejected missing_parent → transient', () {
    expectMapped(
      pg('23503'),
      isA<SyncRejectedFailure>().having(
        (f) => f.reason,
        'reason',
        'missing_parent',
      ),
      transient: true,
    );
    expect(SyncErrorMapper.isTransientRejection('missing_parent'), isTrue);
    expect(SyncErrorMapper.isTransientRejection('validation'), isFalse);
    expect(
      SyncErrorMapper.isTransientRejection('person_has_transactions'),
      isFalse,
    );
  });

  test('22023 (a refused whole call) is permanent', () {
    expectMapped(
      pg('22023'),
      isA<ServerFailure>(),
      transient: false,
      code: 'invalid_request',
    );
  });

  test('a malformed response is permanent; an unknown error is transient', () {
    expectMapped(
      const FormatException('bad'),
      isA<ServerFailure>(),
      transient: false,
      code: 'bad_response',
    );
    expectMapped(
      StateError('?'),
      isA<UnknownFailure>(),
      transient: true,
      code: 'unknown',
    );
  });

  test('an already mapped exception passes through unchanged', () {
    const original = SyncRemoteException(
      NetworkFailure('x'),
      transient: true,
      errorCode: 'network',
    );
    expect(identical(SyncErrorMapper.map(original), original), isTrue);
  });

  test('the error code never carries the server message', () {
    final mapped = SyncErrorMapper.map(pg('23514'));
    expect(mapped.errorCode, isNot(contains('secret')));
    expect(mapped.toString(), isNot(contains('secret')));
  });
}
