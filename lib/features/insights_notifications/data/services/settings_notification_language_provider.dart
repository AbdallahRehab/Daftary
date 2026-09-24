import 'package:injectable/injectable.dart';

import '../../../../core/device/device_locale_provider.dart';
import '../../../settings/domain/entities/app_language.dart';
import '../../../settings/domain/usecases/get_language_preference.dart';
import '../../domain/ports/notification_language_provider.dart';

/// Reads the language the user chose in Settings, falling back to the same
/// first-launch default `SettingsCubit` applies (the device language when
/// it is Arabic or English, else English), so a notification is always in
/// the language the app itself is shown in.
@LazySingleton(as: NotificationLanguageProvider)
class SettingsNotificationLanguageProvider
    implements NotificationLanguageProvider {
  const SettingsNotificationLanguageProvider(
    this._getLanguagePreference,
    this._deviceLocaleProvider,
  );

  final GetLanguagePreference _getLanguagePreference;
  final DeviceLocaleProvider _deviceLocaleProvider;

  @override
  Future<String> currentLanguageCode() async {
    final persisted = (await _getLanguagePreference()).getOrElse((_) => null);
    if (persisted != null) return persisted.code;

    final deviceCode = _deviceLocaleProvider.currentLocale().languageCode;
    return AppLanguage.values
            .where((l) => l.code == deviceCode)
            .firstOrNull
            ?.code ??
        AppLanguage.english.code;
  }
}
