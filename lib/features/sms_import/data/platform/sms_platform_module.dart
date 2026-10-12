import 'dart:io' show Platform;

import 'package:injectable/injectable.dart';

import '../../domain/repositories/sms_import_settings_repository.dart';
import '../../domain/services/shared_text_source.dart';
import '../../domain/services/sms_inbox_gateway.dart';
import '../../domain/services/sms_permission_service.dart';
import 'platform_shared_text_source.dart';
import 'platform_sms_inbox_gateway.dart';
import 'platform_sms_permission_service.dart';
import 'sms_channel_client.dart';
import 'unavailable_shared_text_source.dart';
import 'unavailable_sms_inbox_gateway.dart';
import 'unavailable_sms_permission_service.dart';

/// Chooses the SMS platform adapters once, at the composition root, so the
/// domain and presentation never branch on the platform (constitution X,
/// briefing rule 11; discovery di.md).
///
/// `dart:io` `Platform.isAndroid`, not `defaultTargetPlatform`: under
/// `flutter test` the latter reports android, while the host here is never
/// Android, so tests always get the `Unavailable*` adapters.
///
/// The adapter classes themselves carry no injectable annotation, so no
/// port is ever registered twice.
///
/// On Android, `PlatformSharedTextSource` (T095) is selected in every
/// build, with or without the READ_SMS capability (sharing needs no
/// permission). `PlatformSmsInboxGateway` and `PlatformSmsPermissionService`
/// (T107) are selected on Android too; in a build without READ_SMS they
/// short-circuit to "unavailable" without an inbox or permission call.
@module
abstract class SmsPlatformModule {
  @lazySingleton
  SmsInboxGateway smsInboxGateway(SmsChannelClient channel) =>
      selectForPlatform(
        isAndroid: Platform.isAndroid,
        android: () => PlatformSmsInboxGateway(channel),
        other: () => const UnavailableSmsInboxGateway(),
      );

  @lazySingleton
  SmsPermissionService smsPermissionService(
    SmsChannelClient channel,
    SmsInboxGateway gateway,
    SmsImportSettingsRepository settings,
  ) => selectForPlatform(
    isAndroid: Platform.isAndroid,
    android: () => PlatformSmsPermissionService(channel, gateway, settings),
    other: () => const UnavailableSmsPermissionService(),
  );

  @lazySingleton
  SharedTextSource sharedTextSource(SmsChannelClient channel) =>
      selectForPlatform(
        isAndroid: Platform.isAndroid,
        android: () => PlatformSharedTextSource(channel),
        other: () => const UnavailableSharedTextSource(),
      );
}

/// The pure selection, testable without faking `Platform.isAndroid`.
T selectForPlatform<T>({
  required bool isAndroid,
  required T Function() android,
  required T Function() other,
}) => isAndroid ? android() : other();
