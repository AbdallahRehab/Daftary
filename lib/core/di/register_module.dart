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
}
