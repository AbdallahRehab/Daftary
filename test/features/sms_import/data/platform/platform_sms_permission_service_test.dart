import 'dart:async';

import 'package:daftary/features/sms_import/data/platform/platform_sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/data/platform/platform_sms_permission_service.dart';
import 'package:daftary/features/sms_import/data/platform/sms_channel_client.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

/// 023 T107: `PlatformSmsPermissionService` over the real channel client
/// with canned plugin replies (sms-platform-channel §2.2, §2.3, §2.7).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = MethodChannel(SmsChannelClient.methodChannelName);
  const appSettingsChannel = MethodChannel(
    'com.spencerccf.app_settings/methods',
  );
  final calls = <MethodCall>[];
  final appSettingsCalls = <MethodCall>[];
  late FakeSmsImportSettingsRepository settings;
  var appInfoOpens = 0;

  Map<String, Object?> requestReply({
    bool granted = false,
    bool rationale = false,
    bool dialogShown = true,
    int sdkInt = 34,
    String installSource = 'store',
  }) => {
    'granted': granted,
    'shouldShowRationale': rationale,
    'dialogShown': dialogShown,
    'sdkInt': sdkInt,
    'installSource': installSource,
  };

  void reply({
    bool declared = true,
    Object? Function()? state,
    Object? Function()? request,
  }) {
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      return switch (call.method) {
        'getCapabilities' => {'readSmsDeclared': declared, 'sdkInt': 35},
        'getPermissionState' =>
          state?.call() ?? {'granted': false, 'shouldShowRationale': false},
        'requestPermission' => request?.call() ?? requestReply(),
        _ => throw MissingPluginException(),
      };
    });
  }

  List<String> permissionCalls() => [
    for (final c in calls)
      if (c.method != 'getCapabilities') c.method,
  ];

  PlatformSmsPermissionService build({OpenAppInfoScreen? open}) {
    final channel = SmsChannelClient();
    return PlatformSmsPermissionService(
      channel,
      PlatformSmsInboxGateway(channel),
      settings,
      openAppInfoScreen:
          open ??
          () async {
            appInfoOpens++;
          },
    );
  }

  setUp(() {
    calls.clear();
    appSettingsCalls.clear();
    appInfoOpens = 0;
    settings = FakeSmsImportSettingsRepository();
  });
  tearDown(() {
    messenger
      ..setMockMethodCallHandler(methods, null)
      ..setMockMethodCallHandler(appSettingsChannel, null);
  });

  group('capability off (READ_SMS not declared)', () {
    test('every method answers without a permission call', () async {
      reply(declared: false);
      final service = build();
      expect(
        (await service.getStatus()).getOrElse(
          (_) => SmsPermissionStatus.granted,
        ),
        SmsPermissionStatus.unavailable,
      );
      expect(
        (await service.request(
          previouslyRequested: false,
        )).getOrElse((_) => SmsPermissionStatus.granted),
        SmsPermissionStatus.unavailable,
      );
      expect((await service.openAppInfo()).isRight(), isTrue);
      expect(permissionCalls(), isEmpty);
      expect(appInfoOpens, 0);
    });

    test('no plugin at all -> unavailable', () async {
      final service = build();
      expect(
        (await service.getStatus()).getOrElse(
          (_) => SmsPermissionStatus.granted,
        ),
        SmsPermissionStatus.unavailable,
      );
    });
  });

  group('getStatus (never prompts)', () {
    Future<SmsPermissionStatus> status({
      required bool granted,
      required bool rationale,
      SmsImportSettings stored = const SmsImportSettings(),
    }) async {
      settings = FakeSmsImportSettingsRepository(settings: stored);
      reply(
        state: () => {'granted': granted, 'shouldShowRationale': rationale},
      );
      final result = await build().getStatus();
      expect(permissionCalls(), ['getPermissionState']);
      return result.getOrElse((_) => SmsPermissionStatus.unavailable);
    }

    test('granted', () async {
      expect(
        await status(granted: true, rationale: false),
        SmsPermissionStatus.granted,
      );
    });

    test('never asked -> denied (not permanently)', () async {
      expect(
        await status(granted: false, rationale: false),
        SmsPermissionStatus.denied,
      );
    });

    test('asked before, no rationale -> permanentlyDenied', () async {
      expect(
        await status(
          granted: false,
          rationale: false,
          stored: const SmsImportSettings(permissionRequested: true),
        ),
        SmsPermissionStatus.permanentlyDenied,
      );
    });

    test('asked before, rationale -> denied', () async {
      expect(
        await status(
          granted: false,
          rationale: true,
          stored: const SmsImportSettings(permissionRequested: true),
        ),
        SmsPermissionStatus.denied,
      );
    });

    test('enabled (granted before) and now off -> revoked', () async {
      expect(
        await status(
          granted: false,
          rationale: false,
          stored: const SmsImportSettings(
            isEnabled: true,
            permissionRequested: true,
          ),
        ),
        SmsPermissionStatus.revoked,
      );
    });

    test('never infers restricted settings', () async {
      expect(
        await status(granted: false, rationale: false),
        isNot(SmsPermissionStatus.restrictedBlocked),
      );
    });

    test('a malformed reply is a failure', () async {
      reply(state: () => {'granted': 'yes'});
      expect((await build().getStatus()).isLeft(), isTrue);
    });

    test('a channel unavailable is the unavailable status', () async {
      reply(state: () => throw PlatformException(code: 'unavailable'));
      expect(
        (await build().getStatus()).getOrElse(
          (_) => SmsPermissionStatus.granted,
        ),
        SmsPermissionStatus.unavailable,
      );
    });
  });

  group('request', () {
    Future<SmsPermissionStatus> request(
      Map<String, Object?> platform, {
      bool previouslyRequested = false,
    }) async {
      reply(request: () => platform);
      final result = await build().request(
        previouslyRequested: previouslyRequested,
      );
      return result.getOrElse((_) => SmsPermissionStatus.unavailable);
    }

    test('calls requestPermission once and maps granted', () async {
      expect(
        await request(requestReply(granted: true)),
        SmsPermissionStatus.granted,
      );
      expect(permissionCalls(), ['requestPermission']);
    });

    test('first denial with no rationale is denied, not permanently '
        '(previouslyRequested comes from the caller)', () async {
      expect(await request(requestReply()), SmsPermissionStatus.denied);
    });

    test('a repeat denial with no rationale is permanentlyDenied', () async {
      expect(
        await request(requestReply(), previouslyRequested: true),
        SmsPermissionStatus.permanentlyDenied,
      );
    });

    test('no dialog on Android 15 from a non-store install -> '
        'restrictedBlocked', () async {
      expect(
        await request(
          requestReply(
            dialogShown: false,
            sdkInt: 35,
            installSource: 'notStore',
          ),
        ),
        SmsPermissionStatus.restrictedBlocked,
      );
    });

    test('an unknown install source is not a store', () async {
      expect(
        await request(
          requestReply(dialogShown: false, sdkInt: 35, installSource: 'x'),
        ),
        SmsPermissionStatus.restrictedBlocked,
      );
    });

    test('a store install is never restrictedBlocked', () async {
      expect(
        await request(requestReply(dialogShown: false, sdkInt: 35)),
        isNot(SmsPermissionStatus.restrictedBlocked),
      );
    });

    test('platform errors map to typed failures', () async {
      for (final code in ['no_activity', 'request_in_progress']) {
        reply(request: () => throw PlatformException(code: code));
        final result = await build().request(previouslyRequested: false);
        expect(
          result.getLeft().toNullable(),
          const SmsPermissionFailure(SmsPermissionStatus.denied),
        );
      }
    });

    test('a malformed reply is a failure', () async {
      reply(request: () => {'granted': true});
      final result = await build().request(previouslyRequested: false);
      expect(result.isLeft(), isTrue);
    });

    test('concurrent calls share one platform request', () async {
      final gate = Completer<void>();
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call);
        if (call.method == 'getCapabilities') {
          return {'readSmsDeclared': true, 'sdkInt': 35};
        }
        await gate.future;
        return requestReply(granted: true);
      });
      final service = build();
      final first = service.request(previouslyRequested: false);
      final second = service.request(previouslyRequested: false);
      gate.complete();
      expect(await first, await second);
      expect(permissionCalls(), ['requestPermission']);
      // Released afterwards: a later call asks again.
      await service.request(previouslyRequested: true);
      expect(permissionCalls(), ['requestPermission', 'requestPermission']);
    });
  });

  group('openAppInfo', () {
    test('opens the App info screen without a permission call', () async {
      reply();
      expect((await build().openAppInfo()).isRight(), isTrue);
      expect(appInfoOpens, 1);
      expect(permissionCalls(), isEmpty);
    });

    test('a failure is a fixed token', () async {
      reply();
      final result = await build(
        open: () async =>
            throw PlatformException(code: 'x', message: 'synthetic detail'),
      ).openAppInfo();
      expect(
        result.getLeft().toNullable(),
        PlatformSmsPermissionService.appInfoUnavailable,
      );
    });

    test('the default opener is app_settings with the default '
        '(app details) type', () async {
      reply();
      messenger.setMockMethodCallHandler(appSettingsChannel, (call) async {
        appSettingsCalls.add(call);
        return null;
      });
      final channel = SmsChannelClient();
      final service = PlatformSmsPermissionService(
        channel,
        PlatformSmsInboxGateway(channel),
        settings,
      );
      expect((await service.openAppInfo()).isRight(), isTrue);
      expect(appSettingsCalls, hasLength(1));
      expect(appSettingsCalls.single.method, 'openSettings');
      expect((appSettingsCalls.single.arguments as Map)['type'], 'settings');
    });
  });
}
