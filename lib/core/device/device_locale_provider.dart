import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// Thin, injectable abstraction over the device/OS's current system
/// locale. Wrapping this Flutter-framework read behind a one-method
/// interface keeps [AppLanguage]-resolution logic in Presentation
/// unit-testable without a real Flutter binding (research.md Decision 4).
abstract class DeviceLocaleProvider {
  Locale currentLocale();
}

@LazySingleton(as: DeviceLocaleProvider)
class DeviceLocaleProviderImpl implements DeviceLocaleProvider {
  @override
  Locale currentLocale() => WidgetsBinding.instance.platformDispatcher.locale;
}
