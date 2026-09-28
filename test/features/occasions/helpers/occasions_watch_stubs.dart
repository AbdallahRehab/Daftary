import 'package:daftary/core/database/watch_tables.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_filter.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/watch_stubs.dart';

class MockOccasionsRepository extends Mock implements OccasionsRepository {}

/// 021: answers `watchOccasionsList`/`watchOccasionDetail` by re-running
/// the test's `getOccasionsList`/`getOccasionDetail` stubs once on listen
/// and again on every [FakeTableChanges.notify] — the way the real
/// table-change streams behave.
void stubOccasionsWatches(
  OccasionsRepository repository,
  FakeTableChanges changes,
) {
  when(
    () => repository.watchOccasionsList(
      filter: any(named: 'filter'),
      includeArchived: any(named: 'includeArchived'),
    ),
  ).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getOccasionsList(
        filter: invocation.namedArguments[#filter] as OccasionFilter?,
        includeArchived:
            invocation.namedArguments[#includeArchived] as bool? ?? false,
      ),
    ),
  );
  when(() => repository.watchOccasionDetail(any())).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getOccasionDetail(
        invocation.positionalArguments.first as String,
      ),
    ),
  );
}
