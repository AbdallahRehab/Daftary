import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/currency/domain/entities/primary_currency_setting.dart';
import 'package:daftary/features/currency/domain/usecases/get_exchange_rates.dart';
import 'package:daftary/features/currency/domain/usecases/get_primary_currency.dart';
import 'package:daftary/features/currency/domain/usecases/remove_exchange_rate.dart';
import 'package:daftary/features/currency/presentation/cubit/exchange_rate_list_cubit.dart';
import 'package:daftary/features/currency/presentation/cubit/exchange_rate_list_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mocktail/mocktail.dart';

class _MockGetPrimary extends Mock implements GetPrimaryCurrency {}

class _MockGetRates extends Mock implements GetExchangeRates {}

class _MockRemove extends Mock implements RemoveExchangeRate {}

ExchangeRate _rate(Currency from, Currency to, int micros) => ExchangeRate(
  currency: from,
  relativeTo: to,
  rateMicros: micros,
  lastUpdatedAt: DateTime(2026, 9),
);

void main() {
  late _MockGetPrimary getPrimary;
  late _MockGetRates getRates;
  late _MockRemove remove;

  final usdEgp = _rate(Currency.usd, Currency.egp, 50250000);
  final eurEgp = _rate(Currency.eur, Currency.egp, 55000000);
  final sarUsd = _rate(Currency.sar, Currency.usd, 266667);

  setUp(() {
    getPrimary = _MockGetPrimary();
    getRates = _MockGetRates();
    remove = _MockRemove();
    when(() => getPrimary()).thenAnswer(
      (_) async => const Right(PrimaryCurrencySetting.defaultSetting),
    );
    when(
      () => getRates(),
    ).thenAnswer((_) async => Right([sarUsd, usdEgp, eurEgp]));
  });

  ExchangeRateListCubit build() =>
      ExchangeRateListCubit(getPrimary, getRates, remove);

  final loaded = ExchangeRateListState(
    status: ExchangeRateListStatus.ready,
    rates: [eurEgp, usdEgp, sarUsd],
  );

  blocTest<ExchangeRateListCubit, ExchangeRateListState>(
    'load: rates against the primary first, stale-primary rates after',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [loaded],
  );

  blocTest<ExchangeRateListCubit, ExchangeRateListState>(
    'load failure',
    build: build,
    setUp: () => when(
      () => getRates(),
    ).thenAnswer((_) async => const Left(CacheFailure('x'))),
    act: (cubit) => cubit.load(),
    expect: () => [
      const ExchangeRateListState(status: ExchangeRateListStatus.loadFailure),
    ],
  );

  blocTest<ExchangeRateListCubit, ExchangeRateListState>(
    'remove drops the currency\'s rates',
    build: build,
    seed: () => loaded,
    setUp: () =>
        when(() => remove('USD')).thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.remove('USD'),
    expect: () => [
      loaded.copyWith(removingCode: 'USD'),
      loaded.copyWith(rates: [eurEgp, sarUsd]),
    ],
  );

  blocTest<ExchangeRateListCubit, ExchangeRateListState>(
    'remove failure keeps the rates and flags the failure',
    build: build,
    seed: () => loaded,
    setUp: () => when(
      () => remove('USD'),
    ).thenAnswer((_) async => const Left(CacheFailure('x'))),
    act: (cubit) => cubit.remove('USD'),
    expect: () => [
      loaded.copyWith(removingCode: 'USD'),
      loaded.copyWith(isRemoveFailing: true),
    ],
  );

  blocTest<ExchangeRateListCubit, ExchangeRateListState>(
    'a second remove while one is in flight is ignored',
    build: build,
    seed: () => loaded,
    setUp: () => when(() => remove(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return const Right(unit);
    }),
    act: (cubit) async {
      final first = cubit.remove('USD');
      await cubit.remove('EUR');
      await first;
    },
    verify: (_) {
      verify(() => remove('USD')).called(1);
      verifyNever(() => remove('EUR'));
    },
  );
}
