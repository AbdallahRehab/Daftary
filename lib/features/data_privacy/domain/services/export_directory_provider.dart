import 'dart:io';

/// Resolves the sandboxed directory export files are written to.
///
/// A collaborator rather than a direct `path_provider` call inside
/// `ExportUserData`, so the use case stays free of platform channels and a
/// test can substitute a throwaway temp directory.
abstract class ExportDirectoryProvider {
  Future<Directory> resolve();
}
