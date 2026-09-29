import '../../../../core/database/app_database.dart' as db;
import '../../../../core/money/currency.dart';
import '../../domain/entities/savings_goal.dart' as domain;

/// Maps `savings_goals` rows to the domain [domain.SavingsGoal]. Timestamps
/// and the date-only target date are stored as epoch millis, so this is the
/// single place that conversion happens.
extension SavingsGoalMapper on db.SavingsGoal {
  domain.SavingsGoal toDomain() => domain.SavingsGoal(
    id: id,
    idempotencyKey: idempotencyKey,
    name: name,
    type: type,
    currency: Currency.fromCode(currencyCode),
    targetAmountMinorUnits: targetAmountMinorUnits,
    monthlyContributionMinorUnits: monthlyContributionMinorUnits,
    targetDate: _dateOrNull(targetDate),
    isArchived: isArchived,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    deletedAt: _dateOrNull(deletedAt),
  );
}

DateTime? _dateOrNull(int? millis) =>
    millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
