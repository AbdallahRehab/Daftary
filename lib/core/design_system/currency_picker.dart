import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../money/currency.dart';

/// A dropdown field for choosing a [Currency] from [currencies] (the bundled
/// catalog). Built directly in `core/design_system` — plan.md Complexity
/// Tracking — since every amount-entry form needs it at once. The caller
/// supplies [value], normally the current primary currency (FR-003).
class CurrencyPicker extends StatelessWidget {
  const CurrencyPicker({
    required this.value,
    required this.onChanged,
    this.currencies = Currency.catalog,
    this.enabled = true,
    this.label,
    super.key,
  });

  static const Key fieldKey = Key('currency_picker');

  final Currency value;
  final ValueChanged<Currency> onChanged;
  final List<Currency> currencies;
  final bool enabled;

  /// Overrides the default "Currency" label.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final options = currencies.contains(value)
        ? currencies
        : [value, ...currencies];
    return DropdownButtonFormField<Currency>(
      key: fieldKey,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label ?? l10n.currencyFieldLabel),
      items: [
        for (final currency in options)
          DropdownMenuItem(
            value: currency,
            child: Text(
              '${currency.displayName(languageCode)} (${currency.code})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: enabled
          ? (currency) {
              if (currency != null) onChanged(currency);
            }
          : null,
    );
  }
}
