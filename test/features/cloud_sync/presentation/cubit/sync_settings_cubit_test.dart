import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_failed_item.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_runtime_status.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/retry_failed_sync.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/set_sync_enabled.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/sync_now.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_failed_sync_items.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_status.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_settings_cubit.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '_fakes.dart';

/// 021 T079: SyncSettingsCubit.
void main() {
  late MockCloudSyncRepository repository;
  late StreamController<SyncStatus> statuses;
  late StreamController<List<SyncFailedItem>> failed;

  const failedItem = SyncFailedItem(
    kind: SyncItemKind.person,
    entityId: 'p1',
    reason: SyncFailedReason.invalid,
  );
  final idle = syncStatus();
  final syncing = syncStatus(runtime: SyncRuntimeStatus.syncing);

  setUp(() {
    repository = MockCloudSyncRepository();
    statuses = StreamController<SyncStatus>.broadcast();
    failed = StreamController<List<SyncFailedItem>>.broadcast();
    when(() => repository.watchStatus()).thenAnswer((_) => statuses.stream);
    when(() => repository.watchFailedItems()).thenAnswer((_) => failed.stream);
    when(() => repository.syncNow()).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.setEnabled(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.retryFailed(),
    ).thenAnswer((_) async => const Right(unit));
  });

  tearDown(() async {
    await statuses.close();
    await failed.close();
  });

  SyncSettingsCubit build() => SyncSettingsCubit(
    WatchSyncStatus(repository),
    WatchFailedSyncItems(repository),
    SyncNow(repository),
    SetSyncEnabled(repository),
    RetryFailedSync(repository),
  );

  blocTest<SyncSettingsCubit, SyncSettingsState>(
    'subscribe emits the status and the failed items',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      statuses.add(idle);
      await Future<void>.delayed(Duration.zero);
      failed.add(const [failedItem]);
    },
    expect: () => [
      SyncSettingsState(loadStatus: SyncSettingsLoadStatus.ready, status: idle),
      SyncSettingsState(
        loadStatus: SyncSettingsLoadStatus.ready,
        status: idle,
        failedItems: const [failedItem],
      ),
    ],
  );

  blocTest<SyncSettingsCubit, SyncSettingsState>(
    'a status read error is a load failure',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      statuses.addError(StateError('x'));
    },
    expect: () => [
      isA<SyncSettingsState>()
          .having((s) => s.loadStatus, 'load', SyncSettingsLoadStatus.failure)
          .having((s) => s.actionFailure, 'failure', isA<UnknownFailure>()),
    ],
  );

  blocTest<SyncSettingsCubit, SyncSettingsState>(
    'syncNow requests once, with a busy flag in between',
    build: build,
    seed: () => SyncSettingsState(
      loadStatus: SyncSettingsLoadStatus.ready,
      status: idle,
    ),
    act: (cubit) => cubit.syncNow(),
    expect: () => [
      SyncSettingsState(
        loadStatus: SyncSettingsLoadStatus.ready,
        status: idle,
        isRequestingSync: true,
      ),
      SyncSettingsState(loadStatus: SyncSettingsLoadStatus.ready, status: idle),
    ],
    verify: (_) => verify(() => repository.syncNow()).called(1),
  );

  blocTest<SyncSettingsCubit, SyncSettingsState>(
    'syncNow is disabled while syncing',
    build: build,
    seed: () => SyncSettingsState(
      loadStatus: SyncSettingsLoadStatus.ready,
      status: syncing,
    ),
    act: (cubit) => cubit.syncNow(),
    expect: () => const <SyncSettingsState>[],
    verify: (cubit) {
      expect(cubit.state.canSyncNow, isFalse);
      verifyNever(() => repository.syncNow());
    },
  );

  blocTest<SyncSettingsCubit, SyncSettingsState>(
    'a double tap on "Sync now" sends one request',
    build: build,
    seed: () => SyncSettingsState(
      loadStatus: SyncSettingsLoadStatus.ready,
      status: idle,
    ),
    act: (cubit) => Future.wait([cubit.syncNow(), cubit.syncNow()]),
    verify: (_) => verify(() => repository.syncNow()).called(1),
  );

  test('canSyncNow is false while off or unavailable', () {
    expect(
      SyncSettingsState(status: syncStatus(enabled: false)).canSyncNow,
      isFalse,
    );
    expect(
      SyncSettingsState(status: syncStatus(available: false)).canSyncNow,
      isFalse,
    );
    expect(const SyncSettingsState().canSyncNow, isFalse);
    expect(SyncSettingsState(status: idle).canSyncNow, isTrue);
  });

  blocTest<SyncSettingsCubit, SyncSettingsState>(
    'setEnabled toggles with a guard and reports a failure',
    build: () {
      when(
        () => repository.setEnabled(false),
      ).thenAnswer((_) async => const Left(CacheFailure('db')));
      return build();
    },
    seed: () => SyncSettingsState(
      loadStatus: SyncSettingsLoadStatus.ready,
      status: idle,
    ),
    act: (cubit) =>
        Future.wait([cubit.setEnabled(false), cubit.setEnabled(false)]),
    expect: () => [
      SyncSettingsState(
        loadStatus: SyncSettingsLoadStatus.ready,
        status: idle,
        isTogglingEnabled: true,
      ),
      SyncSettingsState(
        loadStatus: SyncSettingsLoadStatus.ready,
        status: idle,
        actionFailure: const CacheFailure('db'),
      ),
    ],
    verify: (_) => verify(() => repository.setEnabled(false)).called(1),
  );

  blocTest<SyncSettingsCubit, SyncSettingsState>(
    'setEnabled to the current value does nothing',
    build: build,
    seed: () => SyncSettingsState(status: idle),
    act: (cubit) => cubit.setEnabled(true),
    expect: () => const <SyncSettingsState>[],
  );

  blocTest<SyncSettingsCubit, SyncSettingsState>(
    'retryFailed retries once and clears the busy flag',
    build: build,
    seed: () => SyncSettingsState(status: idle),
    act: (cubit) => Future.wait([cubit.retryFailed(), cubit.retryFailed()]),
    expect: () => [
      SyncSettingsState(status: idle, isRetrying: true),
      SyncSettingsState(status: idle),
    ],
    verify: (_) => verify(() => repository.retryFailed()).called(1),
  );
}
