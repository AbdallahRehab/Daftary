import 'package:integration_test/integration_test_driver.dart';

/// Host side of `integration_test/readme/readme_screenshots_test.dart`; see
/// `tool/readme_screenshots.sh`.
Future<void> main() => integrationDriver(timeout: const Duration(minutes: 10));
