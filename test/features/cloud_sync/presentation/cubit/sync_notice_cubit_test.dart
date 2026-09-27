import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/acknowledge_sync_notice.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_status.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_notice_cubit.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_notice_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '_fakes.dart';

/// 021 T079: SyncNoticeCubit.
void main() {
  late MockCloudSyncRepository repository;

  setUp(() {
    repository = MockCloudSyncRepository();
    when(
      () => repository.markNoticeShown(),
    ).thenAnswer((_) async => const Right(unit));
  });

  SyncNoticeCubit build() => SyncNoticeCubit(
    WatchSyncStatus(repository),
    AcknowledgeSyncNotice(repository),
  );

  void statusIs({required bool available, required bool noticeShown}) =>
      when(() => repository.watchStatus()).thenAnswer(
        (_) => Stream.value(
          syncStatus(available: available, noticeShown: noticeShown),
        ),
      );

  blocTest<SyncNoticeCubit, SyncNoticeState>(
    'shows when available and never shown, then hides once acknowledged',
    build: () {
      statusIs(available: true, noticeShown: false);
      return build();
    },
    act: (cubit) async {
      await cubit.check();
      await cubit.acknowledge();
      await cubit.acknowledge();
    },
    expect: () => const [
      SyncNoticeState(visibility: SyncNoticeVisibility.show),
      SyncNoticeState(
        visibility: SyncNoticeVisibility.hidden,
        isAcknowledging: true,
      ),
      SyncNoticeState(visibility: SyncNoticeVisibility.hidden),
    ],
    verify: (_) => verify(() => repository.markNoticeShown()).called(1),
  );

  blocTest<SyncNoticeCubit, SyncNoticeState>(
    'hidden when already shown',
    build: () {
      statusIs(available: true, noticeShown: true);
      return build();
    },
    act: (cubit) => cubit.check(),
    expect: () => const [
      SyncNoticeState(visibility: SyncNoticeVisibility.hidden),
    ],
  );

  blocTest<SyncNoticeCubit, SyncNoticeState>(
    'hidden when cloud sync is not configured',
    build: () {
      statusIs(available: false, noticeShown: false);
      return build();
    },
    act: (cubit) => cubit.check(),
    expect: () => const [
      SyncNoticeState(visibility: SyncNoticeVisibility.hidden),
    ],
    verify: (_) => verifyNever(() => repository.markNoticeShown()),
  );

  blocTest<SyncNoticeCubit, SyncNoticeState>(
    'hidden when the status cannot be read',
    build: () {
      when(
        () => repository.watchStatus(),
      ).thenAnswer((_) => Stream.error(StateError('x')));
      return build();
    },
    act: (cubit) => cubit.check(),
    expect: () => const [
      SyncNoticeState(visibility: SyncNoticeVisibility.hidden),
    ],
  );
}
