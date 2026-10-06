import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/sync/local/sync_outbox.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:daftary/core/sync/sync_mapper_registry.dart';
import 'package:daftary/features/people/data/sync/person_sync_mapper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// 021 T023: the real DI graph resolves a mapper for every entity type.
void main() {
  group('through getIt', () {
    setUp(configureDependencies);
    tearDown(() => getIt.reset());

    test('resolves a mapper for all 8 entity types', () {
      final registry = getIt<SyncMapperRegistry>();
      expect(registry.types, SyncEntityType.values.toSet());
      for (final type in SyncEntityType.values) {
        expect(registry.mapperFor(type).type, type, reason: type.wire);
      }
    });

    test('hands out typed mappers', () {
      final registry = getIt<SyncMapperRegistry>();
      expect(
        registry.of<PeopleData>(SyncEntityType.person),
        isA<PersonSyncMapper>(),
      );
      expect(
        () => registry.of<FinanceEntry>(SyncEntityType.person),
        throwsStateError,
      );
    });

    test('resolves the other 021 foundation singletons', () {
      expect(getIt<SyncOutbox>(), isA<DriftSyncOutbox>());
      expect(getIt<SyncLogger>(), isA<DeveloperSyncLogger>());
      expect(getIt<Connectivity>(), isA<Connectivity>());
      expect(getIt<FlutterSecureStorage>(), isA<FlutterSecureStorage>());
      expect(
        identical(getIt<SyncMapperRegistry>(), getIt<SyncMapperRegistry>()),
        isTrue,
      );
    });
  });

  group('SyncMapperRegistry', () {
    test('throws for an unregistered type', () {
      final registry = SyncMapperRegistry([const PersonSyncMapper()]);
      expect(
        () => registry.mapperFor(SyncEntityType.financeEntry),
        throwsStateError,
      );
    });

    test('rejects two mappers for one type', () {
      expect(
        () => SyncMapperRegistry([
          const PersonSyncMapper(),
          const PersonSyncMapper(),
        ]),
        throwsArgumentError,
      );
    });
  });

  group('SyncWire.parseLocalDay (B1)', () {
    test('turns occurred_on into local midnight of that calendar day', () {
      expect(
        SyncWire.parseLocalDay({'occurred_on': '2026-10-01'}),
        DateTime(2026, 10, 1).millisecondsSinceEpoch,
      );
    });

    test('ignores occurred_at and the offset when occurred_on is present', () {
      expect(
        SyncWire.parseLocalDay({
          'occurred_on': '2026-10-01',
          'occurred_at': '2026-09-30T21:00:00Z',
          'tz_offset_minutes': 180,
        }),
        DateTime(2026, 10, 1).millisecondsSinceEpoch,
      );
    });

    test('falls back to occurred_at when occurred_on is missing', () {
      expect(
        SyncWire.parseLocalDay({'occurred_at': '2026-09-30T21:00:00Z'}),
        DateTime.utc(2026, 9, 30, 21).millisecondsSinceEpoch,
      );
    });

    test('a malformed day is a FormatException', () {
      for (final bad in <Object?>[
        '2026-13-01',
        '2026-10',
        'x',
        5,
        '2026-02-30',
      ]) {
        expect(
          () => SyncWire.parseLocalDay({
            'occurred_on': bad,
            'occurred_at': '2026-09-30T21:00:00Z',
          }),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });

    test('honours custom field names', () {
      expect(
        SyncWire.parseLocalDay(
          {'d': '2026-10-01'},
          dayField: 'd',
          instantField: 'i',
        ),
        DateTime(2026, 10, 1).millisecondsSinceEpoch,
      );
    });
  });
}
