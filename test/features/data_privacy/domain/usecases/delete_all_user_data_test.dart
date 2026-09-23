import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/data_privacy/domain/repositories/data_wipe_repository.dart';
import 'package:daftary/features/data_privacy/domain/usecases/delete_all_user_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDataWipeRepository extends Mock implements DataWipeRepository {}

/// T032 — `DeleteAllUserData` is a pure pass-through: the onboarding reset
/// and navigation belong to `DeleteAccountCubit` (research.md Decision 6).
void main() {
  late MockDataWipeRepository repository;
  late DeleteAllUserData useCase;

  setUp(() {
    repository = MockDataWipeRepository();
    useCase = DeleteAllUserData(repository);
  });

  test('returns Right(unit) when the repository wipe succeeds', () async {
    when(
      () => repository.deleteAllUserData(),
    ).thenAnswer((_) async => const Right(unit));

    expect(await useCase(), const Right<Failure, Unit>(unit));
    verify(() => repository.deleteAllUserData()).called(1);
    verifyNoMoreInteractions(repository);
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
}
