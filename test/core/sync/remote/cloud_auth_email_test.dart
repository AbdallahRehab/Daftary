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

class _MockUserResponse extends Mock implements UserResponse {}

class _Initializer extends Fake implements SupabaseInitializer {
  _Initializer(this.client);

  @override
  final SupabaseClient client;
}

/// 021 T078: email linking (same uid) and sign-in (new uid), with one-time
/// codes.
void main() {
  late _MockGoTrue auth;
  late SupabaseCloudAuthDataSource source;
  const email = 'ahmed@gmail.com';

  setUpAll(() {
    registerFallbackValue(UserAttributes());
    registerFallbackValue(OtpType.email);
  });

  _MockUser user(String id, {bool anonymous = true, String? mail}) {
    final u = _MockUser();
    when(() => u.id).thenReturn(id);
    when(() => u.isAnonymous).thenReturn(anonymous);
    when(() => u.email).thenReturn(mail);
    return u;
  }

  void signedInAnonymously(String uid) {
    final session = _MockSession();
    final u = user(uid);
    when(() => session.isExpired).thenReturn(false);
    when(() => session.user).thenReturn(u);
    when(() => auth.currentSession).thenReturn(session);
    when(() => auth.currentUser).thenReturn(u);
  }

  AuthResponse verified(String uid) {
    final response = _MockAuthResponse();
    final u = user(uid, anonymous: false, mail: email);
    when(() => response.user).thenReturn(u);
    when(() => response.session).thenReturn(null);
    return response;
  }

  setUp(() {
    auth = _MockGoTrue();
    final client = _MockClient();
    when(() => client.auth).thenReturn(auth);
    source = SupabaseCloudAuthDataSource(_Initializer(client));
  });

  Matcher emailFailure(EmailAuthErrorReason reason) => throwsA(
    isA<SyncRemoteException>().having(
      (e) => e.failure,
      'failure',
      EmailAuthFailure(reason),
    ),
  );

  group('link (keeps the uid)', () {
    test('the code is sent with updateUser(email) on the anonymous '
        'session', () async {
      signedInAnonymously('anon-1');
      when(
        () => auth.updateUser(any()),
      ).thenAnswer((_) async => _MockUserResponse());

      await source.requestEmailLinkCode(email);

      final attributes =
          verify(() => auth.updateUser(captureAny())).captured.single
              as UserAttributes;
      expect(attributes.email, email);
      verifyNever(() => auth.signInAnonymously());
    });

    test('with no session yet, one is created first', () async {
      when(() => auth.currentSession).thenReturn(null);
      final response = _MockAuthResponse();
      final u = user('anon-2');
      when(() => response.user).thenReturn(u);
      when(() => auth.signInAnonymously()).thenAnswer((_) async => response);
      when(
        () => auth.updateUser(any()),
      ).thenAnswer((_) async => _MockUserResponse());

      await source.requestEmailLinkCode(email);
      verify(() => auth.signInAnonymously()).called(1);
    });

    test(
      'confirming verifies an emailChange code; the uid is retained',
      () async {
        signedInAnonymously('anon-1');
        when(
          () => auth.verifyOTP(
            type: any(named: 'type'),
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenAnswer((_) async => verified('anon-1'));

        await source.confirmEmailLink(email, '123456');

        verify(
          () => auth.verifyOTP(
            type: OtpType.emailChange,
            email: email,
            token: '123456',
          ),
        ).called(1);
        expect(source.currentUserId, 'anon-1');
      },
    );

    test('an address used by another account is reported', () async {
      signedInAnonymously('anon-1');
      when(() => auth.updateUser(any())).thenThrow(
        const AuthApiException(
          'taken',
          statusCode: '422',
          code: 'email_exists',
        ),
      );
      await expectLater(
        source.requestEmailLinkCode(email),
        emailFailure(EmailAuthErrorReason.emailInUse),
      );
    });
  });

  group('sign in (changes the uid)', () {
    test(
      'the code is sent with signInWithOtp, never creating a user',
      () async {
        when(
          () => auth.signInWithOtp(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenAnswer((_) async {});

        await source.requestSignInCode(email);
        verify(
          () => auth.signInWithOtp(email: email, shouldCreateUser: false),
        ).called(1);
      },
    );

    test('confirming verifies an email code and returns the new uid', () async {
      when(
        () => auth.verifyOTP(
          type: any(named: 'type'),
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => verified('existing-9'));

      expect(await source.confirmSignIn(email, '654321'), 'existing-9');
      verify(
        () =>
            auth.verifyOTP(type: OtpType.email, email: email, token: '654321'),
      ).called(1);
    });

    test('an unknown account is reported', () async {
      when(
        () => auth.signInWithOtp(
          email: any(named: 'email'),
          shouldCreateUser: any(named: 'shouldCreateUser'),
        ),
      ).thenThrow(
        const AuthApiException('no', statusCode: '422', code: 'otp_disabled'),
      );
      await expectLater(
        source.requestSignInCode(email),
        emailFailure(EmailAuthErrorReason.accountNotFound),
      );
    });
  });

  group('invalid code', () {
    for (final (label, error) in [
      (
        'otp_expired',
        const AuthApiException('bad', statusCode: '403', code: 'otp_expired'),
      ),
      ('a bare 403', const AuthApiException('bad', statusCode: '403')),
    ]) {
      test('$label is an invalid code, and never carries the email', () async {
        when(
          () => auth.verifyOTP(
            type: any(named: 'type'),
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenThrow(error);
        for (final call in [
          () => source.confirmEmailLink(email, '000000'),
          () => source.confirmSignIn(email, '000000'),
        ]) {
          try {
            await call();
            fail('expected a failure');
          } on SyncRemoteException catch (e) {
            expect(
              e.failure,
              const EmailAuthFailure(EmailAuthErrorReason.invalidCode),
            );
            expect(e.errorCode, 'email_invalidCode');
            expect('$e ${e.failure.message}', isNot(contains('ahmed')));
          }
        }
      });
    }
  });

  test('rate limiting and network errors keep their classification', () {
    expect(
      SupabaseCloudAuthDataSource.mapEmailError(
        const AuthApiException('slow down', statusCode: '429'),
        verifying: false,
      ).failure,
      const EmailAuthFailure(EmailAuthErrorReason.rateLimited),
    );
    final network = SupabaseCloudAuthDataSource.mapEmailError(
      AuthRetryableFetchException(),
      verifying: true,
    );
    expect(network.failure, isA<NetworkFailure>());
    expect(network.transient, isTrue);
  });

  test('currentEmail is the confirmed address, null when anonymous', () {
    final linked = user('u1', anonymous: false, mail: email);
    when(() => auth.currentUser).thenReturn(linked);
    expect(source.currentEmail, email);
    final anonymous = user('u2', mail: '');
    when(() => auth.currentUser).thenReturn(anonymous);
    expect(source.currentEmail, isNull);
  });
}
