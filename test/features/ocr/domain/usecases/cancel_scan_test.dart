import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:daftary/features/ocr/domain/usecases/cancel_scan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOcrRepository extends Mock implements OcrRepository {}

void main() {
  late MockOcrRepository repository;
  late CancelScan cancelScan;

  void stubCancel(Either<Failure, Unit> response) {
    when(() => repository.cancelScan(any())).thenAnswer((_) async => response);
  }

  setUp(() {
    repository = MockOcrRepository();
    cancelScan = CancelScan(repository);
  });

  group('CancelScan', () {
    test('delegates to the repository with the scan id and reports success '
        'as Right(unit) (FR-015)', () async {
      stubCancel(const Right(unit));

      final result = await cancelScan('scan-1');

      expect(result.getRight().toNullable(), unit);
      verify(() => repository.cancelScan('scan-1')).called(1);
    });

    test(
      'propagates a repository failure unchanged rather than throwing',
      () async {
        const failure = CacheFailure('Could not update the scan');
        stubCancel(const Left(failure));

        final result = await cancelScan('scan-1');

        expect(result.isLeft(), isTrue);
        expect(result.getLeft().toNullable(), same(failure));
      },
    );

    test('nothing transaction-creating is reachable from cancelling: '
        'abandoning a scan creates no money, ever (FR-015, constitution '
        'Principle X)', () async {
      stubCancel(const Right(unit));

      await cancelScan('scan-1');

      // CancelScan's only collaborator is the OcrRepository, and the single
      // method there that can produce a MoneyTransaction is never reached.
      verify(() => repository.cancelScan('scan-1')).called(1);
      verifyNever(
        () => repository.confirmScanBatch(
          idempotencyKey: any(named: 'idempotencyKey'),
          scanId: any(named: 'scanId'),
        ),
      );
      verifyNoMoreInteractions(repository);
    });
  });
}
