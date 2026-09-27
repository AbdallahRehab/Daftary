import 'dart:async';

import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_failed_item.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_runtime_status.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/retry_failed_sync.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/set_sync_enabled.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/sync_now.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_failed_sync_items.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_status.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_settings_cubit.dart';
import 'package:daftary/features/cloud_sync/presentation/widgets/sync_status_subtitle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'cubit/_fakes.dart';

/// 021 T080: the live status under the Settings "Cloud backup & sync" entry.
void main() {
  tearDown(getIt.reset);

  Widget wrap(Widget child, String locale) => MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  for (final locale in ['en', 'ar']) {
    testWidgets('unconfigured build: "not available", no DI ($locale)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const SyncStatusSubtitle(configured: false), locale),
      );
      final l10n = lookupAppLocalizations(Locale(locale));
      expect(find.text(l10n.syncStatusUnavailable), findsOne);
    });

    testWidgets('configured: follows the live status ($locale)', (
      tester,
    ) async {
      final repository = MockCloudSyncRepository();
      final statuses = StreamController<SyncStatus>.broadcast();
      addTearDown(statuses.close);
      when(() => repository.watchStatus()).thenAnswer((_) => statuses.stream);
      when(
        () => repository.watchFailedItems(),
      ).thenAnswer((_) => Stream.value(const <SyncFailedItem>[]));
      getIt.registerFactory(
        () => SyncSettingsCubit(
          WatchSyncStatus(repository),
          WatchFailedSyncItems(repository),
          SyncNow(repository),
          SetSyncEnabled(repository),
          RetryFailedSync(repository),
        ),
      );
      final l10n = lookupAppLocalizations(Locale(locale));
      await tester.pumpWidget(
        wrap(const SyncStatusSubtitle(configured: true), locale),
      );
      statuses.add(syncStatus(runtime: SyncRuntimeStatus.offline));
      await tester.pump();
      expect(find.text(l10n.syncStatusOffline), findsOne);
      statuses.add(syncStatus(pending: 2));
      await tester.pump();
      await tester.pump();
      expect(find.text(l10n.syncStatusPending(2)), findsOne);
    });
  }
}
