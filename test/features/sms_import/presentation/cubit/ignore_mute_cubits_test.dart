import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/undo_ignore.dart';
import 'package:daftary/features/sms_import/domain/usecases/unmute_sender.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_muted_senders.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_undo_list.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_home_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/ignored_imports_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/import_review_state.dart';
import 'package:daftary/features/sms_import/presentation/cubit/muted_senders_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/review_harness.dart';
import '../../helpers/scan_presentation.dart';

class _MockUnmute extends Mock implements UnmuteSender {}

class _MockUndo extends Mock implements UndoIgnore {}

/// T135 — the cubits of T129 and T132-T134: the Home count, the hub's
/// multi-select with batch Ignore, Ignore and mute on the review, the
/// Ignored list with Undo and the Muted senders list.
void main() {
  late FixedClock clock;
  late FakeSmsImportRepository repository;

  setUp(() {
    clock = FixedClock(DateTime(2026, 3, 10, 12));
    repository = FakeSmsImportRepository(clock: clock);
  });
  tearDown(() => repository.close());

  group('BankMessagesHomeCubit count (T129)', () {
    late HubScanDeps deps;
    late BankMessagesHomeCubit cubit;

    setUp(() {
      deps = HubScanDeps(capability: true);
      cubit = buildHomeCubit(deps, repository: repository)..open();
    });
    tearDown(() async {
      await cubit.close();
      await deps.settings.close();
    });

    test('0 pending: no count variant', () async {
      await pumpEventQueue();
      expect(cubit.state.pendingCount, 0);
      expect(cubit.state.showCount, isFalse);
    });

    test('follows the pending count live', () async {
      await pumpEventQueue();
      repository.seed([
        buildPendingImport(id: 'a', fingerprint: 'a'),
        buildPendingImport(id: 'b', fingerprint: 'b'),
      ]);
      await pumpEventQueue();
      expect(cubit.state.pendingCount, 2);
      expect(cubit.state.showCount, isTrue);

      await repository.ignore({'a', 'b'});
      await pumpEventQueue();
      expect(cubit.state.showCount, isFalse);
    });

    test('the onboarding flag and the count are independent', () async {
      await pumpEventQueue();
      repository.seed([buildPendingImport()]);
      await pumpEventQueue();
      expect(cubit.state.showOnboarding, isTrue);
      expect(cubit.state.showCount, isTrue);
    });
  });

  group('BankMessagesCubit selection and batch Ignore (T132)', () {
    late BankMessagesCubit cubit;

    setUp(() async {
      repository.seed([
        buildPendingImport(id: 'a', fingerprint: 'a'),
        buildPendingImport(id: 'b', fingerprint: 'b'),
        buildPendingImport(id: 'c', fingerprint: 'c'),
      ]);
      cubit = buildBankMessagesCubit(repository, clock);
      await cubit.open();
      await pumpEventQueue();
    });
    tearDown(() => cubit.close());

    test('long-press starts selection with that item', () {
      cubit.startSelection('a');
      expect(cubit.state.selectionMode, isTrue);
      expect(cubit.state.selectedIds, {'a'});
    });

    test('toggle adds and removes; cancel clears', () {
      cubit
        ..startSelection()
        ..toggleSelected('a')
        ..toggleSelected('b')
        ..toggleSelected('a');
      expect(cubit.state.selectedIds, {'b'});
      cubit.cancelSelection();
      expect(cubit.state.selectionMode, isFalse);
      expect(cubit.state.selectedIds, isEmpty);
    });

    test('toggle outside selection mode does nothing', () {
      cubit.toggleSelected('a');
      expect(cubit.state.selectedIds, isEmpty);
    });

    test('ignoreSelected ignores the selection in one call and reports '
        'the count', () async {
      cubit
        ..startSelection('a')
        ..toggleSelected('c');
      final pending = cubit.ignoreSelected();
      expect(cubit.state.ignoring, isTrue);
      await pending;
      await pumpEventQueue();

      expect(repository.rows['a']!.status, SmsImportStatus.ignored);
      expect(repository.rows['c']!.status, SmsImportStatus.ignored);
      expect(repository.rows['b']!.status, SmsImportStatus.pending);
      expect(repository.confirmCalls, isEmpty);
      expect(cubit.state.ignoring, isFalse);
      expect(cubit.state.selectionMode, isFalse);
      expect(cubit.state.ignoredCount, 2);
      expect(cubit.state.items.map((i) => i.id), ['b']);

      cubit.consumeIgnoredCount();
      expect(cubit.state.ignoredCount, isNull);
    });

    test(
      'a failed batch keeps the selection and reports the failure',
      () async {
        cubit.startSelection('a');
        repository.nextFailure = const CacheFailure('x');
        await cubit.ignoreSelected();
        expect(cubit.state.ignoreFailure, isA<CacheFailure>());
        expect(cubit.state.selectedIds, {'a'});
        expect(cubit.state.selectionMode, isTrue);
        expect(repository.rows['a']!.status, SmsImportStatus.pending);
      },
    );

    test('nothing selected: no call', () async {
      cubit.startSelection();
      await cubit.ignoreSelected();
      expect(cubit.state.ignoredCount, isNull);
      expect(repository.rows.values.every((r) => r.isPending), isTrue);
    });

    test('an item decided elsewhere leaves the selection', () async {
      cubit
        ..startSelection('a')
        ..toggleSelected('b');
      await repository.ignore({'a'});
      await pumpEventQueue();
      expect(cubit.state.selectedIds, {'b'});
    });

    test('toString is redacted', () {
      cubit.startSelection('a');
      expect(cubit.state.toString(), isNot(contains('Example Cafe')));
      expect(cubit.state.toString(), contains('selected: 1'));
    });
  });

  group('ImportReviewCubit Ignore and mute (T132)', () {
    late ReviewHarness h;

    setUp(() => h = ReviewHarness());
    tearDown(() => h.dispose());

    test('Ignore closes the item, adds nothing and advances', () async {
      h.repository.seed([
        buildPendingImport(id: 'a', fingerprint: 'a'),
        buildPendingImport(id: 'b', fingerprint: 'b'),
      ]);
      final cubit = h.build();
      addTearDown(cubit.close);
      await cubit.load('a');
      expect(cubit.canIgnore, isTrue);

      await cubit.ignore();
      expect(cubit.state.status, ImportReviewStatus.ignored);
      expect(cubit.state.isSettled, isTrue);
      expect(cubit.state.nextImportId, 'b');
      expect(h.repository.rows['a']!.status, SmsImportStatus.ignored);
      expect(h.repository.confirmCalls, isEmpty);
      expect(h.leases.isLeased('a'), isFalse);
    });

    test('Ignore on an item decided elsewhere shows already handled', () async {
      h.repository.seed([buildPendingImport(id: 'a')]);
      final cubit = h.build();
      addTearDown(cubit.close);
      await cubit.load('a');
      h.repository.rows.remove('a');
      await cubit.ignore();
      // The fake skips a missing id; the status is still settled.
      expect(cubit.state.isSettled, isTrue);
    });

    test('an Ignore failure stays on the form', () async {
      h.repository.seed([buildPendingImport(id: 'a')]);
      final cubit = h.build();
      addTearDown(cubit.close);
      await cubit.load('a');
      h.repository.nextFailure = const CacheFailure('x');
      await cubit.ignore();
      expect(cubit.state.status, ImportReviewStatus.ready);
      expect(cubit.state.failure, isA<CacheFailure>());
    });

    test('mute removes the sender\'s pending items and adds nothing', () async {
      h.repository.seed([
        buildPendingImport(id: 'a', fingerprint: 'a', senderId: 'BANKX'),
        buildPendingImport(id: 'b', fingerprint: 'b', senderId: 'BANKX'),
        buildPendingImport(id: 'c', fingerprint: 'c', senderId: 'OTHER'),
      ]);
      final cubit = h.build();
      addTearDown(cubit.close);
      await cubit.load('a');
      expect(cubit.canMuteSender, isTrue);

      await cubit.muteSender();
      expect(cubit.state.status, ImportReviewStatus.senderMuted);
      expect(cubit.state.mutedRemovedCount, 2);
      expect(cubit.state.nextImportId, 'c');
      expect(h.settings.mutedSenders, {'BANKX'});
      expect(h.repository.rows.keys, ['c']);
      expect(h.repository.tombstones, isEmpty);
      expect(h.repository.confirmCalls, isEmpty);
    });

    test('no sender (paste or share): mute is not offered', () async {
      h.repository.seed([
        buildPendingImport(id: 'a', senderId: null, source: SmsSource.paste),
      ]);
      final cubit = h.build();
      addTearDown(cubit.close);
      await cubit.load('a');
      expect(cubit.canMuteSender, isFalse);
      await cubit.muteSender();
      expect(cubit.state.status, ImportReviewStatus.ready);
      expect(h.settings.mutedSenders, isEmpty);
    });
  });

  group('IgnoredImportsCubit (T133)', () {
    late IgnoredImportsCubit cubit;
    late HubScanDeps deps;

    IgnoredImportsCubit build({bool capability = true, UndoIgnore? undo}) {
      deps = HubScanDeps(capability: capability);
      return IgnoredImportsCubit(
        WatchUndoList(repository),
        undo ?? UndoIgnore(repository),
        GetSmsCapability(deps.gateway),
        clock,
      );
    }

    tearDown(() async {
      await cubit.close();
      await deps.settings.close();
    });

    test('empty when nothing was ignored', () async {
      cubit = build();
      await cubit.open();
      expect(cubit.state.status, IgnoredImportsStatus.empty);
    });

    test('lists ignored and expired items only, with days left', () async {
      repository.seed([
        buildPendingImport(
          id: 'i',
          fingerprint: 'i',
          status: SmsImportStatus.ignored,
          decidedAt: clock.now().subtract(const Duration(days: 10)),
        ),
        buildPendingImport(
          id: 'e',
          fingerprint: 'e',
          status: SmsImportStatus.expired,
          decidedAt: clock.now().subtract(const Duration(days: 29, hours: 1)),
        ),
        buildPendingImport(id: 'p', fingerprint: 'p'),
        buildPendingImport(
          id: 'added',
          fingerprint: 'added',
          status: SmsImportStatus.added,
          decidedAt: clock.now(),
          savedRecordId: 's',
          savedRecordType: SavedRecordType.financeEntry,
        ),
      ]);
      cubit = build();
      await cubit.open();
      expect(cubit.state.status, IgnoredImportsStatus.ready);
      expect(cubit.state.items.map((i) => i.id).toSet(), {'i', 'e'});
      final byId = {for (final i in cubit.state.items) i.id: i};
      expect(cubit.state.daysLeft(byId['i']!), 20);
      expect(cubit.state.daysLeft(byId['e']!), 0);
      expect(cubit.state.scanAvailable, isTrue);
    });

    test('without the capability the copy is paste-only', () async {
      cubit = build(capability: false);
      await cubit.open();
      expect(cubit.state.scanAvailable, isFalse);
    });

    test(
      'Undo removes the item and its tombstone; restored is one-shot',
      () async {
        repository.seed([buildPendingImport(id: 'p', fingerprint: 'fp-p')]);
        await repository.ignore({'p'});
        expect(repository.tombstones, isNotEmpty);
        cubit = build();
        await cubit.open();
        await pumpEventQueue();

        final pending = cubit.undo('p');
        expect(cubit.state.undoingId, 'p');
        await pending;
        await pumpEventQueue();
        expect(cubit.state.undoingId, isNull);
        expect(cubit.state.restored, isTrue);
        expect(repository.rows, isEmpty);
        expect(repository.tombstones, isEmpty);
        expect(cubit.state.status, IgnoredImportsStatus.empty);

        cubit.consumeRestored();
        expect(cubit.state.restored, isFalse);
      },
    );

    test('Undo is single-flight', () async {
      final undo = _MockUndo();
      when(() => undo(any())).thenAnswer((_) async {
        await Future<void>.delayed(Duration.zero);
        return const Right(UndoResult());
      });
      cubit = build(undo: undo);
      await cubit.open();
      await Future.wait([cubit.undo('a'), cubit.undo('b')]);
      verify(() => undo('a')).called(1);
      verifyNever(() => undo('b'));
    });

    test('an Undo failure is reported; an already-gone item is not', () async {
      final undo = _MockUndo();
      when(
        () => undo('x'),
      ).thenAnswer((_) async => const Left(CacheFailure('x')));
      when(() => undo('gone')).thenAnswer(
        (_) async => const Left(NotFoundFailure('sms_import_missing')),
      );
      cubit = build(undo: undo);
      await cubit.open();
      await cubit.undo('x');
      expect(cubit.state.undoFailure, isA<CacheFailure>());
      expect(cubit.state.restored, isFalse);
      cubit.consumeUndoFailure();
      await cubit.undo('gone');
      expect(cubit.state.undoFailure, isNull);
    });

    test('toString is redacted', () async {
      repository.seed([
        buildPendingImport(
          status: SmsImportStatus.ignored,
          decidedAt: clock.now(),
          merchant: 'Secret Shop',
        ),
      ]);
      cubit = build();
      await cubit.open();
      expect(cubit.state.toString(), isNot(contains('Secret')));
      expect(cubit.state.toString(), isNot(contains('pending-1')));
    });
  });

  group('MutedSendersCubit (T134)', () {
    late FakeSmsImportSettingsRepository settings;
    late MutedSendersCubit cubit;

    setUp(() {
      settings = FakeSmsImportSettingsRepository();
    });
    tearDown(() async {
      await cubit.close();
      await settings.close();
    });

    MutedSendersCubit build({UnmuteSender? unmute}) => MutedSendersCubit(
      WatchMutedSenders(settings),
      unmute ?? UnmuteSender(settings),
    );

    test('empty without mutes', () async {
      cubit = build();
      await cubit.open();
      expect(cubit.state.status, MutedSendersStatus.empty);
    });

    test('lists sorted senders; unmute removes one', () async {
      settings.mutedSenders.addAll({'QNB', 'CIB'});
      cubit = build();
      await cubit.open();
      await pumpEventQueue();
      expect(cubit.state.senders, ['CIB', 'QNB']);

      await cubit.unmute('CIB');
      await pumpEventQueue();
      expect(cubit.state.unmuted, isTrue);
      expect(cubit.state.senders, ['QNB']);
      expect(settings.mutedSenders, {'QNB'});
      cubit.consumeUnmuted();
      expect(cubit.state.unmuted, isFalse);
    });

    test('unmute is single-flight and reports failures', () async {
      final unmute = _MockUnmute();
      when(() => unmute(any())).thenAnswer((_) async {
        await Future<void>.delayed(Duration.zero);
        return const Left(CacheFailure('x'));
      });
      settings.mutedSenders.add('CIB');
      cubit = build(unmute: unmute);
      await cubit.open();
      await Future.wait([cubit.unmute('CIB'), cubit.unmute('CIB')]);
      verify(() => unmute('CIB')).called(1);
      expect(cubit.state.unmuteFailure, isA<CacheFailure>());
      expect(cubit.state.unmuting, isNull);
    });
  });
}
