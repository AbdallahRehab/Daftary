import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T085 — FR-079: screen-capture protection is enabled app-wide at startup
/// and nothing in the bank-message feature turns it off; the feature's
/// routes are declared inside the router that the single app-wide lock
/// gate wraps, so they sit behind App Lock like every other route.
void main() {
  List<File> dartFiles(String root) =>
      Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('screen protection is enabled at startup', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('getIt<ScreenshotProtectionService>().enable()'));
  });

  test('nothing in sms_import references screen protection or disables it', () {
    final offenders = <String>[];
    for (final file in dartFiles('lib/features/sms_import')) {
      final source = file.readAsStringSync();
      if (source.contains('ScreenshotProtectionService') ||
          source.contains('screenshot_protection_service') ||
          RegExp(r'\.disable\(\)').hasMatch(source) ||
          source.contains('FLAG_SECURE')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('positive control: the matcher finds a disable call', () {
    expect(
      RegExp(
        r'\.disable\(\)',
      ).hasMatch('getIt<ScreenshotProtectionService>().disable();'),
      isTrue,
    );
  });

  test('the lock gate wraps the router: every route is behind App Lock', () {
    final main = File('lib/main.dart').readAsStringSync();
    final routerAt = main.indexOf('routerConfig: appRouter');
    final gateAt = main.indexOf('AppLockGate(');
    expect(routerAt, isNonNegative);
    expect(gateAt, isNonNegative);
    // The gate is built in MaterialApp.router's `builder`, above the
    // router's Navigator, so no route can bypass it.
    expect(main.substring(routerAt, gateAt), contains('builder:'));
  });

  test('the list and review routes are in that router, review declared '
      'after the list (static paths first)', () {
    final router = File('lib/core/routing/app_router.dart').readAsStringSync();
    final hub = router.indexOf('path: BankMessagesRoutes.hub');
    final review = router.indexOf('path: BankMessagesRoutes.reviewPattern');
    expect(hub, isNonNegative);
    expect(review, greaterThan(hub));
    // Inside the shell (the People branch), like `/ocr/...`.
    final shell = router.indexOf('StatefulShellRoute.indexedStack(');
    expect(shell, isNonNegative);
    expect(hub, greaterThan(shell));
  });

  test('no screen of the feature passes content in a route', () {
    for (final file in dartFiles('lib/features/sms_import/presentation')) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('extra:')), reason: file.path);
    }
  });
}
