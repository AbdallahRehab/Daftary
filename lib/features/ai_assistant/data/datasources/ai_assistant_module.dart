import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Registers the third-party leaf dependency the AI assistant's data layer
/// needs, mirroring `RegisterModule` in `core/di` but kept inside the
/// feature so no other feature can take a dependency on it by accident.
@module
abstract class AIAssistantModule {
  /// Android: `EncryptedSharedPreferences` (Keystore-backed) rather than the
  /// legacy RSA-wrapped store. iOS: the default Keychain accessibility
  /// (available after first unlock).
  @lazySingleton
  FlutterSecureStorage get flutterSecureStorage => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
}
