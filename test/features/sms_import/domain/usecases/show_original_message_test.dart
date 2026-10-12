import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/usecases/show_original_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';

void main() {
  late FakeSmsImportRepository repository;

  setUp(() => repository = FakeSmsImportRepository());
  tearDown(() => repository.close());

  Future<void> stage(String text, {String id = 'pending-1'}) async {
    await repository.insertPending(
      NewPendingImport(
        item: buildPendingImport(id: id, fingerprint: 'fp-$id'),
        rawMasked: text,
      ),
    );
  }

  test('an English message is LTR', () async {
    await stage('Purchase EGP 1.00 at Example');
    final original = (await ShowOriginalMessage(repository)(
      'pending-1',
    )).getOrElse((f) => fail('$f'));
    expect(original.direction, TextDirectionHint.ltr);
    expect(original.text, startsWith('Purchase'));
  });

  test('an Arabic message is RTL even with a leading number', () async {
    await stage('١٢٣ تم خصم مبلغ EGP 1.00');
    final original = (await ShowOriginalMessage(repository)(
      'pending-1',
    )).getOrElse((f) => fail('$f'));
    expect(original.direction, TextDirectionHint.rtl);
  });

  test('first strong character decides a mixed message', () {
    expect(
      ShowOriginalMessage.directionOf('EGP 5 تم الخصم من بطاقتك'),
      TextDirectionHint.ltr,
    );
    expect(
      ShowOriginalMessage.directionOf('تم الخصم EGP 5 card purchase at shop'),
      TextDirectionHint.rtl,
    );
  });

  test('unavailable after a decision', () async {
    await stage('Purchase EGP 1.00');
    await repository.ignore({'pending-1'});
    final result = await ShowOriginalMessage(repository)('pending-1');
    expect(result.getLeft().toNullable(), isA<OriginalUnavailableFailure>());
  });

  test('unavailable when there is no original', () async {
    repository.seed([buildPendingImport(hasRawText: false)]);
    final result = await ShowOriginalMessage(repository)('pending-1');
    expect(result.getLeft().toNullable(), isA<OriginalUnavailableFailure>());
  });

  test('a store failure is not reported as a missing original', () async {
    final failing = _FailingOpen();
    final result = await ShowOriginalMessage(failing)('pending-1');
    expect(result.getLeft().toNullable(), isA<CacheFailure>());
  });
}

class _FailingOpen extends FakeSmsImportRepository {
  @override
  Future<Either<Failure, String>> openOriginal(String id) async =>
      const Left(CacheFailure('sms_import_store_failed'));
}
