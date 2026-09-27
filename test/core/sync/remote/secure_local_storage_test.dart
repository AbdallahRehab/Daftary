import 'package:daftary/core/sync/remote/secure_local_storage.dart';
import 'package:daftary/core/sync/remote/supabase_initializer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrue extends Mock implements GoTrueClient {}

/// 021 T051: the session lives in secure storage, and Supabase is
/// initialized once, lazily, and never when unconfigured.
void main() {
  late _MockSecureStorage storage;

  setUp(() {
    storage = _MockSecureStorage();
  });

  group('SecureLocalStorage', () {
    const key = SecureLocalStorage.sessionKey;

    test('persists, reads and removes the session under one key', () async {
      when(
        () => storage.write(key: key, value: 'session-json'),
      ).thenAnswer((_) async {});
      when(
        () => storage.read(key: key),
      ).thenAnswer((_) async => 'session-json');
      when(() => storage.containsKey(key: key)).thenAnswer((_) async => true);
      when(() => storage.delete(key: key)).thenAnswer((_) async {});

      final local = SecureLocalStorage(storage);
      await local.initialize();
      await local.persistSession('session-json');
      expect(await local.hasAccessToken(), isTrue);
      expect(await local.accessToken(), 'session-json');
      await local.removePersistedSession();

      verify(() => storage.write(key: key, value: 'session-json')).called(1);
      verify(() => storage.delete(key: key)).called(1);
    });

    test('the PKCE store is namespaced in secure storage too', () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      await SecureGotrueAsyncStorage(storage).setItem(key: 'k', value: 'v');
      verify(
        () => storage.write(key: 'daftary.supabase.pkce.k', value: 'v'),
      ).called(1);
    });
  });

  group('DefaultSupabaseInitializer', () {
    test('does nothing when not configured', () async {
      var calls = 0;
      final init = DefaultSupabaseInitializer.custom(
        storage: storage,
        configured: false,
        url: '',
        publishableKey: '',
        initialize:
            ({required url, required publishableKey, required authOptions}) {
              calls++;
              throw StateError('must not initialize');
            },
      );
      expect(await init.ensureInitialized(), isFalse);
      expect(init.isInitialized, isFalse);
      expect(calls, 0);
      expect(() => init.client, throwsStateError);
      init.stopAutoRefresh(); // no-op, no throw
    });

    test('initializes once, with secure storage and auto refresh', () async {
      final client = _MockSupabaseClient();
      final auth = _MockGoTrue();
      when(() => client.auth).thenReturn(auth);
      FlutterAuthClientOptions? seen;
      var calls = 0;
      final init = DefaultSupabaseInitializer.custom(
        storage: storage,
        configured: true,
        url: 'https://example.supabase.co',
        publishableKey: 'pk',
        initialize:
            ({
              required url,
              required publishableKey,
              required authOptions,
            }) async {
              calls++;
              seen = authOptions;
              expect(url, 'https://example.supabase.co');
              expect(publishableKey, 'pk');
              return client;
            },
      );

      final results = await Future.wait([
        init.ensureInitialized(),
        init.ensureInitialized(),
      ]);
      expect(results, [true, true]);
      expect(await init.ensureInitialized(), isTrue);
      expect(calls, 1);
      expect(init.client, same(client));
      expect(seen!.localStorage, isA<SecureLocalStorage>());
      expect(seen!.pkceAsyncStorage, isA<SecureGotrueAsyncStorage>());
      expect(seen!.autoRefreshToken, isTrue);
      expect(seen!.detectSessionInUri, isFalse);

      init.stopAutoRefresh();
      init.startAutoRefresh();
      verify(auth.stopAutoRefresh).called(1);
      verify(auth.startAutoRefresh).called(1);
    });

    test('a failed initialization can be retried', () async {
      final client = _MockSupabaseClient();
      var calls = 0;
      final init = DefaultSupabaseInitializer.custom(
        storage: storage,
        configured: true,
        url: 'https://example.supabase.co',
        publishableKey: 'pk',
        initialize:
            ({
              required url,
              required publishableKey,
              required authOptions,
            }) async {
              if (calls++ == 0) throw StateError('first fails');
              return client;
            },
      );
      await expectLater(init.ensureInitialized(), throwsStateError);
      expect(await init.ensureInitialized(), isTrue);
    });
  });
}
