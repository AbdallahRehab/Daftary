import 'package:daftary/core/confidence/field_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_pending_import_count.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_pending_imports.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';

ParseConfidence _overall(OverallConfidence level) => ParseConfidence(
  fields: {SmsField.amount: FieldConfidence.read(FieldConfidenceLevel.low)},
  overall: level,
);

void main() {
  late FakeSmsImportRepository repository;

  setUp(() {
    repository = FakeSmsImportRepository();
    repository.seed([
      buildPendingImport(
        id: 'high-old',
        fingerprint: 'f1',
        createdAt: DateTime(2026, 3, 1),
      ),
      buildPendingImport(
        id: 'low-new',
        fingerprint: 'f2',
        confidence: _overall(OverallConfidence.low),
        createdAt: DateTime(2026, 3, 3),
      ),
      buildPendingImport(
        id: 'low-old',
        fingerprint: 'f3',
        confidence: _overall(OverallConfidence.low),
        createdAt: DateTime(2026, 3, 2),
      ),
      buildPendingImport(
        id: 'medium',
        fingerprint: 'f4',
        confidence: _overall(OverallConfidence.medium),
        createdAt: DateTime(2026, 2, 1),
      ),
      buildPendingImport(
        id: 'ignored',
        fingerprint: 'f5',
        status: SmsImportStatus.ignored,
        decidedAt: DateTime(2026, 3, 3),
      ),
    ]);
  });
  tearDown(() => repository.close());

  const order = ['low-old', 'low-new', 'medium', 'high-old'];

  test('GetPendingImports: low confidence first, then oldest', () async {
    final items = (await GetPendingImports(
      repository,
    )()).getOrElse((f) => fail('$f'));
    expect(items.map((i) => i.id), order);
  });

  test('WatchPendingImports emits the same order', () async {
    final first = await WatchPendingImports(repository)().first;
    expect(first.getOrElse((f) => fail('$f')).map((i) => i.id), order);
  });

  test('WatchPendingImportCount counts pending items only', () async {
    final count = await WatchPendingImportCount(repository)().first;
    expect(count.getOrElse((f) => fail('$f')), 4);
  });
}
