import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T067 (FR-100, FR-101, sms-platform-channel §4) — nothing in the feature
/// logs, and nothing imports analytics or crash reporting. Source greps,
/// each with a positive control so a broken pattern cannot pass silently.
void main() {
  const featureRoot = 'lib/features/sms_import';
  const kotlinFiles = [
    'android/app/src/main/kotlin/com/daftary/daftary/SmsPlugin.kt',
    'android/app/src/main/kotlin/com/daftary/daftary/ShareTargetActivity.kt',
  ];

  final dartLogging = RegExp(
    r'(^|[^\w.])print\(|\bdebugPrint\(|\bdebugPrintStack\(|developer\.log|\bLog\.|dart:developer',
  );
  final kotlinLogging = RegExp(
    r'\bprintln\(|printStackTrace\(|System\.out|System\.err|\bLog\.|\bTimber\.',
  );
  final telemetry = RegExp(
    r'''import\s+['"]package:(firebase_analytics|firebase_crashlytics|firebase_performance|sentry|sentry_flutter|sentry_dart_plugin|amplitude_flutter|mixpanel_flutter|datadog_flutter_plugin|bugsnag_flutter|appcenter|posthog_flutter|segment_analytics|instabug_flutter|newrelic_mobile|flutter_analytics|google_analytics|appsflyer_sdk|adjust_sdk)''',
  );

  List<File> dartFiles() =>
      Directory(featureRoot)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  List<String> hits(File file, RegExp pattern) {
    final lines = file.readAsLinesSync();
    return [
      for (var i = 0; i < lines.length; i++)
        if (pattern.hasMatch(lines[i])) '${file.path}:${i + 1}',
    ];
  }

  test('positive controls', () {
    expect(dartLogging.hasMatch("print('x');"), isTrue);
    expect(dartLogging.hasMatch('debugPrint(text);'), isTrue);
    expect(dartLogging.hasMatch('developer.log(x)'), isTrue);
    expect(dartLogging.hasMatch("import 'dart:developer';"), isTrue);
    expect(dartLogging.hasMatch('Log.d(tag, body)'), isTrue);
    expect(dartLogging.hasMatch('await hasher.fingerprint(body)'), isFalse);
    expect(kotlinLogging.hasMatch('Log.d("SMS", body)'), isTrue);
    expect(kotlinLogging.hasMatch('e.printStackTrace()'), isTrue);
    expect(kotlinLogging.hasMatch('System.out.println(x)'), isTrue);
    expect(
      telemetry.hasMatch("import 'package:firebase_crashlytics/x.dart';"),
      isTrue,
    );
    expect(
      telemetry.hasMatch("import 'package:sentry_flutter/s.dart';"),
      isTrue,
    );
  });

  test('no logging call under lib/features/sms_import', () {
    final files = dartFiles();
    expect(files, isNotEmpty);
    expect([for (final f in files) ...hits(f, dartLogging)], isEmpty);
  });

  test('no logging in the Kotlin SMS files (skipped when absent)', () {
    for (final path in kotlinFiles) {
      final file = File(path);
      if (!file.existsSync()) continue;
      expect(hits(file, kotlinLogging), isEmpty, reason: path);
    }
  });

  test('no analytics or crash-reporting import in sms_import', () {
    expect([for (final f in dartFiles()) ...hits(f, telemetry)], isEmpty);
  });
}
