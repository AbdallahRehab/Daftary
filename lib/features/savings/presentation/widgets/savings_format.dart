import 'package:flutter/material.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/savings_goal_type.dart';

/// Locale-aware formatting shared by every savings screen — one place, so a
/// figure reads the same on the form preview, the progress card and the
/// history list.
class SavingsFormat {
  SavingsFormat.of(BuildContext context)
    : l10n = AppLocalizations.of(context)!,
      _locale = Localizations.localeOf(context).languageCode;

  final AppLocalizations l10n;
  final String _locale;

  /// `150.50 EGP` — always Western digits, the code as suffix (018).
  String money(Money amount) => CurrencyFormatter(
    currency: amount.currency,
    locale: _locale,
  ).formatWithSymbol(amount);

  String date(DateTime date) => AppDateFormatter(locale: _locale).format(date);

  /// A month count as people say it: "20 months", or "2 years and 3
  /// months" from two years on (spec Edge Cases: a very long timeline reads
  /// in years, not an absurd number of months).
  String duration(int months) {
    if (months < 24) return l10n.savingsDurationMonths(months);
    final years = l10n.savingsDurationYears(months ~/ 12);
    final rest = months % 12;
    if (rest == 0) return years;
    return l10n.savingsDurationYearsAndMonths(
      years,
      l10n.savingsDurationMonths(rest),
    );
  }

  /// `0..100`, floored so a goal never reads "100%" before it is achieved.
  String percent(double value) => value.floor().toString();
}

/// The localized label of a standard goal type; a custom (non-standard)
/// value is shown as typed, and no type at all as "No type".
String savingsGoalTypeLabel(AppLocalizations l10n, String? type) =>
    switch (type) {
      null => l10n.savingsGoalTypeNone,
      SavingsGoalType.emergencyFund => l10n.savingsGoalTypeEmergencyFund,
      SavingsGoalType.newCar => l10n.savingsGoalTypeNewCar,
      SavingsGoalType.wedding => l10n.savingsGoalTypeWedding,
      SavingsGoalType.vacation => l10n.savingsGoalTypeVacation,
      SavingsGoalType.newPhone => l10n.savingsGoalTypeNewPhone,
      SavingsGoalType.homeFurniture => l10n.savingsGoalTypeHomeFurniture,
      SavingsGoalType.education => l10n.savingsGoalTypeEducation,
      SavingsGoalType.other => l10n.savingsGoalTypeOther,
      _ => type,
    };

/// The representative icon of a goal type — cosmetic only (FR-001).
IconData savingsGoalTypeIcon(String? type) => switch (type) {
  SavingsGoalType.emergencyFund => Icons.health_and_safety_outlined,
  SavingsGoalType.newCar => Icons.directions_car_outlined,
  SavingsGoalType.wedding => Icons.favorite_outline,
  SavingsGoalType.vacation => Icons.beach_access_outlined,
  SavingsGoalType.newPhone => Icons.smartphone_outlined,
  SavingsGoalType.homeFurniture => Icons.chair_outlined,
  SavingsGoalType.education => Icons.school_outlined,
  _ => Icons.savings_outlined,
};
