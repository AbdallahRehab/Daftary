import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/watch_conversion_context.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/usecases/watch_person.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/usecases/record_repayment.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_person_balance.dart';
import 'package:daftary/features/transactions/presentation/cubit/repayment_form_cubit.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'currency_test_doubles.dart';

class MockRecordRepayment extends Mock implements RecordRepayment {}

class MockWatchPersonBalance extends Mock implements WatchPersonBalance {}

class MockWatchConversionContext extends Mock
    implements WatchConversionContext {}

class MockWatchPerson extends Mock implements WatchPerson {}

/// A [RepaymentFormCubit] over mocked use cases. Streams default to "never
/// emits", i.e. the preview data has not loaded yet.
RepaymentFormCubit repaymentCubitWith({
  required RecordRepayment recordRepayment,
  String personId = 'p1',
  Currency primary = Currency.egp,
  Stream<Either<Failure, PersonBalance>>? balance,
  Stream<Either<Failure, ConversionContext>>? context,
  Stream<Either<Failure, Person>>? person,
}) {
  final watchBalance = MockWatchPersonBalance();
  final watchContext = MockWatchConversionContext();
  final watchPerson = MockWatchPerson();
  when(
    () => watchBalance(any()),
  ).thenAnswer((_) => balance ?? const Stream.empty());
  when(() => watchContext()).thenAnswer((_) => context ?? const Stream.empty());
  when(
    () => watchPerson(any()),
  ).thenAnswer((_) => person ?? const Stream.empty());
  return RepaymentFormCubit(
    recordRepayment,
    getPrimaryCurrencyReturning(primary),
    watchBalance,
    watchContext,
    watchPerson,
    personId,
  );
}
