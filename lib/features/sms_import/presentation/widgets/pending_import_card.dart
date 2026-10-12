import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/confidence_indicator.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/parse_confidence.dart';
import '../../domain/entities/pending_sms_import.dart';
import '../../domain/entities/sms_import_enums.dart';
import 'sms_import_labels.dart';

/// One pending item in the list (ui-contract §3.3): type chip, amount (or
/// "Amount needs checking"), date with an inferred marker, merchant or
/// counterparty, masked card, overall confidence, bank and warning chips.
/// Never the message text.
///
/// The whole card is one screen-reader node with a sentence-like label;
/// meaning never relies on colour (icons plus text).
///
/// In selection mode (T132) a leading checkbox shows the selection, a tap
/// toggles it, and the node exposes `selected`/`checked` (ui-contract
/// §7.9). A long-press outside selection mode starts it.
class PendingImportCard extends StatelessWidget {
  PendingImportCard({
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
    this.enabled = true,
  }) : super(key: ValueKey('pending_import_card_${item.id}'));

  final PendingSmsImport item;

  /// Opens the review, or toggles the selection in selection mode.
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;

  /// False while a batch Ignore runs.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final type = item.suggestedType;
    final typeText = type.isSavable || type == SuggestedRecordType.ignore
        ? SmsImportLabels.type(l10n, type)
        : l10n.smsImportPendingChooseType;
    final amount = item.amount;
    final amountText = amount == null
        ? l10n.smsImportPendingAmountNeedsCheck
        : SmsImportLabels.money(context, amount);
    final occurredOn = item.occurredOn;
    final dateText = occurredOn == null
        ? null
        : (item.confidence.isInferred(SmsField.date)
              ? l10n.smsImportPendingDateInferred(
                  SmsImportLabels.date(context, occurredOn),
                )
              : SmsImportLabels.date(context, occurredOn));
    final name = item.merchant ?? item.counterparty;
    final bank = SmsImportLabels.bank(l10n, item.bankId);
    final last4 = item.cardLast4;
    final ignoreSuggested = type == SuggestedRecordType.ignore;
    final possibleDuplicate = item.warnings.contains(
      SmsWarning.possibleDuplicate,
    );

    final semantics = [
      typeText,
      amountText,
      ?dateText,
      ?name,
      if (last4 != null) l10n.smsImportSemanticsCardEnding(last4),
      SmsImportLabels.confidenceText(l10n, item.confidence.overall),
      bank,
      if (possibleDuplicate) l10n.smsImportPendingPossibleDuplicate,
    ].join(l10n.smsImportReviewListSeparator);

    final details = _details(
      context,
      typeText: typeText,
      ignoreSuggested: ignoreSuggested,
      possibleDuplicate: possibleDuplicate,
      amountText: amountText,
      name: name,
      dateText: dateText,
      last4: last4,
      bank: bank,
      muted: muted,
    );
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selectionMode ? selected : null,
      checked: selectionMode ? selected : null,
      label: semantics,
      hint: selectionMode ? null : l10n.smsImportSemanticsOpenReview,
      excludeSemantics: true,
      onLongPress: enabled ? onLongPress : null,
      child: GestureDetector(
        onLongPress: enabled ? onLongPress : null,
        child: AppCard(
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: selectionMode
                ? Row(
                    children: [
                      Checkbox(
                        key: ValueKey('pending_import_check_${item.id}'),
                        value: selected,
                        onChanged: enabled ? (_) => onTap() : null,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: details),
                    ],
                  )
                : details,
          ),
        ),
      ),
    );
  }

  Widget _details(
    BuildContext context, {
    required String typeText,
    required bool ignoreSuggested,
    required bool possibleDuplicate,
    required String amountText,
    required String? name,
    required String? dateText,
    required String? last4,
    required String bank,
    required Color muted,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final amount = item.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Chip(
              icon: ignoreSuggested
                  ? Icons.visibility_off_outlined
                  : Icons.label_outline,
              text: typeText,
            ),
            ConfidenceIndicator(
              confidence: SmsImportLabels.overall(item.confidence.overall),
            ),
            if (possibleDuplicate)
              _Chip(
                icon: Icons.content_copy_outlined,
                text: l10n.smsImportPendingPossibleDuplicate,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          amountText,
          style: amount == null
              ? AppTypography.body.copyWith(color: muted)
              : AppTypography.figure,
        ),
        if (name != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body,
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            ?(dateText == null
                ? null
                : Text(dateText, style: AppTypography.bodyMuted)),
            if (last4 != null)
              Text(
                SmsImportLabels.maskedCard(last4),
                style: AppTypography.bodyMuted,
              ),
            Text(bank, style: AppTypography.bodyMuted),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm,
        2,
        AppSpacing.sm,
        2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: AppTypography.label.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
