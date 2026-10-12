import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/shared_text_source.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_pasted_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_shared_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockImportPasted extends Mock implements ImportPastedText {}

/// T089 — `ImportSharedText`: the cold-start share once, warm shares in
/// order, each released only after unlock; staged through the paste path
/// as `SmsSource.share`.
void main() {
  late FakeSharedTextSource source;
  late FakeLockStatus lock;
  late _MockImportPasted importPasted;
  late ImportSharedText importShared;

  setUpAll(() => registerFallbackValue(SmsSource.paste));

  setUp(() {
    source = FakeSharedTextSource();
    lock = FakeLockStatus();
    importPasted = _MockImportPasted();
    importShared = ImportSharedText(source, lock, importPasted);
    when(
      () => importPasted(
        text: any(named: 'text'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => Right(PasteImportResult(summary: ScanSummary())));
  });
  tearDown(() async {
    // A never-listened single-subscription controller's close() future
    // never completes, so it is not awaited.
    unawaited(source.close());
    await lock.close();
  });

  group('unlockedShares', () {
    test('delivers the cold-start share once', () async {
      source.initial = const SharedText(text: 'cold');
      final received = <SharedText>[];
      final sub = importShared.unlockedShares().listen(received.add);
      await pumpEventQueue();
      expect(received, [const SharedText(text: 'cold')]);
      expect(source.initialReads, 1);
      await sub.cancel();
    });

    test('delivers warm shares in order', () async {
      final received = <String>[];
      final sub = importShared.unlockedShares().listen(
        (s) => received.add(s.text),
      );
      await pumpEventQueue();
      source.share('one');
      source.share('two');
      await pumpEventQueue();
      expect(received, ['one', 'two']);
      await sub.cancel();
    });

    test('waits while locked and releases after unlock', () async {
      lock.lock();
      source.initial = const SharedText(text: 'cold');
      final received = <String>[];
      final sub = importShared.unlockedShares().listen(
        (s) => received.add(s.text),
      );
      await pumpEventQueue();
      source.share('warm');
      await pumpEventQueue();
      expect(received, isEmpty);

      lock.unlock();
      await pumpEventQueue();
      expect(received, ['cold', 'warm']);
      await sub.cancel();
    });

    test('a lock that lands later holds the next share', () async {
      final received = <String>[];
      final sub = importShared.unlockedShares().listen(
        (s) => received.add(s.text),
      );
      await pumpEventQueue();
      lock.lock();
      source.share('while locked');
      await pumpEventQueue();
      expect(received, isEmpty);
      lock.unlock();
      await pumpEventQueue();
      expect(received, ['while locked']);
      await sub.cancel();
    });
  });

  group('call', () {
    test('stages the text through the paste path as a share', () async {
      final result = await importShared(const SharedText(text: 'msg'));
      expect(result.isRight(), isTrue);
      verify(
        () => importPasted(text: 'msg', source: SmsSource.share),
      ).called(1);
    });

    test('a truncated share is too long and never parsed in part', () async {
      final result = await importShared(
        const SharedText(text: 'cut', truncated: true),
      );
      expect(
        result,
        const Left<Failure, PasteImportResult>(
          InputTooLargeFailure(InputLimit.characters),
        ),
      );
      verifyNever(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      );
    });

    test('waits for unlock before parsing', () async {
      lock.lock();
      var done = false;
      final pending = importShared(
        const SharedText(text: 'msg'),
      ).then((_) => done = true);
      await pumpEventQueue();
      expect(done, isFalse);
      verifyNever(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      );
      lock.unlock();
      await pending;
      expect(done, isTrue);
    });

    test('not recognized is passed through (nothing stored)', () async {
      when(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => const Left(NotRecognizedFailure()));
      final result = await importShared(const SharedText(text: 'noise'));
      expect(
        result,
        const Left<Failure, PasteImportResult>(NotRecognizedFailure()),
      );
    });
  });

  test('SharedText.toString is redacted', () {
    const shared = SharedText(text: 'Purchase of EGP 125.50 at Cafe');
    expect(shared.toString(), isNot(contains('Cafe')));
    expect(shared.toString(), isNot(contains('125')));
  });

  test('unlockedShares cancels cleanly', () async {
    final sub = importShared.unlockedShares().listen((_) {});
    await pumpEventQueue();
    await expectLater(sub.cancel(), completes);
  });
}
