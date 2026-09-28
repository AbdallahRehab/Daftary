import 'package:daftary/core/database/watch_tables.dart';
import 'package:daftary/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/watch_stubs.dart';

class MockOcrRepository extends Mock implements OcrRepository {}

/// 021: answers `watchScanHistory`/`watchScanDetail` by re-running the
/// test's `getScanHistory`/`getScanDetail` stubs once on listen and again
/// on every [FakeTableChanges.notify] — the way the real table-change
/// streams behave.
void stubOcrWatches(OcrRepository repository, FakeTableChanges changes) {
  when(
    repository.watchScanHistory,
  ).thenAnswer((_) => changes.signal().reRead(repository.getScanHistory));
  when(() => repository.watchScanDetail(any())).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getScanDetail(
        invocation.positionalArguments.first as String,
      ),
    ),
  );
}
