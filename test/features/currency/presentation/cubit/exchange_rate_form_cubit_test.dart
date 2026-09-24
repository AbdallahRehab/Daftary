import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/currency/domain/entities/currency_failures.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/currency/domain/entities/primary_currency_setting.dart';
import 'package:daftary/features/currency/domain/usecases/get_exchange_rates.dart';
import 'package:daftary/features/currency/domain/usecases/get_primary_currency.dart';
import 'package:daftary/features/currency/domain/usecases/set_exchange_rate.dart';
import 'package:daftary/features/currency/presentation/cubit/exchange_rate_form_cubit.dart';
import 'package:daftary/features/currency/presentation/cubit/exchange_rate_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mocktail/mocktail.dart';

class _MockGetPrimary extends Mock implements GetPrimaryCurrency {}

class _MockGetRates extends Mock implements GetExchangeRates {}

class _MockSetRate extends Mock implements SetExchangeRate {}

void main() {
  late _MockGetPrimary getPrimary;
  late _MockGetRates getRates;
  late _MockSetRate setRate;

  final usdEgp = ExchangeRate(
    currency: Currency.usd,
    relativeTo: Currency.egp,
    rateMicros: 50250000,
    lastUpdatedAt: DateTime(2026, 9),
  );
  const nonEgp = [
    Currency.usd,
    Currency.eur,
    Currency.sar,
    Currency.aed,
    Currency.gbp,
  ];

  setUp(() {
    getPrimary = _MockGetPrimary();
    getRates = _MockGetRates();
    setRate = _MockSetRate();
    when(() => getPrimary()).thenAnswer(
      (_) async => const Right(PrimaryCurrencySetting.defaultSetting),
    );
    when(() => getRates()).thenAnswer((_) async => Right([usdEgp]));
  });

  ExchangeRateFormCubit build() =>
      ExchangeRateFormCubit(getPrimary, getRates, setRate);

  void stubSave(Either<Failure, ExchangeRate> result) {
    when(
      () => setRate(
        currencyCode: any(named: 'currencyCode'),
        relativeToCurrencyCode: any(named: 'relativeToCurrencyCode'),
        rate: any(named: 'rate'),
      ),
    ).thenAnswer((_) async => result);
  }

  const newForm = ExchangeRateFormState(
    status: ExchangeRateFormStatus.ready,
    currency: Currency.usd,
    availableCurrencies: nonEgp,
  );

  group('load', () {
    blocTest<ExchangeRateFormCubit, ExchangeRateFormState>(
      'new rate: every currency except the primary, first preselected',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [newForm],
    );

    blocTest<ExchangeRateFormCubit, ExchangeRateFormState>(
      'new rate with initialCode preselects it',
      build: build,
      act: (cubit) => cubit.load(initialCode: 'SAR'),
      expect: () => [newForm.copyWith(currency: Currency.sar)],
    );

    blocTest<ExchangeRateFormCubit, ExchangeRateFormState>(
      'edit prefills the stored rate and locks the currency',
      build: build,
      act: (cubit) => cubit.load(editingCode: 'USD'),
      expect: () => [newForm.copyWith(isEditing: true, rateText: '50.25')],
    );

    blocTest<ExchangeRateFormCubit, ExchangeRateFormState>(
      'load failure',
      build: build,
      setUp: () => when(
        () => getPrimary(),
      ).thenAnswer((_) async => const Left(CacheFailure('x'))),
      act: (cubit) => cubit.load(),
      expect: () => [
        const ExchangeRateFormState(status: ExchangeRateFormStatus.loadFailure),
      ],
    );
  });

  blocTest<ExchangeRateFormCubit, ExchangeRateFormState>(
    'selectCurrency is ignored for the primary and while editing',
    build: build,
    seed: () => newForm,
    act: (cubit) {
      cubit
        ..selectCurrency(Currency.egp)
        ..selectCurrency(Currency.gbp);
    },
    expect: () => [newForm.copyWith(currency: Currency.gbp)],
  );

  blocTest<ExchangeRateFormCubit, ExchangeRateFormState>(
    'save parses Arabic digits and stores against the primary',
    build: build,
    seed: () => newForm.copyWith(rateText: '٥٠٫٢٥'),
    setUp: () => stubSave(Right(usdEgp)),
    act: (cubit) => cubit.save(),
    expect: () => [
      newForm.copyWith(rateText: '٥٠٫٢٥', isSubmitting: true),
      newForm.copyWith(rateText: '٥٠٫٢٥', isSaved: true),
    ],
    verify: (_) => verify(
      () => setRate(
        currencyCode: 'USD',
        relativeToCurrencyCode: 'EGP',
        rate: 50.25,
      ),
    ).called(1),
  );

  for (final bad in ['', '0', '-5', 'abc', '1.2.3', '0.0000001']) {
    blocTest<ExchangeRateFormCubit, ExchangeRateFormState>(
      'save rejects "$bad" without calling the use case',
      build: build,
      seed: () => newForm.copyWith(rateText: bad),
      act: (cubit) => cubit.save(),
      expect: () => [
        newForm.copyWith(rateText: bad, isSubmitting: true),
        newForm.copyWith(rateText: bad, showRateError: true),
      ],
      verify: (_) => verifyNever(
        () => setRate(
          currencyCode: any(named: 'currencyCode'),
          relativeToCurrencyCode: any(named: 'relativeToCurrencyCode'),
          rate: any(named: 'rate'),
        ),
      ),
    );
  }

  blocTest<ExchangeRateFormCubit, ExchangeRateFormState>(
    'typing clears the rate error',
    build: build,
    seed: () => newForm.copyWith(showRateError: true),
    act: (cubit) => cubit.rateChanged('5'),
    expect: () => [newForm.copyWith(rateText: '5')],
  );

  blocTest<ExchangeRateFormCubit, ExchangeRateFormState>(
    'InvalidExchangeRateFailure from the use case shows the rate error',
    build: build,
    seed: () => newForm.copyWith(rateText: '5'),
    setUp: () => stubSave(const Left(InvalidExchangeRateFailure())),
    act: (cubit) => cubit.save(),
    expect: () => [
      newForm.copyWith(rateText: '5', isSubmitting: true),
      newForm.copyWith(rateText: '5', showRateError: true),
    ],
  );

  blocTest<ExchangeRateFormCubit, ExchangeRateFormState>(
    'a storage failure flags isSaveFailing and re-enables Save',
    build: build,
    seed: () => newForm.copyWith(rateText: '5'),
    setUp: () => stubSave(const Left(CacheFailure('x'))),
    act: (cubit) => cubit.save(),
    expect: () => [
      newForm.copyWith(rateText: '5', isSubmitting: true),
      newForm.copyWith(rateText: '5', isSaveFailing: true),
    ],
    verify: (cubit) => expect(cubit.state.canSave, isTrue),
  );

  blocTest<ExchangeRateFormCubit, ExchangeRateFormState>(
    'duplicate Save taps store the rate once',
    build: build,
    seed: () => newForm.copyWith(rateText: '5'),
    setUp: () =>
        when(
          () => setRate(
            currencyCode: any(named: 'currencyCode'),
            relativeToCurrencyCode: any(named: 'relativeToCurrencyCode'),
            rate: any(named: 'rate'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return Right(usdEgp);
        }),
    act: (cubit) async {
      final first = cubit.save();
      await cubit.save();
      await first;
      await cubit.save(); // after saved: still ignored
    },
    verify: (_) => verify(
      () => setRate(
        currencyCode: any(named: 'currencyCode'),
        relativeToCurrencyCode: any(named: 'relativeToCurrencyCode'),
        rate: any(named: 'rate'),
      ),
    ).called(1),
  );
}
