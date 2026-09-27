import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/currency/domain/entities/currency_failures.dart';
import 'package:daftary/features/currency/domain/entities/primary_currency_setting.dart';
import 'package:daftary/features/currency/domain/usecases/get_primary_currency.dart';
import 'package:daftary/features/currency/domain/usecases/set_primary_currency.dart';
import 'package:daftary/features/currency/domain/usecases/watch_primary_currency.dart';
import 'package:daftary/features/currency/presentation/cubit/primary_currency_cubit.dart';
import 'package:daftary/features/currency/presentation/cubit/primary_currency_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mocktail/mocktail.dart';

class _MockGetPrimary extends Mock implements GetPrimaryCurrency {}

class _MockSetPrimary extends Mock implements SetPrimaryCurrency {}

/// 021: the Cubit watches; these emit the mocked read's answer once.
class _WatchPrimaryFrom implements WatchPrimaryCurrency {
  _WatchPrimaryFrom(this.get);

  final GetPrimaryCurrency get;

  @override
  Stream<Either<Failure, PrimaryCurrencySetting>> call() =>
      Stream.fromFuture(get());
}

void main() {
  late _MockGetPrimary getPrimary;
  late _MockSetPrimary setPrimary;

  const ready = PrimaryCurrencyState(status: PrimaryCurrencyStatus.ready);
  const pending = PrimaryCurrencyState(
    status: PrimaryCurrencyStatus.ready,
    pendingTarget: Currency.usd,
    rateRequiredFor: Currency.egp,
  );

  setUp(() {
    getPrimary = _MockGetPrimary();
    setPrimary = _MockSetPrimary();
    when(() => getPrimary()).thenAnswer(
      (_) async => const Right(PrimaryCurrencySetting.defaultSetting),
    );
  });

  PrimaryCurrencyCubit build() =>
      PrimaryCurrencyCubit(_WatchPrimaryFrom(getPrimary), setPrimary);

  void stubSet(Either<Failure, Unit> result) {
    when(
      () => setPrimary(
        newPrimaryCurrencyCode: any(named: 'newPrimaryCurrencyCode'),
        rateForPreviousPrimary: any(named: 'rateForPreviousPrimary'),
      ),
    ).thenAnswer((_) async => result);
  }

  blocTest<PrimaryCurrencyCubit, PrimaryCurrencyState>(
    'subscribe emits ready with the stored primary',
    build: build,
    setUp: () => when(() => getPrimary()).thenAnswer(
      (_) async => const Right(PrimaryCurrencySetting(currency: Currency.sar)),
    ),
    act: (cubit) => cubit.subscribe(),
    expect: () => [ready.copyWith(primary: Currency.sar)],
  );

  blocTest<PrimaryCurrencyCubit, PrimaryCurrencyState>(
    'subscribe failure emits loadFailure',
    build: build,
    setUp: () => when(
      () => getPrimary(),
    ).thenAnswer((_) async => const Left(CacheFailure('x'))),
    act: (cubit) => cubit.subscribe(),
    expect: () => [
      const PrimaryCurrencyState(status: PrimaryCurrencyStatus.loadFailure),
    ],
  );

  blocTest<PrimaryCurrencyCubit, PrimaryCurrencyState>(
    'change succeeds: submitting, then the new primary + changed outcome',
    build: build,
    seed: () => ready,
    setUp: () => stubSet(const Right(unit)),
    act: (cubit) => cubit.changePrimary(Currency.usd),
    expect: () => [
      ready.copyWith(isSubmitting: true),
      ready.copyWith(
        primary: Currency.usd,
        outcome: PrimaryCurrencyChangeOutcome.changed,
      ),
    ],
    verify: (_) =>
        verify(() => setPrimary(newPrimaryCurrencyCode: 'USD')).called(1),
  );

  blocTest<PrimaryCurrencyCubit, PrimaryCurrencyState>(
    'choosing the current primary does nothing',
    build: build,
    seed: () => ready,
    act: (cubit) => cubit.changePrimary(Currency.egp),
    expect: () => <PrimaryCurrencyState>[],
  );

  blocTest<PrimaryCurrencyCubit, PrimaryCurrencyState>(
    'RateRequiredForSwitchFailure surfaces the rate prompt (FR-012)',
    build: build,
    seed: () => ready,
    setUp: () => stubSet(Left(RateRequiredForSwitchFailure(Currency.egp))),
    act: (cubit) => cubit.changePrimary(Currency.usd),
    expect: () => [ready.copyWith(isSubmitting: true), pending],
    verify: (cubit) => expect(cubit.state.isRatePromptPending, isTrue),
  );

  blocTest<PrimaryCurrencyCubit, PrimaryCurrencyState>(
    'a generic failure reports failed and keeps the primary',
    build: build,
    seed: () => ready,
    setUp: () => stubSet(const Left(CacheFailure('x'))),
    act: (cubit) => cubit.changePrimary(Currency.usd),
    expect: () => [
      ready.copyWith(isSubmitting: true),
      ready.copyWith(outcome: PrimaryCurrencyChangeOutcome.failed),
    ],
  );

  blocTest<PrimaryCurrencyCubit, PrimaryCurrencyState>(
    'confirming with a rate completes the switch (Arabic digits accepted)',
    build: build,
    seed: () => pending,
    setUp: () => stubSet(const Right(unit)),
    act: (cubit) => cubit.confirmSwitchWithRate('٠٫٠٢'),
    expect: () => [
      pending.copyWith(isSubmitting: true),
      ready.copyWith(
        primary: Currency.usd,
        outcome: PrimaryCurrencyChangeOutcome.changed,
      ),
    ],
    verify: (_) => verify(
      () => setPrimary(
        newPrimaryCurrencyCode: 'USD',
        rateForPreviousPrimary: 0.02,
      ),
    ).called(1),
  );

  blocTest<PrimaryCurrencyCubit, PrimaryCurrencyState>(
    'an unparseable / zero rate keeps the prompt and reports invalidRate',
    build: build,
    seed: () => pending,
    act: (cubit) => cubit.confirmSwitchWithRate('0'),
    expect: () => [
      pending.copyWith(isSubmitting: true),
      pending.copyWith(outcome: PrimaryCurrencyChangeOutcome.invalidRate),
    ],
    verify: (_) => verifyNever(
      () => setPrimary(
        newPrimaryCurrencyCode: any(named: 'newPrimaryCurrencyCode'),
        rateForPreviousPrimary: any(named: 'rateForPreviousPrimary'),
      ),
    ),
  );

  blocTest<PrimaryCurrencyCubit, PrimaryCurrencyState>(
    'cancelling the prompt leaves the primary unchanged',
    build: build,
    seed: () => pending,
    act: (cubit) => cubit.cancelPendingSwitch(),
    expect: () => [ready],
  );

  blocTest<PrimaryCurrencyCubit, PrimaryCurrencyState>(
    'duplicate taps while submitting start only one switch',
    build: build,
    seed: () => ready,
    setUp: () =>
        when(
          () => setPrimary(
            newPrimaryCurrencyCode: any(named: 'newPrimaryCurrencyCode'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return const Right(unit);
        }),
    act: (cubit) async {
      final first = cubit.changePrimary(Currency.usd);
      await cubit.changePrimary(Currency.eur);
      await cubit.changePrimary(Currency.usd);
      await first;
    },
    verify: (cubit) {
      verify(
        () => setPrimary(
          newPrimaryCurrencyCode: any(named: 'newPrimaryCurrencyCode'),
        ),
      ).called(1);
      expect(cubit.state.primary, Currency.usd);
    },
  );
}
