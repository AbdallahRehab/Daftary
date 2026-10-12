import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/merchant_category_mapping.dart';
import '../entities/sms_import_enums.dart';
import '../entities/sms_import_settings.dart';

/// Settings, mutes, learned mappings and counters (domain-interfaces §3.2).
abstract class SmsImportSettingsRepository {
  Stream<Either<Failure, SmsImportSettings>> watchSettings();

  /// Creates the singleton lazily.
  Future<Either<Failure, SmsImportSettings>> getSettings();

  Future<Either<Failure, Unit>> setEnabled(bool enabled);

  Future<Either<Failure, Unit>> dismissOnboarding();

  Future<Either<Failure, Unit>> setScanWindow(ScanWindow window);

  Future<Either<Failure, Unit>> setCountCashWithdrawals(bool value);

  Future<Either<Failure, Unit>> markPermissionRequested();

  Future<Either<Failure, Unit>> advanceCursor({
    required DateTime date,
    required int id,
  });

  Future<Either<Failure, Unit>> recordScan({
    required DateTime at,
    required bool catchUp,
  });

  Future<Either<Failure, Unit>> addCounts({
    int scanned = 0,
    int recognized = 0,
    int added = 0,
    int ignored = 0,
  });

  Future<Either<Failure, Unit>> setRulesSeen(Map<String, int> versions);

  Stream<Either<Failure, Set<String>>> watchMutedSenders();

  /// One transaction: inserts the mute (canonical upper-case) and deletes
  /// that sender's pending rows (no tombstones, as in FR-078). Returns the
  /// deleted count.
  Future<Either<Failure, int>> muteSender(String senderId);

  Future<Either<Failure, Unit>> unmuteSender(String senderId);

  Stream<Either<Failure, List<MerchantCategoryMapping>>> watchMappings();

  /// `(merchantKey, entryType)` -> category id.
  Future<Either<Failure, Map<(String, String), String>>> getMappingMap();

  Future<Either<Failure, Unit>> removeMapping(
    String merchantKey,
    String entryType,
  );

  /// "Clear learned categories" (FR-056).
  Future<Either<Failure, Unit>> clearMappings();
}
