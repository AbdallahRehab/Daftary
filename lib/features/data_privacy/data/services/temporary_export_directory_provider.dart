import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/services/export_directory_provider.dart';

/// Places exports in an `exports/` subdirectory of the app's own temporary
/// (cache) directory: sandboxed, never backed up, and free for the OS to
/// reclaim once the user has shared the file (data-model.md "ExportResult").
@LazySingleton(as: ExportDirectoryProvider)
class TemporaryExportDirectoryProvider implements ExportDirectoryProvider {
  const TemporaryExportDirectoryProvider();

  static const _exportsDirName = 'exports';

  @override
  Future<Directory> resolve() async {
    final temp = await getTemporaryDirectory();
    return Directory(
      p.join(temp.path, _exportsDirName),
    ).create(recursive: true);
  }
}
