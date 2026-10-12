import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_pending_import.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';

void main() {
  test('returns the item by id', () async {
    final repository = FakeSmsImportRepository()..seed([buildPendingImport()]);
    final result = await GetPendingImport(repository)('pending-1');
    expect(result.getOrElse((f) => fail('$f')).id, 'pending-1');
  });

  test('NotFoundFailure with a fixed token when absent', () async {
    final result = await GetPendingImport(FakeSmsImportRepository())('nope');
    final failure = result.getLeft().toNullable();
    expect(failure, isA<NotFoundFailure>());
    expect(failure!.message, 'sms_import_not_found');
  });
}
