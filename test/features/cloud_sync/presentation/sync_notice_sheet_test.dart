import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/acknowledge_sync_notice.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_status.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_notice_cubit.dart';
import 'package:daftary/features/cloud_sync/presentation/pages/sync_settings_page.dart';
import 'package:daftary/features/cloud_sync/presentation/widgets/sync_notice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'cubit/_fakes.dart';

/// 021 T081: the one-time sync notice.
void main() {
  late MockCloudSyncRepository repository;
  late bool noticeShown;

  setUp(() {
    noticeShown = false;
    repository = MockCloudSyncRepository();
    when(
      () => repository.watchStatus(),
    ).thenAnswer((_) => Stream.value(syncStatus(noticeShown: noticeShown)));
    when(() => repository.markNoticeShown()).thenAnswer((_) async {
      noticeShown = true;
      return const Right(unit);
    });
  });

  Widget app({bool configured = true, String locale = 'en'}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => SyncNoticeHost(
            configured: configured,
            createCubit: () => SyncNoticeCubit(
              WatchSyncStatus(repository),
              AcknowledgeSyncNotice(repository),
            ),
            child: const Scaffold(body: Text('home')),
          ),
        ),
        GoRoute(
          path: SyncSettingsRoutes.settings,
          builder: (context, state) => const Scaffold(body: Text('sync page')),
        ),
      ],
    );
    return MaterialApp.router(
      theme: buildLightTheme(),
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  for (final locale in ['en', 'ar']) {
    testWidgets('shown once, then never again ($locale)', (tester) async {
      final l10n = lookupAppLocalizations(Locale(locale));
      await tester.pumpWidget(app(locale: locale));
      await tester.pumpAndSettle();
      expect(find.byType(SyncNoticeSheet), findsOne);
      expect(find.text(l10n.syncNoticeTitle), findsOne);

      await tester.tap(find.byKey(SyncNoticeSheet.dismissKey));
      await tester.pumpAndSettle();
      expect(find.byType(SyncNoticeSheet), findsNothing);
      verify(() => repository.markNoticeShown()).called(1);

      // The next launch.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(locale: locale));
      await tester.pumpAndSettle();
      expect(find.byType(SyncNoticeSheet), findsNothing);
      verifyNever(() => repository.markNoticeShown());
    });
  }

  testWidgets('closing the sheet by dragging it away also acknowledges it', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // the barrier
    await tester.pumpAndSettle();
    expect(find.byType(SyncNoticeSheet), findsNothing);
    verify(() => repository.markNoticeShown()).called(1);
  });

  testWidgets('"Sync settings" acknowledges and opens the sync page', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SyncNoticeSheet.openSettingsKey));
    await tester.pumpAndSettle();
    expect(find.text('sync page'), findsOne);
    verify(() => repository.markNoticeShown()).called(1);
  });

  testWidgets('never shown when cloud sync is not configured', (tester) async {
    await tester.pumpWidget(app(configured: false));
    await tester.pumpAndSettle();
    expect(find.byType(SyncNoticeSheet), findsNothing);
    verifyNever(() => repository.watchStatus());
  });

  testWidgets('never shown when the build has no cloud (status unavailable)', (
    tester,
  ) async {
    when(() => repository.watchStatus()).thenAnswer(
      (_) => Stream.value(syncStatus(noticeShown: false, available: false)),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byType(SyncNoticeSheet), findsNothing);
  });
}
