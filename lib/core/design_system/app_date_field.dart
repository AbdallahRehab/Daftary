import 'package:flutter/material.dart';

import '../date/app_date_formatter.dart';
import 'tokens.dart';

/// The app's single date-picker field style: a read-only, tappable
/// `InputDecorator` that opens the platform date picker. Shared by every
/// form that captures a transaction date (previously duplicated verbatim
/// per form).
///
/// 023: [date] may be `null` when no date is known yet (a pasted bank
/// message that states none); the field then shows [emptyText] and the
/// caller's [errorText], and the picker opens on today.
class AppDateField extends StatelessWidget {
  const AppDateField({
    required this.label,
    required this.date,
    required this.onDateChanged,
    super.key,
    this.firstDate,
    this.lastDate,
    this.emptyText,
    this.errorText,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Shown while [date] is `null`.
  final String? emptyText;

  /// Shown under the field (for example a required-field message).
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () async {
        final first = firstDate ?? DateTime(2000);
        final last = lastDate ?? DateTime.now().add(const Duration(days: 1));
        final now = DateTime.now();
        final initial =
            date ??
            (now.isAfter(last) ? last : (now.isBefore(first) ? first : now));
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: first,
          lastDate: last,
        );
        if (picked != null) onDateChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Text(switch (date) {
          final DateTime value => AppDateFormatter(
            locale: Localizations.localeOf(context).languageCode,
          ).format(value),
          null => emptyText ?? '',
        }),
      ),
    );
  }
}
