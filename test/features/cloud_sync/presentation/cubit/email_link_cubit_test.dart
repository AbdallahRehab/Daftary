import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/confirm_email_code.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/request_email_code.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/email_link_cubit.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/email_link_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '_fakes.dart';

/// 021 T079: EmailLinkCubit — initial, codeSent, verifying, success and
/// failure, with a duplicate-submit guard.
void main() {
  late MockCloudSyncRepository repository;
  const email = 'ahmed@gmail.com';
  const invalidCode = EmailAuthFailure(EmailAuthErrorReason.invalidCode);

  setUp(() {
    repository = MockCloudSyncRepository();
    when(
      () => repository.requestEmailCode(
        any(),
        linkCurrent: any(named: 'linkCurrent'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.confirmEmailCode(
        any(),
        any(),
        linkCurrent: any(named: 'linkCurrent'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  EmailLinkCubit build() => EmailLinkCubit(
    RequestEmailCode(repository),
    ConfirmEmailCode(repository),
  );

  const sentState = EmailLinkState(
    step: EmailLinkStep.codeSent,
    email: email,
    codeSent: true,
  );

  blocTest<EmailLinkCubit, EmailLinkState>(
    'link: initial -> sending -> codeSent -> verifying -> success',
    build: build,
    act: (cubit) async {
      await cubit.requestCode(' $email ');
      await cubit.confirmCode('123456');
    },
    expect: () => [
      const EmailLinkState(step: EmailLinkStep.sending, email: email),
      sentState,
      sentState.copyWith(step: EmailLinkStep.verifying),
      const EmailLinkState(step: EmailLinkStep.success, codeSent: true),
    ],
    verify: (_) {
      verify(
        () => repository.requestEmailCode(email, linkCurrent: true),
      ).called(1);
      verify(
        () => repository.confirmEmailCode(email, '123456', linkCurrent: true),
      ).called(1);
    },
  );

  blocTest<EmailLinkCubit, EmailLinkState>(
    'sign in uses linkCurrent: false',
    build: build,
    act: (cubit) async {
      cubit.start(EmailLinkMode.signIn);
      await cubit.requestCode(email);
    },
    verify: (_) => verify(
      () => repository.requestEmailCode(email, linkCurrent: false),
    ).called(1),
  );

  blocTest<EmailLinkCubit, EmailLinkState>(
    'an invalid address fails without a request',
    build: build,
    act: (cubit) => cubit.requestCode('not-an-email'),
    expect: () => [
      const EmailLinkState(step: EmailLinkStep.sending, email: 'not-an-email'),
      const EmailLinkState(
        step: EmailLinkStep.failure,
        email: 'not-an-email',
        failure: EmailAuthFailure(EmailAuthErrorReason.invalidEmail),
      ),
    ],
    verify: (_) => verifyNever(
      () => repository.requestEmailCode(
        any(),
        linkCurrent: any(named: 'linkCurrent'),
      ),
    ),
  );

  blocTest<EmailLinkCubit, EmailLinkState>(
    'a wrong code fails and keeps the code form; a retry can succeed',
    build: () {
      var calls = 0;
      when(
        () => repository.confirmEmailCode(
          any(),
          any(),
          linkCurrent: any(named: 'linkCurrent'),
        ),
      ).thenAnswer(
        (_) async => calls++ == 0 ? const Left(invalidCode) : const Right(unit),
      );
      return build();
    },
    seed: () => sentState,
    act: (cubit) async {
      await cubit.confirmCode('000000');
      await cubit.confirmCode('123456');
    },
    expect: () => [
      sentState.copyWith(step: EmailLinkStep.verifying),
      sentState.copyWith(step: EmailLinkStep.failure, failure: invalidCode),
      sentState.copyWith(step: EmailLinkStep.verifying),
      const EmailLinkState(step: EmailLinkStep.success, codeSent: true),
    ],
  );

  blocTest<EmailLinkCubit, EmailLinkState>(
    'a second submit while one runs is ignored',
    build: () {
      final gate = Completer<Either<Failure, Unit>>();
      when(
        () => repository.requestEmailCode(
          any(),
          linkCurrent: any(named: 'linkCurrent'),
        ),
      ).thenAnswer((_) => gate.future);
      Future<void>.delayed(
        const Duration(milliseconds: 10),
        () => gate.complete(const Right(unit)),
      );
      return build();
    },
    act: (cubit) =>
        Future.wait([cubit.requestCode(email), cubit.requestCode(email)]),
    verify: (_) => verify(
      () => repository.requestEmailCode(email, linkCurrent: true),
    ).called(1),
  );

  blocTest<EmailLinkCubit, EmailLinkState>(
    'confirm without a sent code does nothing',
    build: build,
    act: (cubit) => cubit.confirmCode('123456'),
    expect: () => const <EmailLinkState>[],
  );

  test('toString never contains the email', () {
    expect(sentState.toString(), isNot(contains('ahmed')));
  });
}
