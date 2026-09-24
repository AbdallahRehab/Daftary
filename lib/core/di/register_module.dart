import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import '../database/app_database.dart';
import '../money/egp_formatter.dart';

/// Registers third-party/leaf dependencies that aren't themselves annotated
/// with `@injectable` (research.md Decision 11: the DB file lives in the
/// app's sandboxed documents directory, opened lazily by [AppDatabase]'s
/// own default constructor).
@module
abstract class RegisterModule {
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();

  @lazySingleton
  EgpFormatter get egpFormatter => EgpFormatter();

  @lazySingleton
  ImagePicker get imagePicker => ImagePicker();

  /// Shared OS keychain/keystore handle (moved here from the AI assistant's
  /// own module once 015 App Lock became its second user). Android:
  /// `EncryptedSharedPreferences` (Keystore-backed) rather than the legacy
  /// RSA-wrapped store. iOS: the default Keychain accessibility (available
  /// after first unlock). Each feature namespaces its own keys and reaches
  /// storage only through its own data source.
  @lazySingleton
  FlutterSecureStorage get flutterSecureStorage => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
}
