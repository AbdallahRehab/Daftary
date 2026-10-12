import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../money/currency.dart';

/// A dropdown field for choosing a [Currency] from [currencies] (the bundled
/// catalog). Built directly in `core/design_system` — plan.md Complexity
/// Tracking — since every amount-entry form needs it at once. The caller
/// supplies [value], normally the current primary currency (FR-003).
///
/// 023: [CurrencyPicker.optional] allows no selection yet (a bank message
/// that states no currency, FR-053); the field then shows [hint] and the
/// caller's [errorText] until the user chooses.
class CurrencyPicker extends StatelessWidget {
  const CurrencyPicker({
    required Currency value,
    required this.onChanged,
    this.currencies = Currency.catalog,
    this.enabled = true,
    this.label,
    this.hint,
    this.errorText,
    super.key,
  }) : selected = value;

  /// 023: like the default constructor, but [selected] may be `null`.
  const CurrencyPicker.optional({
    required this.selected,
    required this.onChanged,
    this.currencies = Currency.catalog,
    this.enabled = true,
    this.label,
    this.hint,
    this.errorText,
    super.key,
  });

  static const Key fieldKey = Key('currency_picker');

  /// The selected currency; `null` only through [CurrencyPicker.optional].
  final Currency? selected;

  /// The selected currency of a picker built with the default constructor.
  Currency get value => selected!;
  final ValueChanged<Currency> onChanged;
  final List<Currency> currencies;
  final bool enabled;

  /// Overrides the default "Currency" label.
  final String? label;

  /// Shown while [value] is `null`.
  final String? hint;

  /// Shown under the field (for example a required-field message).
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final current = selected;
    final options = current == null || currencies.contains(current)
        ? currencies
        : [current, ...currencies];
    return DropdownButtonFormField<Currency>(
      key: fieldKey,
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label ?? l10n.currencyFieldLabel,
        hintText: hint,
        errorText: errorText,
      ),
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
