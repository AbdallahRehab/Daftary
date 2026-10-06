import 'package:daftary/core/sync/sync_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<({String message, int level, String name})> lines;

  DeveloperSyncLogger logger({required bool releaseMode}) =>
      DeveloperSyncLogger.withSink((
        String message, {
        int level = 800,
        String name = '',
      }) {
        lines.add((message: message, level: level, name: name));
      }, releaseMode: releaseMode);

  setUp(() => lines = []);

  test('event names map to the logged names', () {
    expect(
      [for (final e in SyncEvent.values) e.logName],
      [
        'SYNC_STARTED',
        'SYNC_UPLOAD_STARTED',
        'SYNC_UPLOAD_SUCCESS',
        'SYNC_UPLOAD_FAILED',
        'SYNC_DOWNLOAD_STARTED',
        'SYNC_DOWNLOAD_SUCCESS',
        'SYNC_CONFLICT',
        'SYNC_RETRY',
        'SYNC_COMPLETED',
        'SYNC_ABORTED',
        'SYNC_MIGRATION_ENQUEUED',
        'SYNC_CURSOR_ADVANCED',
        'SYNC_UNKNOWN_ENTITY_SKIPPED',
      ],
    );
  });

  test('the allowed field keys are exactly the allow-list', () {
    // The API is typed `Map<SyncLogField, Object>`, so a free-form key such
    // as 'name' or 'amount' does not compile. This pins the allow-list.
    expect(
      [for (final f in SyncLogField.values) f.name],
      [
        'entityType',
        'count',
        'durationMs',
        'errorCode',
        'delayMs',
        'revision',
        'opId',
      ],
    );
  });

  test('formats the event name then key=value pairs in enum order', () {
    logger(releaseMode: false).event(
      SyncEvent.uploadSuccess,
      fields: {
        SyncLogField.durationMs: 120,
        SyncLogField.entityType: 'person',
        SyncLogField.count: 3,
      },
    );
    expect(
      lines.single.message,
      'SYNC_UPLOAD_SUCCESS entityType=person count=3 durationMs=120',
    );
    expect(lines.single.name, 'daftary.sync');
    expect(lines.single.level, 800);
  });

  test('an event with no fields logs just its name', () {
    logger(releaseMode: false).event(SyncEvent.syncStarted);
    expect(lines.single.message, 'SYNC_STARTED');
  });

  test('debug builds log every event', () {
    final l = logger(releaseMode: false);
    for (final e in SyncEvent.values) {
      l.event(e);
    }
    expect(lines, hasLength(SyncEvent.values.length));
  });

  test('release builds log only upload failures, aborts and conflicts', () {
    final l = logger(releaseMode: true);
    for (final e in SyncEvent.values) {
      l.event(e, fields: {SyncLogField.errorCode: 'network'});
    }
    expect(
      [for (final line in lines) line.message.split(' ').first],
      ['SYNC_UPLOAD_FAILED', 'SYNC_CONFLICT', 'SYNC_ABORTED'],
    );
    expect(lines.first.level, 1000);
    expect(lines[1].level, 900);
  });
}
