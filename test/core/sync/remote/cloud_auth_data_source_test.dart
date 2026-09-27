import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/sync/remote/cloud_auth_data_source.dart';
import 'package:daftary/core/sync/remote/supabase_initializer.dart';
import 'package:daftary/core/sync/remote/sync_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockClient extends Mock implements SupabaseClient {}

class _MockGoTrue extends Mock implements GoTrueClient {}

class _MockSession extends Mock implements Session {}

class _MockUser extends Mock implements User {}

class _MockAuthResponse extends Mock implements AuthResponse {}

class _Initializer extends Fake implements SupabaseInitializer {
  _Initializer(this.client);

  @override
  final SupabaseClient client;
}

/// 021 T053: the anonymous-session part of the auth data source.
void main() {
  late _MockGoTrue auth;
  late SupabaseCloudAuthDataSource source;

  _MockUser user(String id, {bool anonymous = true}) {
    final u = _MockUser();
    when(() => u.id).thenReturn(id);
    when(() => u.isAnonymous).thenReturn(anonymous);
    return u;
  }

  setUp(() {
    auth = _MockGoTrue();
    final client = _MockClient();
    when(() => client.auth).thenReturn(auth);
    source = SupabaseCloudAuthDataSource(_Initializer(client));
  });

  test('with no session, signs in anonymously and returns the uid', () async {
    when(() => auth.currentSession).thenReturn(null);
    final response = _MockAuthResponse();
    final u = user('uid-1');
    when(() => response.user).thenReturn(u);
    when(() => auth.signInAnonymously()).thenAnswer((_) async => response);

    expect(await source.ensureSession(), 'uid-1');
    verify(() => auth.signInAnonymously()).called(1);
  });

  test('a valid session is reused without a request', () async {
    final session = _MockSession();
    final u = user('uid-2');
    when(() => session.isExpired).thenReturn(false);
    when(() => session.user).thenReturn(u);
    when(() => auth.currentSession).thenReturn(session);
    when(() => auth.currentUser).thenReturn(u);

    expect(await source.ensureSession(), 'uid-2');
    expect(source.currentUserId, 'uid-2');
    expect(source.isAnonymous, isTrue);
    verifyNever(() => auth.signInAnonymously());
    verifyNever(() => auth.refreshSession());
  });

  test('an expired session is refreshed', () async {
    final session = _MockSession();
    when(() => session.isExpired).thenReturn(true);
    when(() => auth.currentSession).thenReturn(session);
    final response = _MockAuthResponse();
    final u = user('uid-3');
    when(() => response.user).thenReturn(u);
    when(() => auth.refreshSession()).thenAnswer((_) async => response);

    expect(await source.ensureSession(), 'uid-3');
    verifyNever(() => auth.signInAnonymously());
  });

  test('failures surface as classified SyncRemoteException', () async {
    when(() => auth.currentSession).thenReturn(null);
    when(
      () => auth.signInAnonymously(),
    ).thenThrow(AuthRetryableFetchException());
    await expectLater(
      source.ensureSession(),
      throwsA(
        isA<SyncRemoteException>()
            .having((e) => e.failure, 'failure', isA<NetworkFailure>())
            .having((e) => e.transient, 'transient', isTrue),
      ),
    );

    when(
      () => auth.signInAnonymously(),
    ).thenThrow(const AuthApiException('disabled', statusCode: '422'));
    await expectLater(
      source.ensureSession(),
      throwsA(
        isA<SyncRemoteException>().having(
          (e) => e.requiresAuth,
          'requiresAuth',
          isTrue,
        ),
      ),
    );
  });

  test('no user signed in: no uid, not anonymous', () {
    when(() => auth.currentUser).thenReturn(null);
    expect(source.currentUserId, isNull);
    expect(source.isAnonymous, isFalse);
  });
}
