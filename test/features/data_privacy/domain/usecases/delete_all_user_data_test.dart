import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/data/datasources/secure_credential_store_impl.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/purge_ai_assistant_credentials.dart';
import 'package:daftary/features/data_privacy/domain/repositories/data_wipe_repository.dart';
import 'package:daftary/features/data_privacy/domain/usecases/delete_all_user_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../ai_assistant/helpers/ai_assistant_harness.dart';

class MockDataWipeRepository extends Mock implements DataWipeRepository {}

/// T032 — `DeleteAllUserData` wipes every table; the onboarding reset and
/// navigation belong to `DeleteAccountCubit` (research.md Decision 6).
///
/// 014 T084 — it also forgets the AI assistant's API key, which lives in
/// secure storage where the table wipe cannot reach. Exercised against the
/// real `AIAssistantRepositoryImpl` with a fake keychain.
void main() {
  late MockDataWipeRepository repository;
  late AIAssistantHarness ai;
  late DeleteAllUserData useCase;

  setUp(() async {
    repository = MockDataWipeRepository();
    ai = AIAssistantHarness.open();
    useCase = DeleteAllUserData(
      repository,
      PurgeAIAssistantCredentials(ai.repository),
    );
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
}
