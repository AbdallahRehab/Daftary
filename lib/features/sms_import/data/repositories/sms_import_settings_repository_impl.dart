import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/watch_tables.dart';
import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/merchant_category_mapping.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_import_settings.dart';
import '../../domain/entities/sms_sender_mute.dart';
import '../../domain/repositories/sms_import_settings_repository.dart';
import '../datasources/sms_import_settings_dao.dart';
import '../models/settings_mapper.dart';

/// Settings, mutes, learned mappings and counters (domain-interfaces §3.2).
///
/// - The singleton is not created by a read: an absent row reads as the
///   defaults, and the first write creates it (the `NotificationPreferences`
///   precedent, data-model §4.5 as refined in discovery P2).
/// - [ScanWindow] is checked in code, never in SQL.
/// - The cursor only moves forward, and is advanced by the caller after a
///   page has been committed.
/// - Counters are monotonic: negative deltas are refused.
///
/// Every failure is a fixed, content-free token; an underlying exception is
/// never passed through.
@LazySingleton(as: SmsImportSettingsRepository)
class SmsImportSettingsRepositoryImpl implements SmsImportSettingsRepository {
  SmsImportSettingsRepositoryImpl(this._dao, this._clock);

  final SmsImportSettingsDao _dao;
  final AppClock _clock;

  static const Failure _storeFailure = CacheFailure(
    'sms_settings_store_failed',
  );

  db.AppDatabase get _db => _dao.database;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } catch (_) {
      // Never inspected or kept: SQLite errors embed bound parameters.
      return const Left(_storeFailure);
    }
  }

  Future<Either<Failure, Unit>> _write(db.SmsImportSettingsCompanion changes) =>
      _guard(() async {
        await _dao.updateSettings(changes);
        return unit;
      });

  @override
  Stream<Either<Failure, SmsImportSettings>> watchSettings() =>
      _db.watchEither({_db.smsImportSettings}, getSettings);

  @override
  Future<Either<Failure, SmsImportSettings>> getSettings() => _guard(() async {
    final row = await _dao.getSettings();
    return row?.toDomain() ?? const SmsImportSettings();
  });

  @override
  Future<Either<Failure, Unit>> setEnabled(bool enabled) =>
      _write(db.SmsImportSettingsCompanion(isEnabled: db.Value(enabled)));

  @override
  Future<Either<Failure, Unit>> dismissOnboarding() => _write(
    const db.SmsImportSettingsCompanion(onboardingDismissed: db.Value(true)),
  );

  @override
  Future<Either<Failure, Unit>> setScanWindow(ScanWindow window) {
    // Checked in code (data-model §3.5): only 7, 30 or 90 is ever written.
    final days = ScanWindow.fromDays(window.days).days;
    return _write(
      db.SmsImportSettingsCompanion(scanWindowDays: db.Value(days)),
    );
  }

  @override
  Future<Either<Failure, Unit>> setCountCashWithdrawals(bool value) => _write(
    db.SmsImportSettingsCompanion(countCashWithdrawals: db.Value(value)),
  );

  @override
  Future<Either<Failure, Unit>> markPermissionRequested() => _write(
    const db.SmsImportSettingsCompanion(permissionRequested: db.Value(true)),
  );

  @override
  Future<Either<Failure, Unit>> advanceCursor({
    required DateTime date,
    required int id,
  }) => _guard(() async {
    await _db.transaction(() async {
      final current = await _dao.getSettings();
      final currentDate = current?.cursorDate;
      final currentId = current?.cursorId ?? -1;
      final newDate = date.millisecondsSinceEpoch;
      // Forward only: a late or replayed page never moves it back.
      final forward =
          currentDate == null ||
          newDate > currentDate ||
          (newDate == currentDate && id > currentId);
      if (!forward) return;
      await _dao.updateSettings(
        db.SmsImportSettingsCompanion(
          cursorDate: db.Value(newDate),
          cursorId: db.Value(id),
        ),
      );
    });
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> recordScan({
    required DateTime at,
    required bool catchUp,
  }) {
    final millis = db.Value<int?>(at.millisecondsSinceEpoch);
    return _write(
      catchUp
          ? db.SmsImportSettingsCompanion(lastCatchUpAt: millis)
          : db.SmsImportSettingsCompanion(lastScanAt: millis),
    );
  }

  @override
  Future<Either<Failure, Unit>> addCounts({
    int scanned = 0,
    int recognized = 0,
    int added = 0,
    int ignored = 0,
  }) async {
    if (scanned < 0 || recognized < 0 || added < 0 || ignored < 0) {
      return const Left(ValidationFailure('sms_counts_monotonic'));
    }
    if (scanned == 0 && recognized == 0 && added == 0 && ignored == 0) {
      return const Right(unit);
    }
    return _guard(() async {
      await _dao.addCounts(
        scanned: scanned,
        recognized: recognized,
        added: added,
        ignored: ignored,
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> setRulesSeen(Map<String, int> versions) =>
      _write(
        db.SmsImportSettingsCompanion(
          rulesSeen: db.Value(encodeRulesSeen(versions)),
        ),
      );

  // ------------------------------------------------------------------- mutes

  Future<Either<Failure, Set<String>>> _mutedSenders() => _guard(() async {
    final rows = await _dao.getMutes();
    return {for (final row in rows) row.toDomain().senderId};
  });

  @override
  Stream<Either<Failure, Set<String>>> watchMutedSenders() =>
      _db.watchEither({_db.smsSenderMutes}, _mutedSenders);

  @override
  Future<Either<Failure, int>> muteSender(String senderId) async {
    final canonical = canonicalSmsSenderId(senderId);
    if (canonical.isEmpty) {
      return const Left(ValidationFailure('sms_sender_empty'));
    }
    return _guard(
      () => _db.transaction(() async {
        await _dao.insertMute(canonical, _clock.now().millisecondsSinceEpoch);
        return _dao.deletePendingFromSender(canonical);
      }),
    );
  }

  @override
  Future<Either<Failure, Unit>> unmuteSender(String senderId) =>
      _guard(() async {
        await _dao.deleteMute(canonicalSmsSenderId(senderId));
        return unit;
      });

  // ---------------------------------------------------------------- mappings

  Future<Either<Failure, List<MerchantCategoryMapping>>> _mappings() =>
      _guard(() async {
        final rows = await _dao.getMappings();
        return [for (final row in rows) ?row.toDomain()];
      });

  @override
  Stream<Either<Failure, List<MerchantCategoryMapping>>> watchMappings() =>
      _db.watchEither({_db.smsMerchantCategoryMappings}, _mappings);

  @override
  Future<Either<Failure, Map<(String, String), String>>> getMappingMap() =>
      _guard(() async {
        final rows = await _dao.getMappings();
        return {
          for (final row in rows)
            if (row.entryType == 'expense' || row.entryType == 'income')
              (row.merchantKey, row.entryType): row.categoryId,
        };
      });

  @override
  Future<Either<Failure, Unit>> removeMapping(
    String merchantKey,
    String entryType,
  ) => _guard(() async {
    await _dao.deleteMapping(merchantKey, entryType);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> clearMappings() => _guard(() async {
    await _dao.clearMappings();
    return unit;
  });
}
