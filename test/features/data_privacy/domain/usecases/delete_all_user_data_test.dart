import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/data/datasources/secure_credential_store_impl.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/purge_ai_assistant_credentials.dart';
import 'package:daftary/features/data_privacy/domain/repositories/data_wipe_repository.dart';
import 'package:daftary/features/data_privacy/domain/services/secure_storage_wiper.dart';
import 'package:daftary/features/data_privacy/domain/usecases/delete_all_user_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_cloud_copy_eraser.dart';
import '../../../ai_assistant/helpers/ai_assistant_harness.dart';

class MockDataWipeRepository extends Mock implements DataWipeRepository {}

/// Records calls instead of touching real secure storage; App Lock's real
/// wiper is covered in `test/features/app_lock/integration/`.
class FakeSecureStorageWiper implements SecureStorageWiper {
  final List<String> log = [];
  Failure? wipeFailure;

  @override
  Future<Either<Failure, SecureStorageRestore>> wipe() async {
    log.add('wipe');
    final failure = wipeFailure;
    if (failure != null) return Left(failure);
    return Right(() async {
      log.add('restore');
      return const Right(unit);
    });
  }
}

/// T032 — `DeleteAllUserData` wipes every table; the onboarding reset and
/// navigation belong to `DeleteAccountCubit` (research.md Decision 6).
///
/// 014 T084 — it also forgets the AI assistant's API key, which lives in
/// secure storage where the table wipe cannot reach. Exercised against the
/// real `AIAssistantRepositoryImpl` with a fake keychain.
void main() {
  late MockDataWipeRepository repository;
  late FakeSecureStorageWiper wiper;
  late AIAssistantHarness ai;
  late FakeCloudCopyEraser cloud;
  late DeleteAllUserData useCase;

  DeleteAllUserData buildUseCase() => DeleteAllUserData(
    repository,
    PurgeAIAssistantCredentials(ai.repository),
    wiper,
    cloud,
  );

  setUp(() async {
    repository = MockDataWipeRepository();
    wiper = FakeSecureStorageWiper();
    cloud = FakeCloudCopyEraser();
    ai = AIAssistantHarness.open();
    useCase = buildUseCase();
    await ai.repository.enable(
      providerId: AIProviderRegistry.openAiId,
      apiKey: testApiKey,
      consentAcceptedAt: DateTime(2026, 9, 1),
    );
    // A leftover custom-provider key too: every slot must be forgotten.
    ai.store.keys[AIProviderRegistry.customPrefix] = otherTestApiKey;
    ai.store.log.clear();
  });
  tearDown(() => ai.close());

  test('returns Right(unit) when the repository wipe succeeds', () async {
    when(
      () => repository.deleteAllUserData(),
    ).thenAnswer((_) async => const Right(unit));

    expect(await useCase(), const Right<Failure, Unit>(unit));
    verify(() => repository.deleteAllUserData()).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('deletes the stored API key from every secure-storage slot', () async {
    when(
      () => repository.deleteAllUserData(),
    ).thenAnswer((_) async => const Right(unit));

    await useCase();

    expect(ai.store.keys, isEmpty);
    expect(ai.store.log, [
      for (final id in SecureCredentialStoreImpl.everySlotProviderId)
        'delete:$id',
    ]);
  });

  test('passes the repository failure through unchanged', () async {
    const failure = CacheFailure('wipe failed');
    when(
      () => repository.deleteAllUserData(),
    ).thenAnswer((_) async => const Left(failure));

    expect(await useCase(), const Left<Failure, Unit>(failure));
    verify(() => repository.deleteAllUserData()).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('a keychain failure stops before any table is wiped, and its '
      'failure never carries the key', () async {
    ai.store.failDeletes = true;

    final result = await useCase();

    expect(result.isLeft(), isTrue);
    final failure = result.getLeft().toNullable()!;
    expect(failure, isA<CacheFailure>());
    expect(failure.message, isNot(contains(testApiKey)));
    expect(failure.toString(), isNot(contains(testApiKey)));
    verifyNever(() => repository.deleteAllUserData());
  });

  group('015 T085 — secure-storage wiper', () {
    test('wipes secure storage before the tables and never restores it '
        'after a successful table wipe', () async {
      when(
        () => repository.deleteAllUserData(),
      ).thenAnswer((_) async => const Right(unit));

      expect(await useCase(), const Right<Failure, Unit>(unit));
      expect(wiper.log, ['wipe']);
    });

    test('a secure-storage wipe failure stops before any table is '
        'wiped', () async {
      const failure = CacheFailure('keychain unavailable');
      wiper.wipeFailure = failure;

      expect(await useCase(), const Left<Failure, Unit>(failure));
      verifyNever(() => repository.deleteAllUserData());
    });

    test('a failed table wipe restores secure storage and reports the '
        'table failure', () async {
      const failure = CacheFailure('wipe failed');
      when(
        () => repository.deleteAllUserData(),
      ).thenAnswer((_) async => const Left(failure));

      expect(await useCase(), const Left<Failure, Unit>(failure));
      expect(wiper.log, ['wipe', 'restore']);
    });

    test('a keychain failure for the AI key stops before secure storage '
        'is wiped', () async {
      ai.store.failDeletes = true;

      await useCase();

      expect(wiper.log, isEmpty);
    });
  });

  group('021 — the cloud copy', () {
    test('"Delete my data" erases the cloud copy by default', () async {
      when(
        () => repository.deleteAllUserData(),
      ).thenAnswer((_) async => const Right(unit));

      await useCase();

      expect(cloud.eraseRequests, [true]);
    });

    test('the Forgot-PIN wipe keeps the cloud copy (session only)', () async {
      when(
        () => repository.deleteAllUserData(),
      ).thenAnswer((_) async => const Right(unit));

      await useCase(eraseCloudCopy: false);

      expect(cloud.eraseRequests, [false]);
    });

    test('an unreachable cloud stops before any table is wiped and restores '
        'secure storage', () async {
      const failure = NetworkFailure('offline');
      cloud = FakeCloudCopyEraser(failWith: failure);
      useCase = buildUseCase();

      expect(await useCase(), const Left<Failure, Unit>(failure));
      verifyNever(() => repository.deleteAllUserData());
      expect(wiper.log, ['wipe', 'restore']);
    });
  });
}
