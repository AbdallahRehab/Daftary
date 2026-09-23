import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T050 (export part) / FR-012, FR-022 — the export flow never reaches the
/// network: no file in `data_privacy` imports an HTTP/socket client or uses
/// `dart:io`'s network classes. The only way data leaves the device is the
/// user handing the file to the OS share sheet, which is outside the app.
void main() {
  const featureDir = 'lib/features/data_privacy';

  final networkImport = RegExp(
    r'''import\s+['"](package:(http|dio|web_socket_channel|grpc|'''
    r'''firebase_[a-z_]+|cloud_[a-z_]+|supabase[a-z_]*)/|dart:html)''',
  );
  final networkApi = RegExp(
    r'\b(HttpClient|HttpRequest|RawSocket|Socket|SecureSocket|WebSocket|'
    r'ServerSocket|RawDatagramSocket|NetworkInterface|InternetAddress)\b',
  );

  List<File> dartFiles() => Directory(featureDir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('the export files under test actually exist', () {
    final paths = dartFiles().map((f) => f.path).toList();
    for (final expected in [
      'domain/usecases/export_user_data.dart',
      'data/services/share_plus_service.dart',
      'presentation/cubit/export_cubit.dart',
      'presentation/pages/data_export_page.dart',
    ]) {
      expect(paths, contains(endsWith(expected)));
    }
  });

  test('no data_privacy file imports or uses a network client', () {
    final offenders = <String>[
      for (final file in dartFiles())
        for (final (i, line) in file.readAsLinesSync().indexed)
          if (!line.trimLeft().startsWith('//') &&
              (networkImport.hasMatch(line) || networkApi.hasMatch(line)))
            '${file.path}:${i + 1}: ${line.trim()}',
    ];

    expect(offenders, isEmpty);
  });
}
