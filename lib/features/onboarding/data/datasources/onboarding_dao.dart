import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Direct `drift` access to the single-row `OnboardingStatus` table
/// (data-model.md: the row id is always the fixed constant `'singleton'`),
/// mirroring `lib/features/settings/data/datasources/settings_dao.dart`.
@injectable
class OnboardingDao {
  OnboardingDao(this._db);

  final AppDatabase _db;

  static const _singletonId = 'singleton';

  Future<OnboardingStatusData?> getStatus() => (_db.select(
    _db.onboardingStatus,
  )..where((t) => t.id.equals(_singletonId))).getSingleOrNull();

  Future<void> markComplete(int completedAt) async {
    await _db
        .into(_db.onboardingStatus)
        .insertOnConflictUpdate(
          OnboardingStatusCompanion.insert(
            id: _singletonId,
            isComplete: const Value(true),
            completedAt: Value(completedAt),
          ),
        );
  }
}
