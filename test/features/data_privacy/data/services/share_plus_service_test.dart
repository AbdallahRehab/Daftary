import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/features/data_privacy/data/services/share_plus_service.dart';
import 'package:daftary/features/data_privacy/domain/services/share_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/security/helpers/test_app_lifecycle_observer.dart';

class MockSharePlus extends Mock implements SharePlus {}

/// T019 — `SharePlusService` maps every platform outcome to an [Either]:
/// presenting the sheet (whatever the user then does with it) is success,
/// and any platform error is a typed [ShareFailure], never a raw throw.
void main() {
  late MockSharePlus sharePlus;
  late SharePlusService service;
  late AppLifecycleObserver lifecycle;

  setUpAll(() => registerFallbackValue(ShareParams(text: 'fallback')));

  setUp(() {
    sharePlus = MockSharePlus();
    lifecycle = testAppLifecycleObserver(lockTimeout: Duration.zero);
    service = SharePlusService.withSharePlus(sharePlus, lifecycle);
  });

  void stubResult(ShareResultStatus status) {
    when(
      () => sharePlus.share(any()),
    ).thenAnswer((_) async => ShareResult('raw', status));
  }

  test('hands the file and subject to the share sheet', () async {
    stubResult(ShareResultStatus.success);

    final result = await service.shareFile(
      filePath: '/tmp/export.csv',
      subject: 'My data',
    );

    expect(result, const Right<Failure, Unit>(unit));
    final params =
        verify(() => sharePlus.share(captureAny())).captured.single
            as ShareParams;
    expect(params.files!.single.path, '/tmp/export.csv');
    expect(params.subject, 'My data');
  });

  for (final status in ShareResultStatus.values) {
    test('a presented sheet is success whatever the user did '
        '(${status.name})', () async {
      stubResult(status);

      final result = await service.shareFile(filePath: '/tmp/export.csv');

      // Dismissing the sheet is a normal outcome, never an error.
      expect(result, const Right<Failure, Unit>(unit));
    });
  }

  test('a platform exception becomes a ShareFailure', () async {
    when(
      () => sharePlus.share(any()),
    ).thenThrow(PlatformException(code: 'boom', message: 'no activity'));

    final result = await service.shareFile(filePath: '/tmp/export.csv');

    expect(result.getLeft().toNullable(), isA<ShareFailure>());
  });

  test('any other error becomes a ShareFailure too', () async {
    when(() => sharePlus.share(any())).thenThrow(StateError('unexpected'));

    final result = await service.shareFile(filePath: '/tmp/export.csv');

    expect(result.getLeft().toNullable(), isA<ShareFailure>());
  });

  // 015 FR-010: the share sheet can background the app on Android; with
  // App Lock set to lock immediately, returning must not show a lock screen.
  test('sharing never triggers App Lock', () async {
    when(() => sharePlus.share(any())).thenAnswer((_) async {
      lifecycle
        ..didChangeAppLifecycleState(AppLifecycleState.paused)
        ..didChangeAppLifecycleState(AppLifecycleState.resumed);
      return const ShareResult('raw', ShareResultStatus.success);
    });

    await service.shareFile(filePath: '/tmp/export.csv');
    await pumpEventQueue();

    expect(lifecycle.isLocked.value, isFalse);
  });
}
