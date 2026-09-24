import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/notification_history_entry.dart';
import '../../domain/entities/notification_source_type.dart';
import '../../domain/repositories/notification_history_repository.dart';
import '../datasources/notifications_dao.dart';
import '../models/notification_mappers.dart';

@LazySingleton(as: NotificationHistoryRepository)
class NotificationHistoryRepositoryImpl
    implements NotificationHistoryRepository {
  NotificationHistoryRepositoryImpl(this._dao);

  final NotificationsDao _dao;

  @override
  Future<Either<Failure, NotificationHistoryEntry?>> find(
    NotificationSourceType sourceType,
    String sourceId,
    String? applicablePeriod,
  ) async {
    try {
      final row = await _dao.findHistory(
        sourceType: sourceType.name,
        sourceId: sourceId,
        applicablePeriod: applicablePeriod,
      );
      return Right(row?.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to load notification history: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationHistoryEntry>> upsert(
    NotificationHistoryEntry entry,
  ) async {
    try {
      final row = await _dao.upsertHistoryOnBandChange(entry.toRow());
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to save notification history: $e'));
    }
  }
}
