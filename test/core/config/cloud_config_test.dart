import 'package:daftary/core/config/cloud_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// 021 T004: a plain `flutter test` passes no `--dart-define`s, so the app
/// must see itself as unconfigured and stay fully local.
void main() {
  test('is not configured when no build-time defines are supplied', () {
    expect(CloudConfig.url, isEmpty);
    expect(CloudConfig.publishableKey, isEmpty);
    expect(CloudConfig.isConfigured, isFalse);
  });
}
