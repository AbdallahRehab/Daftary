import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/notification_preference.dart';

/// Domain/Data boundary for the single [NotificationPreference] record.
abstract class NotificationPreferenceRepository {
  /// The stored preference, or [NotificationPreference.defaults] when none
  /// has ever been saved (feature off, both categories on, no quiet hours,
  /// no permission).
  Future<Either<Failure, NotificationPreference>> getPreference();

  /// Replaces the stored preference with [preference] and returns it as
  /// persisted.
  Future<Either<Failure, NotificationPreference>> savePreference(
    NotificationPreference preference,
  );
}
