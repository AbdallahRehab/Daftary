import 'dart:io';

import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/scan_presentation.dart';

/// T123 — FR-002: no SMS permission is requested on app start, on install
/// or from any screen other than the explicit enable flow.
///
/// Two halves: a static guard over `lib/` (the request path has exactly
/// one entry, the enable flow, and nothing on the startup path can reach
/// it), and a behavioural check that every SMS surface Home, Settings and
/// the hub open at start-up reads state without prompting.
void main() {
  /// Code lines of [file], with whole-line comments dropped.
  List<String> codeLines(File file) => file
      .readAsLinesSync()
      .where((line) => !line.trimLeft().startsWith('//'))
      .toList();

  List<File> dartFiles(String path) =>
      Directory(path)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('.g.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  /// Files under `lib/` whose code (not comments) matches [pattern].
  Set<String> filesUsing(RegExp pattern) => {
    for (final file in dartFiles('lib'))
      if (codeLines(file).any(pattern.hasMatch)) file.path,
  };

  test('the platform request is reached only through RequestSmsPermission', () {
    expect(filesUsing(RegExp(r'\.request\(\s*previouslyRequested')), {
      'lib/features/sms_import/domain/usecases/request_sms_permission.dart',
    });
    expect(filesUsing(RegExp("'requestPermission'")), {
      'lib/features/sms_import/data/platform/sms_channel_client.dart',
    });
  });

  test('RequestSmsPermission is used only by EnableSmsImport', () {
    expect(filesUsing(RegExp(r'\bRequestSmsPermission\b')), {
      'lib/core/di/injection.config.dart',
      'lib/features/sms_import/domain/usecases/enable_sms_import.dart',
      'lib/features/sms_import/domain/usecases/request_sms_permission.dart',
    });
  });

  test('EnableSmsImport is used only by the enable flow cubit', () {
    expect(filesUsing(RegExp(r'\bEnableSmsImport\b')), {
      'lib/core/di/injection.config.dart',
      'lib/features/sms_import/domain/usecases/enable_sms_import.dart',
      'lib/features/sms_import/presentation/cubit/enable_flow_cubit.dart',
    });
  });

  test('the startup path names no permission or enable-flow type', () {
    final forbidden = RegExp(
      r'\b(RequestSmsPermission|EnableSmsImport|EnableFlowCubit|'
      r'SmsPermissionService|EnableBankMessagesPage)\b',
    );
    final startupFiles = [
      File('lib/main.dart'),
      File('lib/features/sms_import/presentation/shared_text_router.dart'),
      File('lib/features/sms_import/presentation/shared_text_inbox.dart'),
      File('lib/core/security/app_lifecycle_observer.dart'),
      ...dartFiles('lib/features/startup'),
    ];
    for (final file in startupFiles) {
      expect(file.existsSync(), isTrue, reason: file.path);
      final hits = codeLines(file).where(forbidden.hasMatch).toList();
      expect(hits, isEmpty, reason: file.path);
    }
  });

  test('the guards catch a call (positive control)', () {
    expect(
      RegExp(
        r'\.request\(\s*previouslyRequested',
      ).hasMatch('_p.request(previouslyRequested: true)'),
      isTrue,
    );
  });

  test('every surface opened at start-up reads without prompting', () async {
    final deps = HubScanDeps(
      capability: true,
      permissions: FakeSmsPermissionService(status: SmsPermissionStatus.denied),
    );
    final repository = FakeSmsImportRepository();
    final home = buildHomeCubit(deps)..open();
    final hub = buildBankMessagesCubit(
      repository,
      FixedClock(DateTime(2026)),
      deps: deps,
    );
    final settings = buildSettingsCubit(deps);
    final enable = buildEnableFlowCubit(deps, repository: repository);

    await hub.open();
    await settings.open();
    await enable.open();
    await enable.onResumed();
    await hub.refreshScanContext();
    await settings.refreshPermission();
    await pumpEventQueue();

    expect(deps.permissions.requests, 0);
    expect(deps.settings.settings.permissionRequested, isFalse);

    await home.close();
    await hub.close();
    await settings.close();
    await enable.close();
    await repository.close();
    await deps.settings.close();
  });
}
