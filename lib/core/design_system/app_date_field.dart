import 'package:flutter/material.dart';

import '../date/app_date_formatter.dart';
import 'tokens.dart';

/// The app's single date-picker field style: a read-only, tappable
/// `InputDecorator` that opens the platform date picker. Shared by every
/// form that captures a transaction date (previously duplicated verbatim
/// per form).
class AppDateField extends StatelessWidget {
  const AppDateField({
    required this.label,
    required this.date,
    required this.onDateChanged,
    super.key,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate ?? DateTime(2000),
          lastDate: lastDate ?? DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) onDateChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Text(
          AppDateFormatter(
            locale: Localizations.localeOf(context).languageCode,
          ).format(date),
        ),
      ),
    );
  }
}
