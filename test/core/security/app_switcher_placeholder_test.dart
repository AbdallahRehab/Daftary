import 'dart:io';

import 'package:daftary/core/security/app_switcher_placeholder.dart';
import 'package:flutter_test/flutter_test.dart';

/// T067 — the app-switcher placeholder is drawn natively; this pins the
/// native sources to the definition `AppSwitcherPlaceholder` documents, so
/// the two cannot drift apart silently.
void main() {
  test('iOS covers the window with the documented blur style', () {
    final swift = File('ios/Runner/SecurityPlugin.swift').readAsStringSync();
    expect(
      swift,
      contains('UIBlurEffect(style: .${AppSwitcherPlaceholder.iosBlurStyle})'),
    );
    expect(swift, contains('UIApplication.willResignActiveNotification'));
  });

  test('Android blanks the recents thumbnail with the documented flag', () {
    final kotlin = File(
      'android/app/src/main/kotlin/com/daftary/daftary/SecurityPlugin.kt',
    ).readAsStringSync();
    expect(
      kotlin,
      contains(
        'WindowManager.LayoutParams.${AppSwitcherPlaceholder.androidWindowFlag}',
      ),
    );
  });
}
