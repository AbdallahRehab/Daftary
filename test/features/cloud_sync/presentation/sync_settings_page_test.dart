import 'dart:async';

import 'package:daftary/core/design_system/app_button.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_conflict_item.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_failed_item.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_runtime_status.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/confirm_email_code.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/request_email_code.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/resolve_sync_conflict.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/retry_failed_sync.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/set_sync_enabled.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/sync_now.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_failed_sync_items.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_conflicts.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_status.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/email_link_cubit.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_conflicts_cubit.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_settings_cubit.dart';
import 'package:daftary/features/cloud_sync/presentation/pages/sync_settings_page.dart';
import 'package:daftary/features/cloud_sync/presentation/widgets/conflict_resolution_sheet.dart';
import 'package:daftary/features/cloud_sync/presentation/widgets/email_link_sheet.dart';
import 'package:daftary/features/cloud_sync/presentation/widgets/sync_status_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'cubit/_fakes.dart';

/// 021 T080: the Settings sync page renders every status in en and ar.
void main() {
  late MockCloudSyncRepository repository;
  late StreamController<SyncStatus> statuses;
  late StreamController<List<SyncFailedItem>> failed;
  late StreamController<List<SyncConflictItem>> conflicts;

  final conflict = SyncConflictItem(
    entityType: ConflictEntityType.moneyTransaction,
    entityId: 't1',
    localSummary: ConflictVersion(
      amount: const Money.egp(1000),
      date: DateTime(2026, 3, 4),
      direction: ConflictDirection.given,
    ),
    serverSummary: ConflictVersion(
      amount: const Money.egp(2000),
      date: DateTime(2026, 3, 4),
      direction: ConflictDirection.given,
    ),
    detectedAt: DateTime(2026, 3, 6),
  );
  const failedItem = SyncFailedItem(
    kind: SyncItemKind.person,
    entityId: 'p1',
    reason: SyncFailedReason.personHasTransactions,
  );

  setUp(() {
    repository = MockCloudSyncRepository();
    statuses = StreamController<SyncStatus>.broadcast();
    failed = StreamController<List<SyncFailedItem>>.broadcast();
    conflicts = StreamController<List<SyncConflictItem>>.broadcast();
    when(() => repository.watchStatus()).thenAnswer((_) => statuses.stream);
    when(() => repository.watchFailedItems()).thenAnswer((_) => failed.stream);
    when(() => repository.watchConflicts()).thenAnswer((_) => conflicts.stream);
    when(() => repository.syncNow()).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.retryFailed(),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.setEnabled(any()),
    ).thenAnswer((_) async => const Right(unit));
    getIt
      ..registerFactory(
        () => SyncSettingsCubit(
          WatchSyncStatus(repository),
          WatchFailedSyncItems(repository),
          SyncNow(repository),
          SetSyncEnabled(repository),
          RetryFailedSync(repository),
        ),
      )
      ..registerFactory(
        () => SyncConflictsCubit(
          WatchSyncConflicts(repository),
          ResolveSyncConflict(repository),
        ),
      )
      ..registerFactory(
        () => EmailLinkCubit(
          RequestEmailCode(repository),
          ConfirmEmailCode(repository),
        ),
      );
  });

  tearDown(() async {
    await getIt.reset();
    await statuses.close();
    await failed.close();
    await conflicts.close();
  });

  Future<AppLocalizations> pumpPage(
    WidgetTester tester,
    SyncStatus status, {
    String locale = 'en',
    List<SyncFailedItem> failedItems = const [],
    List<SyncConflictItem> conflictItems = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SyncSettingsPage(),
      ),
    );
    await tester.pump();
    statuses.add(status);
    failed.add(failedItems);
    conflicts.add(conflictItems);
    // Not pumpAndSettle: the "Sync now" spinner animates while syncing.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return lookupAppLocalizations(Locale(locale));
  }

  String statusText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(SyncStatusLine.textKey)).data!;

  AppButton syncNowButton(WidgetTester tester) =>
      tester.widget<AppButton>(find.byKey(SyncSettingsPage.syncNowKey));

  final cases = <String, (SyncStatus, String Function(AppLocalizations))>{
    'up to date': (
      syncStatus(lastSuccessAt: DateTime(2026, 9, 27, 9, 30)),
      (l) => l.syncStatusUpToDate,
    ),
    'pending': (syncStatus(pending: 3), (l) => l.syncStatusPending(3)),
    'syncing': (
      syncStatus(runtime: SyncRuntimeStatus.syncing, pending: 1),
      (l) => l.syncStatusSyncing,
    ),
    'offline': (
      syncStatus(runtime: SyncRuntimeStatus.offline, pending: 2),
      (l) => l.syncStatusOffline,
    ),
    'failed': (syncStatus(failed: 1), (l) => l.syncStatusFailed),
    'conflict': (syncStatus(conflicts: 1), (l) => l.syncStatusConflict),
    'retrying': (
      syncStatus(runtime: SyncRuntimeStatus.backingOff, pending: 1),
      (l) => l.syncStatusRetrying,
    ),
    'auth required': (
      syncStatus(runtime: SyncRuntimeStatus.authRequired),
      (l) => l.syncStatusAuthRequired,
    ),
    'disabled': (
      syncStatus(runtime: SyncRuntimeStatus.disabled, enabled: false),
      (l) => l.syncStatusOff,
    ),
    'unavailable': (
      syncStatus(runtime: SyncRuntimeStatus.disabled, available: false),
      (l) => l.syncStatusUnavailable,
    ),
    'unreadable row': (
      syncStatus(
        runtime: SyncRuntimeStatus.backingOff,
        problem: SyncProblem.unreadableCloudData,
      ),
      (l) => l.syncStatusUnreadable,
    ),
  };

  for (final locale in ['en', 'ar']) {
    group(locale, () {
      for (final MapEntry(key: name, value: (status, text)) in cases.entries) {
        testWidgets('renders "$name"', (tester) async {
          final l10n = await pumpPage(
            tester,
            status,
            locale: locale,
            failedItems: status.failed > 0 ? const [failedItem] : const [],
            conflictItems: status.conflicts > 0 ? [conflict] : const [],
          );
          expect(tester.takeException(), isNull);
          expect(statusText(tester), text(l10n));
          expect(
            Directionality.of(tester.element(find.byType(SyncStatusLine))),
            locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          if (status.available) {
            expect(find.byKey(SyncSettingsPage.enabledSwitchKey), findsOne);
            expect(find.text(l10n.syncCountPending), findsOne);
            expect(find.text(l10n.syncCountFailed), findsOne);
            expect(find.text(l10n.syncCountConflicts), findsOne);
          } else {
            expect(find.byKey(SyncSettingsPage.syncNowKey), findsNothing);
            expect(find.byKey(SyncSettingsPage.enabledSwitchKey), findsNothing);
          }
          if (status.problem == SyncProblem.unreadableCloudData) {
            expect(find.text(l10n.syncProblemUnreadableMessage), findsOne);
          } else {
            expect(find.byKey(SyncSettingsPage.problemKey), findsNothing);
          }
        });
      }

      testWidgets('lists failed items with Retry, and conflicts that open '
          'the resolution sheet', (tester) async {
        // A tall screen, so every section is laid out at once.
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final l10n = await pumpPage(
          tester,
          syncStatus(failed: 1, conflicts: 1),
          locale: locale,
          failedItems: const [failedItem],
          conflictItems: [conflict],
        );
        expect(find.text(l10n.syncFailedSectionTitle), findsOne);
        expect(find.text(l10n.syncKindPerson), findsOne);
        expect(find.text(l10n.syncFailedReasonPersonHasTransactions), findsOne);
        await tester.tap(find.byKey(SyncSettingsPage.retryKey));
        await tester.pump();
        verify(() => repository.retryFailed()).called(1);

        await tester.tap(find.byKey(const Key('sync_conflict_t1')));
        await tester.pumpAndSettle();
        expect(find.byType(ConflictResolutionSheet), findsOne);
        expect(find.byKey(ConflictResolutionSheet.keepMineKey), findsOne);
      });
    });
  }

  testWidgets('"Sync now" is disabled while syncing, enabled when idle, and '
      'a tap sends one request', (tester) async {
    await pumpPage(tester, syncStatus(runtime: SyncRuntimeStatus.syncing));
    expect(syncNowButton(tester).onPressed, isNull);
    expect(syncNowButton(tester).isLoading, isTrue);

    statuses.add(syncStatus());
    await tester.pumpAndSettle();
    expect(syncNowButton(tester).onPressed, isNotNull);
    when(() => repository.syncNow()).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 100),
        () => const Right(unit),
      ),
    );
    await tester.tap(find.byKey(SyncSettingsPage.syncNowKey));
    await tester.pump();
    await tester.tap(
      find.byKey(SyncSettingsPage.syncNowKey),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    verify(() => repository.syncNow()).called(1);
  });

  testWidgets('the switch turns sync off', (tester) async {
    await pumpPage(tester, syncStatus());
    await tester.tap(find.byKey(SyncSettingsPage.enabledSwitchKey));
    await tester.pumpAndSettle();
    verify(() => repository.setEnabled(false)).called(1);
  });

  testWidgets('anonymous: "Link email" and "Sign in"; the link sheet opens', (
    tester,
  ) async {
    final l10n = await pumpPage(tester, syncStatus());
    expect(find.byKey(SyncSettingsPage.linkEmailKey), findsOne);
    expect(find.byKey(SyncSettingsPage.signInKey), findsOne);
    await tester.tap(find.byKey(SyncSettingsPage.linkEmailKey));
    await tester.pumpAndSettle();
    expect(find.byType(EmailLinkSheet), findsOne);
    expect(find.text(l10n.syncEmailLinkTitle), findsOne);
  });

  testWidgets('linked: only the masked email is shown', (tester) async {
    await pumpPage(
      tester,
      syncStatus(isAnonymous: false, linkedEmailMasked: 'a***@g***.com'),
    );
    expect(find.byKey(SyncSettingsPage.linkEmailKey), findsNothing);
    expect(find.byKey(SyncSettingsPage.linkedEmailKey), findsOne);
    expect(find.textContaining('a***@g***.com'), findsOne);
  });

  testWidgets('no account actions while sync is off', (tester) async {
    await pumpPage(
      tester,
      syncStatus(runtime: SyncRuntimeStatus.disabled, enabled: false),
    );
    expect(find.byKey(SyncSettingsPage.linkEmailKey), findsNothing);
    expect(syncNowButton(tester).onPressed, isNull);
  });
}
