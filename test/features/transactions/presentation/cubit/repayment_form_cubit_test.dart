import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/watch_conversion_context.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/usecases/watch_person.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/usecases/record_repayment.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_person_balance.dart';
import 'package:daftary/features/transactions/presentation/cubit/repayment_form_cubit.dart';
import 'package:daftary/features/transactions/presentation/cubit/repayment_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/currency_test_doubles.dart';

class MockRecordRepayment extends Mock implements RecordRepayment {}

class MockWatchPersonBalance extends Mock implements WatchPersonBalance {}

class MockWatchConversionContext extends Mock
    implements WatchConversionContext {}

class MockWatchPerson extends Mock implements WatchPerson {}

void main() {
  late MockRecordRepayment recordRepayment;
  late MockWatchPersonBalance watchBalance;
  late MockWatchConversionContext watchContext;
  late MockWatchPerson watchPerson;
  late StreamController<Either<Failure, PersonBalance>> balanceController;
  late StreamController<Either<Failure, ConversionContext>> contextController;
  late StreamController<Either<Failure, Person>> personController;

  final now = DateTime(2026, 1, 1);
  final saved = MoneyTransaction(
    id: 't1',
    idempotencyKey: 'k',
    personId: 'p1',
    amount: const Money.egp(1),
    direction: TransactionDirection.received,
    kind: TransactionKind.repayment,
    date: now,
    createdAt: now,
  );

  setUpAll(() {
    registerFallbackValue(const Money.egp(0));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    recordRepayment = MockRecordRepayment();
    watchBalance = MockWatchPersonBalance();
    watchContext = MockWatchConversionContext();
    watchPerson = MockWatchPerson();
    balanceController = StreamController<Either<Failure, PersonBalance>>();
    contextController = StreamController<Either<Failure, ConversionContext>>();
    personController = StreamController<Either<Failure, Person>>();
    when(() => watchBalance('p1')).thenAnswer((_) => balanceController.stream);
    when(() => watchContext()).thenAnswer((_) => contextController.stream);
    when(() => watchPerson('p1')).thenAnswer((_) => personController.stream);
    when(
      () => recordRepayment(
        idempotencyKey: any(named: 'idempotencyKey'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Right(saved));
  });

  tearDown(() async {
    await balanceController.close();
    await contextController.close();
    await personController.close();
  });

  RepaymentFormCubit buildCubit({
    void Function(String message, {Object? error})? log,
  }) => RepaymentFormCubit(
    recordRepayment,
    getPrimaryCurrencyReturning(),
    watchBalance,
    watchContext,
    watchPerson,
    'p1',
    log: log,
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  PersonBalance owed(int minor) =>
      PersonBalance(personId: 'p1', net: Money.egp(minor));

  void verifyRecordCalls(int times) {
    Future<Object?> call() => recordRepayment(
      idempotencyKey: any(named: 'idempotencyKey'),
      personId: any(named: 'personId'),
      amount: any(named: 'amount'),
      date: any(named: 'date'),
      note: any(named: 'note'),
    );
    if (times == 0) {
      verifyNever(call);
    } else {
      verify(call).called(times);
    }
  }

  test('subscribes to the balance and the conversion context', () async {
    final cubit = buildCubit()..subscribe();

    verify(() => watchBalance('p1')).called(1);
    verify(() => watchContext()).called(1);
    expect(balanceController.hasListener, isTrue);
    expect(contextController.hasListener, isTrue);
    await cubit.close();
  });

  test('submit does nothing until both the balance and the context '
      'have emitted', () async {
    final cubit = buildCubit()..subscribe();
    cubit.amountChanged('100');

    await cubit.submit();
    verifyRecordCalls(0);

    balanceController.add(Right(owed(100000)));
    await settle();
    await cubit.submit();
    verifyRecordCalls(0);

    contextController.add(const Right(ConversionContext.egpOnly));
    await settle();
    expect(cubit.state.balanceLoaded, isTrue);
    await cubit.submit();
    verifyRecordCalls(1);
    await cubit.close();
  });

  test(
    'a preview is exposed once loaded and follows the typed amount',
    () async {
      final cubit = buildCubit()..subscribe();
      balanceController.add(Right(owed(100000)));
      contextController.add(const Right(ConversionContext.egpOnly));
      await settle();

      cubit.amountChanged('400');

      expect(cubit.state.preview?.resulting, const Money.egp(60000));
      expect(cubit.state.preview?.flips, isFalse);
      await cubit.close();
    },
  );

  test('a flipping repayment asks for confirmation first; confirmFlip saves '
      'once with the same idempotency key', () async {
    final cubit = buildCubit()..subscribe();
    balanceController.add(Right(owed(100000)));
    contextController.add(const Right(ConversionContext.egpOnly));
    await settle();
    cubit.amountChanged('1500');

    await cubit.submit();

    expect(cubit.state.needsFlipConfirmation, isTrue);
    expect(cubit.state.status, RepaymentFormStatus.editing);
    verifyRecordCalls(0);

    final key = cubit.state.idempotencyKey;
    await cubit.confirmFlip();

    expect(cubit.state.needsFlipConfirmation, isFalse);
    expect(cubit.state.status, RepaymentFormStatus.success);
    final captured = verify(
      () => recordRepayment(
        idempotencyKey: captureAny(named: 'idempotencyKey'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    )..called(1);
    expect(captured.captured.single, key);
    await cubit.close();
  });

  test('cancelling the flip confirmation saves nothing', () async {
    final cubit = buildCubit()..subscribe();
    balanceController.add(Right(owed(100000)));
    contextController.add(const Right(ConversionContext.egpOnly));
    await settle();
    cubit.amountChanged('1500');
    await cubit.submit();

    cubit.cancelFlip();

    expect(cubit.state.needsFlipConfirmation, isFalse);
    verifyRecordCalls(0);
    await cubit.close();
  });

  test(
    'a non-flipping repayment saves immediately without confirmation',
    () async {
      final cubit = buildCubit()..subscribe();
      balanceController.add(Right(owed(100000)));
      contextController.add(const Right(ConversionContext.egpOnly));
      await settle();
      cubit.amountChanged('400');

      await cubit.submit();

      expect(cubit.state.needsFlipConfirmation, isFalse);
      verifyRecordCalls(1);
      await cubit.close();
    },
  );

  test('close cancels every subscription', () async {
    final cubit = buildCubit()..subscribe();
    expect(balanceController.hasListener, isTrue);

    await cubit.close();

    expect(balanceController.hasListener, isFalse);
    expect(contextController.hasListener, isFalse);
    expect(personController.hasListener, isFalse);
  });

  test('a failed balance read keeps saving disabled; a later success '
      'enables it and clears the failure', () async {
    final cubit = buildCubit()..subscribe();
    cubit.amountChanged('100');
    balanceController.add(Left(CacheFailure('boom')));
    contextController.add(const Right(ConversionContext.egpOnly));
    await settle();

    expect(cubit.state.balanceLoaded, isFalse);
    expect(cubit.state.failure, isA<CacheFailure>());
    await cubit.submit();
    verifyRecordCalls(0);

    balanceController.add(Right(owed(100000)));
    await settle();

    expect(cubit.state.balanceLoaded, isTrue);
    expect(cubit.state.failure, isNull);
    expect(cubit.state.status, RepaymentFormStatus.editing);
    await cubit.close();
  });

  test('balanceLoadFailed is false while loading, true after a failed read '
      'and false again once it loads (T096)', () async {
    final cubit = buildCubit()..subscribe();
    expect(cubit.state.balanceLoadFailed, isFalse);

    balanceController.add(Left(CacheFailure('boom')));
    contextController.add(const Right(ConversionContext.egpOnly));
    await settle();
    expect(cubit.state.balanceLoadFailed, isTrue);

    balanceController.add(Right(owed(100000)));
    await settle();
    expect(cubit.state.balanceLoadFailed, isFalse);
    await cubit.close();
  });

  test('a failed save is not a balance load failure (T096)', () async {
    when(
      () => recordRepayment(
        idempotencyKey: any(named: 'idempotencyKey'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Left(CacheFailure('save failed')));
    final cubit = buildCubit()..subscribe();
    balanceController.add(Right(owed(100000)));
    contextController.add(const Right(ConversionContext.egpOnly));
    await settle();
    cubit.amountChanged('10');
    await cubit.submit();

    expect(cubit.state.failure, isA<CacheFailure>());
    expect(cubit.state.balanceLoadFailed, isFalse);
    await cubit.close();
  });

  test('a WatchPerson failure keeps the fallback label, does not break '
      'the form and is logged once per failure (T102)', () async {
    final logged = <({String message, Object? error})>[];
    final cubit = buildCubit(
      log: (message, {error}) => logged.add((message: message, error: error)),
    )..subscribe();
    balanceController.add(Right(owed(100000)));
    contextController.add(const Right(ConversionContext.egpOnly));

    personController.add(Left(CacheFailure('no person')));
    personController.addError(StateError('stream broke'));
    await settle();

    expect(cubit.state.personName, isNull);
    expect(cubit.state.balanceLoaded, isTrue);
    expect(cubit.state.failure, isNull);
    expect(logged, hasLength(2));
    expect(logged[0].error, 'no person');
    expect(logged[1].error, isA<StateError>());
    await cubit.close();
  });

  test('subscribe() again after a failed read resets to loading, then '
      'loads (T096 retry)', () async {
    final cubit = buildCubit()..subscribe();
    balanceController.add(Left(CacheFailure('boom')));
    contextController.add(const Right(ConversionContext.egpOnly));
    await settle();
    expect(cubit.state.balanceLoadFailed, isTrue);

    final retryBalance = StreamController<Either<Failure, PersonBalance>>();
    final retryContext = StreamController<Either<Failure, ConversionContext>>();
    addTearDown(retryBalance.close);
    addTearDown(retryContext.close);
    when(() => watchBalance('p1')).thenAnswer((_) => retryBalance.stream);
    when(() => watchContext()).thenAnswer((_) => retryContext.stream);
    when(() => watchPerson('p1')).thenAnswer((_) => const Stream.empty());

    cubit.subscribe();
    await settle();
    // The failed streams were cancelled, so a late emission cannot leak in.
    expect(balanceController.hasListener, isFalse);
    expect(contextController.hasListener, isFalse);
    expect(cubit.state.balanceLoaded, isFalse);
    expect(cubit.state.failure, isNull);
    expect(cubit.state.balanceLoadFailed, isFalse);
    expect(cubit.state.status, RepaymentFormStatus.editing);

    retryBalance.add(Right(owed(100000)));
    retryContext.add(const Right(ConversionContext.egpOnly));
    await settle();
    expect(cubit.state.balanceLoaded, isTrue);
    await cubit.close();
  });
}
