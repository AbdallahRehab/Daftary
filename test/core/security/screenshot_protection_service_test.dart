import 'dart:async';
import 'dart:io';

import 'package:daftary/core/security/screenshot_protection_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// T019 — the Dart side of the SecurityPlugin channel, against a
/// MethodChannel test double (no real OS screen capture).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methodChannel = MethodChannel(
    PlatformScreenshotProtectionService.methodChannelName,
  );

  late List<String> calls;
  late PlatformScreenshotProtectionService service;

  setUp(() {
    calls = [];
    service = PlatformScreenshotProtectionService();
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      calls.add(call.method);
      return call.method == 'isCaptured' ? true : null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(methodChannel, null));

  test('enable/disable invoke the platform channel', () async {
    await service.enable();
    await service.disable();
    expect(calls, ['enable', 'disable']);
  });

  test('isScreenCaptured reports the platform value', () async {
    expect(await service.isScreenCaptured(), isTrue);
  });

  test('platform errors never throw to the caller', () async {
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      throw PlatformException(code: 'boom');
    });
    await expectLater(service.enable(), completes);
    expect(await service.isScreenCaptured(), isFalse);
  });

  test('a missing plugin (tests/desktop) never throws', () async {
    messenger.setMockMethodCallHandler(methodChannel, null);
    await expectLater(service.enable(), completes);
    expect(await service.isScreenCaptured(), isFalse);
  });

  test('recording changes are streamed from the event channel', () async {
    const codec = StandardMethodCodec();
    messenger.setMockMessageHandler(
      PlatformScreenshotProtectionService.eventChannelName,
      (message) async {
        final call = codec.decodeMethodCall(message);
        if (call.method == 'listen') {
          for (final value in [true, false]) {
            await messenger.handlePlatformMessage(
              PlatformScreenshotProtectionService.eventChannelName,
              codec.encodeSuccessEnvelope(value),
              (_) {},
            );
          }
        }
        return codec.encodeSuccessEnvelope(null);
      },
    );
    expect(
      service.screenCaptureChanges.take(2).toList(),
      completion([true, false]),
    );
  });

  // FR-020: protection is always on, independent of App Lock's own state —
  // main.dart enables it unconditionally, before (and not inside) any App
  // Lock configuration check.
  test('main.dart enables protection unconditionally at startup', () {
    final main = File('lib/main.dart').readAsStringSync();
    final body = main.substring(
      main.indexOf('Future<void> main()'),
      main.indexOf('runApp('),
    );
    final line = body
        .split('\n')
        .firstWhere(
          (l) => l.contains('ScreenshotProtectionService>().enable()'),
        );
    expect(line.trim(), 'await getIt<ScreenshotProtectionService>().enable();');
    expect(body, isNot(contains('if (')));
  });

  // T065 — User Story 5 Scenario 4: protection is switched on before App
  // Lock's configuration is consulted at all. `AppLifecycleObserver
  // .initialize()` is main.dart's first read of App Lock state, so enable()
  // must come strictly before it, and neither may be conditional.
  test('main.dart enables protection before any App Lock check', () {
    final main = File('lib/main.dart').readAsStringSync();
    final body = main.substring(
      main.indexOf('Future<void> main()'),
      main.indexOf('runApp('),
    );
    final enableAt = body.indexOf(
      'await getIt<ScreenshotProtectionService>().enable();',
    );
    final firstAppLockRead = body.indexOf('AppLifecycleObserver>()');
    expect(enableAt, isNonNegative);
    expect(firstAppLockRead, isNonNegative);
    expect(enableAt, lessThan(firstAppLockRead));
    for (final appLockTerm in ['AppLockConfig', 'isEnabled', 'getConfig']) {
      expect(body.substring(0, enableAt), isNot(contains(appLockTerm)));
    }
  });

  // T066 — FR-021: a simulated iOS recording session
  // (`UIScreen.capturedDidChangeNotification` double). The overlay itself
  // is native; its Dart-visible state is the capture flag, which must enter
  // and leave the "captured" state exactly around the recording window.
  test('a simulated recording window is entered and exited', () async {
    const codec = StandardMethodCodec();
    var recording = false;
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      calls.add(call.method);
      return call.method == 'isCaptured' ? recording : null;
    });

    Future<void> capturedDidChange(bool value) async {
      recording = value;
      await messenger.handlePlatformMessage(
        PlatformScreenshotProtectionService.eventChannelName,
        codec.encodeSuccessEnvelope(value),
        (_) {},
      );
    }

    messenger.setMockMessageHandler(
      PlatformScreenshotProtectionService.eventChannelName,
      (message) async {
        final call = codec.decodeMethodCall(message);
        if (call.method == 'listen') {
          // SecurityPlugin.swift reports the current state on listen.
          scheduleMicrotask(() => capturedDidChange(recording));
        }
        return codec.encodeSuccessEnvelope(null);
      },
    );
    addTearDown(
      () => messenger.setMockMessageHandler(
        PlatformScreenshotProtectionService.eventChannelName,
        null,
      ),
    );

    final states = <bool>[];
    final subscription = service.screenCaptureChanges.listen(states.add);
    await pumpEventQueue();
    expect(states, [false]);
    expect(await service.isScreenCaptured(), isFalse);

    await capturedDidChange(true); // recording starts -> overlay up
    await pumpEventQueue();
    expect(states, [false, true]);
    expect(await service.isScreenCaptured(), isTrue);

    await capturedDidChange(false); // recording stops -> overlay down
    await pumpEventQueue();
    expect(states, [false, true, false]);
    expect(await service.isScreenCaptured(), isFalse);

    await subscription.cancel();
  });
}
