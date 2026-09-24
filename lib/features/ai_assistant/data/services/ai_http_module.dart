import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

/// Registers the single [http.Client] the AI assistant talks to its
/// provider through (research.md Decision 2). This is the app's only
/// network dependency.
@module
abstract class AIHttpModule {
  @lazySingleton
  http.Client get httpClient => http.Client();
}
