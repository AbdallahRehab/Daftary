import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/repositories/notification_preference_repository.dart';
import '../datasources/notifications_dao.dart';
import '../models/notification_mappers.dart';

@LazySingleton(as: NotificationPreferenceRepository)
class NotificationPreferenceRepositoryImpl
    implements NotificationPreferenceRepository {
  NotificationPreferenceRepositoryImpl(this._dao);

  final NotificationsDao _dao;

  @override
  Future<Either<Failure, NotificationPreference>> getPreference() async {
    try {
      final row = await _dao.getPreference();
      return Right(row?.toDomain() ?? NotificationPreference.defaults);
    } catch (e) {
      return Left(CacheFailure('Failed to load notification preference: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationPreference>> savePreference(
    NotificationPreference preference,
  ) async {
    try {
      final row = await _dao.upsertPreference(
        preference.toCompanion(NotificationsDao.preferenceRowId),
      );
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to save notification preference: $e'));
    }
  }
}
