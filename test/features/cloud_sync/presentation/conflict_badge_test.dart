import 'dart:async';

import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_conflict_item.dart';
import 'package:daftary/features/cloud_sync/domain/repositories/cloud_sync_repository.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/resolve_sync_conflict.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_conflicts.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_conflicts_cubit.dart';
import 'package:daftary/features/cloud_sync/presentation/widgets/conflict_badge.dart';
import 'package:daftary/features/cloud_sync/presentation/widgets/conflict_resolution_sheet.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/presentation/widgets/finance_entry_list_tile.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements CloudSyncRepository {}

/// 021 T074: the conflict badge and the resolution sheet, in en and ar.
void main() {
  late _MockRepository repository;
  late StreamController<List<SyncConflictItem>> conflicts;
  late SyncConflictsCubit cubit;

  final item = SyncConflictItem(
    entityType: ConflictEntityType.moneyTransaction,
    entityId: 't1',
    localSummary: ConflictVersion(
      amount: const Money.egp(123400),
      date: DateTime(2026, 3, 4),
      direction: ConflictDirection.given,
      note: 'my note',
    ),
    serverSummary: ConflictVersion(
      amount: const Money.egp(999900),
      date: DateTime(2026, 3, 5),
      direction: ConflictDirection.received,
      isDeleted: true,
    ),
    detectedAt: DateTime(2026, 3, 6),
  );

  final transaction = MoneyTransaction(
    id: 't1',
    idempotencyKey: 'k1',
    personId: 'p1',
    amount: const Money.egp(123400),
    direction: TransactionDirection.given,
    kind: TransactionKind.initialExchange,
    date: DateTime(2026, 3, 4),
    createdAt: DateTime(2026, 3, 4),
  );

  setUp(() {
    repository = _MockRepository();
    conflicts = StreamController<List<SyncConflictItem>>.broadcast();
    when(() => repository.watchConflicts()).thenAnswer((_) => conflicts.stream);
    cubit = SyncConflictsCubit(
      WatchSyncConflicts(repository),
      ResolveSyncConflict(repository),
    )..subscribe();
  });

  tearDown(() async {
    await cubit.close();
    await conflicts.close();
  });

  Widget wrap(Widget child, {String locale = 'en'}) => MaterialApp(
    theme: buildLightTheme(),
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider.value(
      value: cubit,
      child: Scaffold(body: child),
    ),
  );

  group('badge', () {
    testWidgets('a tile without a conflict renders no badge', (tester) async {
      await tester.pumpWidget(
        wrap(TransactionListTile(transaction: transaction)),
      );
      expect(find.byType(ConflictBadge), findsNothing);
    });

    for (final (locale, label) in [('en', 'Conflict'), ('ar', 'تعارض')]) {
      testWidgets('the transaction and entry rows show the badge ($locale)', (
        tester,
      ) async {
        var taps = 0;
        final entry = FinanceEntry(
          id: 'e1',
          idempotencyKey: 'k',
          categoryId: 'c1',
          type: FinanceEntryType.expense,
          amount: const Money.egp(500),
          date: DateTime(2026, 3, 4),
          createdAt: DateTime(2026, 3, 4),
        );
        await tester.pumpWidget(
          wrap(
            Column(
              children: [
                TransactionListTile(
                  transaction: transaction,
                  conflictBadge: ConflictBadge(onTap: () => taps++),
                ),
                FinanceEntryListTile(
                  entry: entry,
                  categoryName: 'Rent',
                  categoryIconKey: 'rent',
                  conflictBadge: ConflictBadge(onTap: () => taps++),
                ),
              ],
            ),
            locale: locale,
          ),
        );
        expect(find.byType(ConflictBadge), findsNWidgets(2));
        expect(find.text(label), findsNWidgets(2));
        await tester.tap(find.byType(ConflictBadge).first);
        expect(taps, 1);
      });
    }
  });

  group('sheet', () {
    for (final (locale, mine, theirs, keepMine) in [
      ('en', 'This device', 'Other device', 'Keep mine'),
      ('ar', 'هذا الجهاز', 'جهاز آخر', 'الاحتفاظ بنسختي'),
    ]) {
      testWidgets('shows both versions side by side ($locale)', (tester) async {
        await tester.pumpWidget(
          wrap(ConflictResolutionSheet(item: item), locale: locale),
        );
        expect(find.text(mine), findsOneWidget);
        expect(find.text(theirs), findsOneWidget);
        expect(find.text(keepMine), findsOneWidget);
        expect(find.text('my note'), findsOneWidget);
        expect(find.textContaining('1,234.00'), findsOneWidget);
        expect(find.textContaining('9,999.00'), findsOneWidget);

        // Mine is at the reading start: left in LTR, right in RTL.
        final mineX = tester.getCenter(find.text(mine)).dx;
        final theirsX = tester.getCenter(find.text(theirs)).dx;
        expect(locale == 'ar' ? mineX > theirsX : mineX < theirsX, isTrue);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('"Keep theirs" resolves through the repository and closes', (
      tester,
    ) async {
      when(
        () => repository.resolveConflict(
          'money_transaction',
          't1',
          ConflictChoice.keepTheirs,
        ),
      ).thenAnswer((_) async => const Right(unit));
      conflicts.add([item]);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showConflictResolutionSheet(context, item),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ConflictResolutionSheet.keepTheirsKey));
      await tester.pumpAndSettle();

      verify(
        () => repository.resolveConflict(
          'money_transaction',
          't1',
          ConflictChoice.keepTheirs,
        ),
      ).called(1);
      expect(find.byType(ConflictResolutionSheet), findsNothing);
    });

    testWidgets('a failed resolution keeps the sheet open and says so', (
      tester,
    ) async {
      when(
        () => repository.resolveConflict(any(), any(), ConflictChoice.keepMine),
      ).thenAnswer((_) async => const Left(CacheFailure('x')));
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showConflictResolutionSheet(context, item),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ConflictResolutionSheet.keepMineKey));
      await tester.pumpAndSettle();

      expect(find.byType(ConflictResolutionSheet), findsOneWidget);
      expect(
        find.text("Couldn't resolve the conflict. Try again."),
        findsOneWidget,
      );
    });
  });
}
