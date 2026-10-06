import 'dart:async';

import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_conflict_item.dart';
import 'package:daftary/features/cloud_sync/domain/repositories/cloud_sync_repository.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/resolve_sync_conflict.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_conflicts.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_conflicts_cubit.dart';
import 'package:daftary/features/cloud_sync/presentation/widgets/conflict_resolution_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements CloudSyncRepository {}

/// 022 T052 (A3): the resolution sheet for a savings contribution edited on
/// two devices, in Arabic and English, light and dark.
void main() {
  late _MockRepository repository;
  late SyncConflictsCubit cubit;

  final item = SyncConflictItem(
    entityType: ConflictEntityType.savingsContribution,
    entityId: 'c1',
    localSummary: ConflictVersion(
      amount: const Money.egp(100000),
      date: DateTime(2026, 10, 1),
      direction: ConflictDirection.contribution,
      note: 'salary',
    ),
    serverSummary: ConflictVersion(
      amount: const Money.egp(120000),
      date: DateTime(2026, 10, 2),
      direction: ConflictDirection.withdrawal,
    ),
    detectedAt: DateTime(2026, 10, 3),
  );

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.watchConflicts(),
    ).thenAnswer((_) => const Stream<List<SyncConflictItem>>.empty());
    cubit = SyncConflictsCubit(
      WatchSyncConflicts(repository),
      ResolveSyncConflict(repository),
    );
  });

  tearDown(() => cubit.close());

  Widget wrap(String locale, {required bool dark}) => MaterialApp(
    theme: dark ? buildDarkTheme() : buildLightTheme(),
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider.value(
      value: cubit,
      child: Scaffold(body: ConflictResolutionSheet(item: item)),
    ),
  );

  for (final (locale, contribution, withdrawal, keepMine, keepTheirs) in [
    ('en', 'Contribution', 'Withdrawal', 'Keep mine', 'Keep theirs'),
    (
      'ar',
      'إيداع في الهدف',
      'سحب من الهدف',
      'الاحتفاظ بنسختي',
      'الاحتفاظ بالنسخة الأخرى',
    ),
  ]) {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';
      testWidgets('shows both versions with their direction ($locale, $mode)', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        tester.view
          ..physicalSize = const Size(800, 1400)
          ..devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(wrap(locale, dark: dark));

        expect(find.text(contribution), findsOneWidget);
        expect(find.text(withdrawal), findsOneWidget);
        expect(find.textContaining('1,000.00'), findsOneWidget);
        expect(find.textContaining('1,200.00'), findsOneWidget);
        expect(find.text('salary'), findsOneWidget);
        expect(find.text(keepMine), findsOneWidget);
        expect(find.text(keepTheirs), findsOneWidget);

        // Each version is announced as one unit, direction included, and
        // both choices are reachable by label.
        expect(
          find.bySemanticsLabel(RegExp('1,000.00.*$contribution')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp('1,200.00.*$withdrawal')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel(keepMine), findsOneWidget);
        expect(find.bySemanticsLabel(keepTheirs), findsOneWidget);
        expect(tester.takeException(), isNull);

        semantics.dispose();
      });
    }
  }

  testWidgets('equal typed amounts but different goal amounts show the goal '
      'amount on each card', (tester) async {
    final same = SyncConflictItem(
      entityType: ConflictEntityType.savingsContribution,
      entityId: 'c1',
      localSummary: ConflictVersion(
        amount: const Money.egp(50000),
        goalAmount: const Money.egp(50000),
        date: DateTime(2026, 10, 1),
        direction: ConflictDirection.contribution,
      ),
      serverSummary: ConflictVersion(
        amount: const Money.egp(50000),
        goalAmount: const Money.egp(70000),
        date: DateTime(2026, 10, 1),
        direction: ConflictDirection.contribution,
      ),
      detectedAt: DateTime(2026, 10, 3),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(body: ConflictResolutionSheet(item: same)),
        ),
      ),
    );
    expect(find.textContaining('500.00'), findsNWidgets(3));
    expect(find.textContaining('700.00'), findsOneWidget);
  });

  testWidgets('a clear difference in the typed amount hides the goal amount', (
    tester,
  ) async {
    await tester.pumpWidget(wrap('en', dark: false));
    expect(item.showsGoalAmount, isFalse);
  });
}
