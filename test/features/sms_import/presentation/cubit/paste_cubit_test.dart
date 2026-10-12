import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/shared_text_source.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_pasted_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_shared_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/read_clipboard_text.dart';
import 'package:daftary/features/sms_import/presentation/cubit/paste_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/paste_state.dart';
import 'package:daftary/features/sms_import/presentation/shared_text_inbox.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockImportPasted extends Mock implements ImportPastedText {}

class _MockImportShared extends Mock implements ImportSharedText {}

const _secret = 'Purchase of EGP 125.50 at Example Cafe card ****0000';

PasteImportResult _result({
  int scanned = 1,
  int recognized = 1,
  List<String> ids = const ['id-1'],
  int unreadable = 0,
}) => PasteImportResult(
  summary: ScanSummary(
    scanned: scanned,
    recognized: recognized,
    createdPending: ids.length,
    unreadable: unreadable,
  ),
  newIds: ids,
);

/// T087 — `PasteCubit`: the clipboard is read only on the Paste tap; empty
/// clipboard, bounds, not recognized, multi-message summary, the shared
/// inbox consumed once, and a redacted `toString`.
void main() {
  late FakeClipboardReader clipboard;
  late _MockImportPasted importPasted;
  late _MockImportShared importShared;
  late SharedTextInbox inbox;
  late PasteCubit cubit;

  setUpAll(() {
    registerFallbackValue(SmsSource.paste);
    registerFallbackValue(const SharedText(text: ''));
  });

  setUp(() {
    clipboard = FakeClipboardReader();
    importPasted = _MockImportPasted();
    importShared = _MockImportShared();
    inbox = SharedTextInbox();
    cubit = PasteCubit(
      ReadClipboardText(clipboard),
      importPasted,
      importShared,
      inbox,
    );
    when(
      () => importPasted(
        text: any(named: 'text'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => Right(_result()));
    when(() => importShared(any())).thenAnswer((_) async => Right(_result()));
  });
  tearDown(() async {
    await cubit.close();
    await inbox.dispose();
  });

  test('opening reads no clipboard', () async {
    clipboard.text = _secret;
    await cubit.open();
    expect(clipboard.reads, 0);
    expect(cubit.state.status, PasteStatus.ready);
  });

  group('Paste tap', () {
    test('reads the clipboard once and returns its text', () async {
      clipboard.text = _secret;
      final text = await cubit.pasteFromClipboard();
      expect(text, _secret);
      expect(clipboard.reads, 1);
      expect(cubit.state.status, PasteStatus.ready);
      // The cubit never keeps the text.
      expect(cubit.state.toString(), isNot(contains('Cafe')));
    });

    test('an empty clipboard is the nothing-to-paste state', () async {
      clipboard.text = null;
      expect(await cubit.pasteFromClipboard(), isNull);
      expect(cubit.state.status, PasteStatus.clipboardEmpty);
    });

    test('whitespace only counts as empty', () async {
      clipboard.text = '  \n ';
      expect(await cubit.pasteFromClipboard(), isNull);
      expect(cubit.state.status, PasteStatus.clipboardEmpty);
    });

    test('reading the clipboard never processes on its own', () async {
      clipboard.text = _secret;
      await cubit.pasteFromClipboard();
      verifyNever(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      );
    });
  });

  group('process', () {
    test('stages the text as a paste and reports the summary', () async {
      when(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      ).thenAnswer(
        (_) async => Right(_result(scanned: 3, recognized: 2, ids: ['a', 'b'])),
      );
      await cubit.process(_secret);
      verify(
        () => importPasted(text: _secret, source: SmsSource.paste),
      ).called(1);
      expect(cubit.state.status, PasteStatus.recognized);
      expect(cubit.state.recognizedCount, 2);
      expect(cubit.state.skippedCount, 1);
      expect(cubit.state.result!.newIds, ['a', 'b']);
      expect(cubit.state.fromShare, isFalse);
    });

    test('passes through processing', () async {
      final states = <PasteStatus>[];
      final sub = cubit.stream.listen((s) => states.add(s.status));
      await cubit.process(_secret);
      await pumpEventQueue();
      expect(states, [PasteStatus.processing, PasteStatus.recognized]);
      await sub.cancel();
    });

    test('empty text does nothing', () async {
      await cubit.process('   ');
      expect(cubit.state.status, PasteStatus.ready);
      verifyNever(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      );
    });

    test('not recognized: the state says so and nothing else', () async {
      when(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => const Left(NotRecognizedFailure()));
      await cubit.process(_secret);
      expect(cubit.state.status, PasteStatus.notRecognized);
      expect(cubit.state.result, isNull);
    });

    test('bounds exceeded names the limit', () async {
      when(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      ).thenAnswer(
        (_) async => const Left(InputTooLargeFailure(InputLimit.messages)),
      );
      await cubit.process(_secret);
      expect(cubit.state.status, PasteStatus.tooLarge);
      expect(cubit.state.tooLargeLimit, InputLimit.messages);
    });

    test('unreadable only offers manual entry', () async {
      when(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      ).thenAnswer(
        (_) async => Right(_result(recognized: 0, ids: [], unreadable: 1)),
      );
      await cubit.process(_secret);
      expect(cubit.state.status, PasteStatus.unreadableOnly);
    });

    test('a storage failure is an error state', () async {
      when(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('x')));
      await cubit.process(_secret);
      expect(cubit.state.status, PasteStatus.error);
      expect(cubit.state.failure, const CacheFailure('x'));
    });

    test('reset returns to ready', () async {
      when(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => const Left(NotRecognizedFailure()));
      await cubit.process(_secret);
      cubit.reset();
      expect(cubit.state.status, PasteStatus.ready);
    });
  });

  group('shared text', () {
    test('open consumes a waiting share once, as a share', () async {
      inbox.put(const SharedText(text: _secret));
      await cubit.open();
      verify(() => importShared(const SharedText(text: _secret))).called(1);
      expect(inbox.hasPending, isFalse);
      expect(cubit.state.status, PasteStatus.recognized);
      expect(cubit.state.fromShare, isTrue);

      await cubit.consumeShared();
      verifyNever(() => importShared(any()));
      expect(clipboard.reads, 0);
    });

    test('a share arriving while open is consumed', () async {
      await cubit.open();
      inbox.put(const SharedText(text: 'warm'));
      await pumpEventQueue();
      verify(() => importShared(const SharedText(text: 'warm'))).called(1);
      expect(inbox.hasPending, isFalse);
    });

    test('a share arriving during a paste is consumed after it', () async {
      await cubit.open();
      final processing = cubit.process(_secret);
      inbox.put(const SharedText(text: 'warm'));
      await processing;
      await pumpEventQueue();
      verify(() => importShared(const SharedText(text: 'warm'))).called(1);
    });

    test('nothing waiting: open does nothing', () async {
      await cubit.open();
      verifyNever(() => importShared(any()));
      expect(cubit.state.status, PasteStatus.ready);
    });

    test('a not-recognized share stores nothing and says so', () async {
      when(
        () => importShared(any()),
      ).thenAnswer((_) async => const Left(NotRecognizedFailure()));
      inbox.put(const SharedText(text: 'noise'));
      await cubit.open();
      expect(cubit.state.status, PasteStatus.notRecognized);
      expect(cubit.state.fromShare, isTrue);
    });
  });

  test('toString is redacted', () async {
    await cubit.process(_secret);
    final text = cubit.state.toString();
    expect(text, isNot(contains('Cafe')));
    expect(text, isNot(contains('125')));
    expect(text, isNot(contains('id-1')));
    expect(text, contains('recognized'));
  });

  test('the inbox is in memory, returns a share once, and its toString is '
      'redacted', () {
    inbox.put(const SharedText(text: _secret));
    expect(inbox.toString(), isNot(contains('Cafe')));
    expect(inbox.take(), const SharedText(text: _secret));
    expect(inbox.take(), isNull);
  });

  test('a newer share replaces an unconsumed older one', () {
    inbox.put(const SharedText(text: 'old'));
    inbox.put(const SharedText(text: 'new'));
    expect(inbox.take()!.text, 'new');
    expect(inbox.take(), isNull);
  });
}
