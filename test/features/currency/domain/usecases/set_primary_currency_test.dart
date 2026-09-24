import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/currency/domain/entities/currency_failures.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/currency/domain/entities/primary_currency_setting.dart';
import 'package:daftary/features/currency/domain/ports/currency_usage_checker.dart';
import 'package:daftary/features/currency/domain/repositories/currency_repository.dart';
import 'package:daftary/features/currency/domain/usecases/set_exchange_rate.dart';
import 'package:daftary/features/currency/domain/usecases/set_primary_currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements CurrencyRepository {}

class _MockUsageChecker extends Mock implements CurrencyUsageChecker {}

/// T043 — FR-012's forced-rate-on-switch rule. The cross-feature "is this
/// currency used anywhere" read is a single port ([CurrencyUsageChecker])
/// composed over every amount-bearing table; it is mocked here.
void main() {
  late _MockRepository repository;
  late _MockUsageChecker usage;
  late SetPrimaryCurrency setPrimary;

  final egpToUsd = ExchangeRate(
    currency: Currency.egp,
    relativeTo: Currency.usd,
    rateMicros: 20000,
    lastUpdatedAt: DateTime(2026, 9),
  );

  setUp(() {
    repository = _MockRepository();
    usage = _MockUsageChecker();
    setPrimary = SetPrimaryCurrency(
      repository,
      usage,
      SetExchangeRate(repository),
    );
    when(() => repository.getPrimaryCurrency()).thenAnswer(
      (_) async => const Right(PrimaryCurrencySetting.defaultSetting),
    );
    when(
      () => repository.setPrimaryCurrency(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.getExchangeRates(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => repository.setExchangeRate(
        currencyCode: any(named: 'currencyCode'),
        relativeToCurrencyCode: any(named: 'relativeToCurrencyCode'),
        rate: any(named: 'rate'),
      ),
    ).thenAnswer((_) async => Right(egpToUsd));
  });

  test('switching to the current primary is a no-op success', () async {
    final result = await setPrimary(newPrimaryCurrencyCode: 'EGP');

    expect(result, const Right<Failure, Unit>(unit));
    verifyNever(() => repository.setPrimaryCurrency(any()));
    verifyNever(() => usage.isCurrencyInUse(any()));
  });

  test('an unknown code fails with CurrencyNotFoundFailure', () async {
    final result = await setPrimary(newPrimaryCurrencyCode: 'XXX');

    expect(result.getLeft().toNullable(), isA<CurrencyNotFoundFailure>());
    verifyNever(() => repository.setPrimaryCurrency(any()));
  });

  test(
    'succeeds without a rate when no record uses the current primary',
    () async {
      when(
        () => usage.isCurrencyInUse('EGP'),
      ).thenAnswer((_) async => const Right(false));

      final result = await setPrimary(newPrimaryCurrencyCode: 'USD');

      expect(result.isRight(), isTrue);
      verify(() => repository.setPrimaryCurrency('USD')).called(1);
    },
  );

  test(
    'records in the current primary and no rate → '
    'RateRequiredForSwitchFailure(previous) and no switch (FR-012)',
    () async {
      when(
        () => usage.isCurrencyInUse('EGP'),
      ).thenAnswer((_) async => const Right(true));

      final result = await setPrimary(newPrimaryCurrencyCode: 'USD');

      final failure = result.getLeft().toNullable();
      expect(failure, isA<RateRequiredForSwitchFailure>());
      expect(
        (failure! as RateRequiredForSwitchFailure).previousPrimary,
        Currency.egp,
      );
      verifyNever(() => repository.setPrimaryCurrency(any()));
    },
  );

  test(
    'records in use but a (previous → new) rate already exists → switches',
    () async {
      when(
        () => usage.isCurrencyInUse('EGP'),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => repository.getExchangeRates(),
      ).thenAnswer((_) async => Right([egpToUsd]));

      final result = await setPrimary(newPrimaryCurrencyCode: 'USD');

      expect(result.isRight(), isTrue);
      verify(() => repository.setPrimaryCurrency('USD')).called(1);
    },
  );

  test('a rate in the wrong direction does not satisfy the check', () async {
    when(
      () => usage.isCurrencyInUse('EGP'),
    ).thenAnswer((_) async => const Right(true));
    when(() => repository.getExchangeRates()).thenAnswer(
      (_) async => Right([
        ExchangeRate(
          currency: Currency.usd,
          relativeTo: Currency.egp,
          rateMicros: 50000000,
          lastUpdatedAt: DateTime(2026, 9),
        ),
      ]),
    );

    final result = await setPrimary(newPrimaryCurrencyCode: 'USD');

    expect(result.getLeft().toNullable(), isA<RateRequiredForSwitchFailure>());
  });

  test(
    'rateForPreviousPrimary stores (previous → new) first, then switches',
    () async {
      when(
        () => usage.isCurrencyInUse('EGP'),
      ).thenAnswer((_) async => const Right(true));

      final result = await setPrimary(
        newPrimaryCurrencyCode: 'USD',
        rateForPreviousPrimary: 0.02,
      );

      expect(result.isRight(), isTrue);
      verifyInOrder([
        () => repository.setExchangeRate(
          currencyCode: 'EGP',
          relativeToCurrencyCode: 'USD',
          rate: 0.02,
        ),
        () => repository.setPrimaryCurrency('USD'),
      ]);
    },
  );

  test(
    'an invalid rateForPreviousPrimary is rejected and nothing is written',
    () async {
      for (final bad in [0.0, -3.0, double.nan]) {
        final result = await setPrimary(
          newPrimaryCurrencyCode: 'USD',
          rateForPreviousPrimary: bad,
        );
        expect(
          result.getLeft().toNullable(),
          isA<InvalidExchangeRateFailure>(),
        );
      }
      verifyNever(
        () => repository.setExchangeRate(
          currencyCode: any(named: 'currencyCode'),
          relativeToCurrencyCode: any(named: 'relativeToCurrencyCode'),
          rate: any(named: 'rate'),
        ),
      );
      verifyNever(() => repository.setPrimaryCurrency(any()));
    },
  );

  test(
    'a usage-check failure is propagated, never treated as "unused"',
    () async {
      when(
        () => usage.isCurrencyInUse('EGP'),
      ).thenAnswer((_) async => const Left(CacheFailure('boom')));

      final result = await setPrimary(newPrimaryCurrencyCode: 'USD');

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
      verifyNever(() => repository.setPrimaryCurrency(any()));
    },
  );

  test(
    'checks usage of the CURRENT primary, not EGP, after an earlier switch',
    () async {
      when(() => repository.getPrimaryCurrency()).thenAnswer(
        (_) async =>
            const Right(PrimaryCurrencySetting(currency: Currency.sar)),
      );
      when(
        () => usage.isCurrencyInUse('SAR'),
      ).thenAnswer((_) async => const Right(true));

      final result = await setPrimary(newPrimaryCurrencyCode: 'EGP');

      final failure = result.getLeft().toNullable();
      expect(
        (failure! as RateRequiredForSwitchFailure).previousPrimary,
        Currency.sar,
      );
    },
  );
}
