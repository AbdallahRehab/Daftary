import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/sms_import_enums.dart';
import 'sms_import_labels.dart';

/// The review's record type: Expense, Income, Given or Received only
/// (FR-048). Repayment and occasion contribution are never offered.
///
/// Chips wrap at large text sizes, each has a 48 dp target, and the
/// selected one is announced as selected. `null` shows none selected with
/// "Choose a type" (FR-033).
class ImportTypeSelector extends StatelessWidget {
  const ImportTypeSelector({
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
  });

  /// The four types offered.
  static const List<SuggestedRecordType> offered = [
    SuggestedRecordType.expense,
    SuggestedRecordType.income,
    SuggestedRecordType.given,
    SuggestedRecordType.received,
  ];

  final SuggestedRecordType? value;
  final ValueChanged<SuggestedRecordType> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.smsImportReviewTypeLabel,
          style: AppTypography.label.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final type in offered)
              ChoiceChip(
                key: ValueKey('import_type_${type.name}'),
                label: Text(SmsImportLabels.type(l10n, type)),
                selected: value == type,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: enabled ? (_) => onChanged(type) : null,
              ),
          ],
        ),
        if (value == null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
            child: Text(
              l10n.smsImportReviewChooseType,
              style: AppTypography.label.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
