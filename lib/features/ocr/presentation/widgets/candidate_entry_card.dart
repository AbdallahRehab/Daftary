import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../people/domain/entities/person.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/presentation/widgets/duplicate_warning_sheet.dart';
import '../../../transactions/presentation/widgets/person_picker_field.dart';
import '../../domain/entities/candidate_entry.dart';
import '../../domain/entities/field_confidence.dart';
import 'confidence_indicator.dart';

/// One proposed entry, laid out so it can be checked against the page and
/// corrected before it is allowed to become money (FR-008, FR-013).
///
/// The card never decides anything: eligibility comes from
/// [CandidateEntry.isConfirmEligible] and every edit is handed straight
/// back to the cubit. Its only judgement is presentational — which field to
/// draw attention to, and why this row cannot be confirmed yet.
class CandidateEntryCard extends StatefulWidget {
  const CandidateEntryCard({
    required this.entry,
    required this.batchDefaultDirection,
    required this.scanDate,
    required this.duplicateMatches,
    required this.amountInvalid,
    required this.onPersonNameChanged,
    required this.onPersonSelected,
    required this.onDuplicatesDismissed,
    required this.onAmountChanged,
    required this.onDirectionChanged,
    required this.onDateChanged,
    required this.onNotesChanged,
    required this.onDiscard,
    super.key,
    this.highlightIncomplete = false,
  });

  final CandidateEntry entry;

  /// The batch fallback this entry's direction resolves against (FR-005).
  final TransactionDirection? batchDefaultDirection;

  /// The scan's own date, which an entry without a read date falls back to.
  final DateTime scanDate;

  /// Existing people whose names look like this entry's (FR-009).
  final List<Person> duplicateMatches;

  /// Whether the amount field currently holds unparseable text.
  final bool amountInvalid;

  /// Set after a confirm attempt was refused, to mark the rows that caused
  /// it (FR-011).
  final bool highlightIncomplete;

  final ValueChanged<String> onPersonNameChanged;
  final ValueChanged<Person> onPersonSelected;
  final VoidCallback onDuplicatesDismissed;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<TransactionDirection> onDirectionChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onDiscard;

  @override
  State<CandidateEntryCard> createState() => _CandidateEntryCardState();
}

class _CandidateEntryCardState extends State<CandidateEntryCard> {
  late final TextEditingController _amountController = TextEditingController(
    text: _formattedAmount(widget.entry),
  );
  late final TextEditingController _notesController = TextEditingController(
    text: widget.entry.notes ?? '',
  );

  /// The raw recognized line starts collapsed so a clean batch reads
  /// calmly, but is always one tap away — checking a suspicious row against
  /// what was actually on the paper is the whole point of review.
  bool _showRawText = false;

  static String _formattedAmount(CandidateEntry entry) {
    final minorUnits = entry.amountMinorUnits;
    if (minorUnits == null) return '';
    return EgpFormatter().format(Money.fromMinorUnits(minorUnits));
  }

  @override
  void didUpdateWidget(covariant CandidateEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reconcile only when the value changed for a reason other than this
    // field's own typing, or every keystroke would jump the caret.
    final amount = _formattedAmount(widget.entry);
    if (widget.entry.amountMinorUnits != oldWidget.entry.amountMinorUnits &&
        amount != _amountController.text) {
      _amountController.value = TextEditingValue(
        text: amount,
        selection: TextSelection.collapsed(offset: amount.length),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final entry = widget.entry;
    final isEligible = entry.isConfirmEligible(widget.batchDefaultDirection);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            isEdited: entry.isEdited,
            showRawText: _showRawText,
            onToggleRawText: () => setState(() => _showRawText = !_showRawText),
            onDiscard: widget.onDiscard,
          ),
          if (_showRawText) ...[
            const SizedBox(height: AppSpacing.sm),
            _RawOcrText(text: entry.rawOcrText),
          ],
          const SizedBox(height: AppSpacing.md),
          _FieldLabel(
            label: l10n.ocrReviewPersonLabel,
            confidence: entry.personNameConfidence,
          ),
          PersonPickerField(
            query: entry.personName,
            // The duplicate matches double as the picker's suggestions:
            // one list, one matching rule, whether the name was typed or
            // read off a page (FR-009).
            results: widget.duplicateMatches,
            selectedPerson: null,
            onQueryChanged: widget.onPersonNameChanged,
            onPersonSelected: widget.onPersonSelected,
            onCreateNew: (_) => widget.onDuplicatesDismissed(),
            errorText: entry.personName.trim().isEmpty
                ? l10n.ocrReviewPersonRequired
                : null,
          ),
          if (widget.duplicateMatches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.people_outline, size: 16),
                label: Text(l10n.ocrReviewDuplicateWarningAction),
                onPressed: () => showDuplicateWarningSheet(
                  context,
                  matches: widget.duplicateMatches,
                  onPickExisting: widget.onPersonSelected,
                  onCreateNewAnyway: widget.onDuplicatesDismissed,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _FieldLabel(
            label: l10n.ocrReviewAmountLabel,
            confidence: entry.amountConfidence,
          ),
          AppTextField(
            label: l10n.ocrReviewAmountLabel,
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Amounts stay left-to-right in both locales, the same way the
            // manual transaction form treats them.
            textDirection: TextDirection.ltr,
            errorText: widget.amountInvalid
                ? l10n.ocrReviewAmountInvalid
                : (entry.amountMinorUnits == null
                      ? l10n.ocrReviewAmountRequired
                      : null),
            onChanged: widget.onAmountChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel(
            label: l10n.ocrReviewDirectionLabel,
            confidence: entry.directionConfidence,
          ),
          _DirectionSelector(
            direction: entry.effectiveDirection(widget.batchDefaultDirection),
            onChanged: widget.onDirectionChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          _FieldLabel(
            label: l10n.ocrReviewDateLabel,
            confidence: entry.dateConfidence,
          ),
          AppDateField(
            label: l10n.ocrReviewDateLabel,
            date: entry.effectiveDate(widget.scanDate),
            onDateChanged: widget.onDateChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: l10n.ocrReviewNotesLabel,
            controller: _notesController,
            maxLines: 2,
            onChanged: widget.onNotesChanged,
          ),
          if (!isEligible) ...[
            const SizedBox(height: AppSpacing.md),
            _IncompleteNotice(
              reasons: _incompleteReasons(l10n),
              emphasized: widget.highlightIncomplete,
              color: widget.highlightIncomplete
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }

  /// Explains an ineligibility that [CandidateEntry.isConfirmEligible]
  /// already decided — it does not re-decide it. The card only reaches here
  /// when that method has already said "no"; these checks name which of its
  /// clauses was the reason.
  List<String> _incompleteReasons(AppLocalizations l10n) {
    final entry = widget.entry;
    final amount = entry.amountMinorUnits;
    return [
      if (entry.personName.trim().isEmpty) l10n.ocrReviewPersonRequired,
      if (amount == null || amount <= 0) l10n.ocrReviewAmountRequired,
      if (entry.effectiveDirection(widget.batchDefaultDirection) == null)
        l10n.ocrReviewDirectionRequired,
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isEdited,
    required this.showRawText,
    required this.onToggleRawText,
    required this.onDiscard,
  });

  final bool isEdited;
  final bool showRawText;
  final VoidCallback onToggleRawText;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (isEdited)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: Icon(
              Icons.edit_outlined,
              size: 16,
              color: colorScheme.primary,
              semanticLabel: l10n.ocrReviewEditedBadge,
            ),
          ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              icon: Icon(
                showRawText ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(l10n.ocrReviewRawTextAction),
              onPressed: onToggleRawText,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: colorScheme.error,
          tooltip: l10n.ocrReviewDiscardAction,
          onPressed: onDiscard,
        ),
      ],
    );
  }
}

class _RawOcrText extends StatelessWidget {
  const _RawOcrText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ocrReviewRawTextLabel,
            style: AppTypography.label.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(text, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.confidence});

  final String label;
  final FieldConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ConfidenceIndicator(confidence: confidence),
        ],
      ),
    );
  }
}

class _DirectionSelector extends StatelessWidget {
  const _DirectionSelector({required this.direction, required this.onChanged});

  final TransactionDirection? direction;
  final ValueChanged<TransactionDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<TransactionDirection>(
      segments: [
        ButtonSegment(
          value: TransactionDirection.received,
          label: Text(l10n.ocrReviewDirectionReceived),
          icon: const Icon(Icons.south_west, size: 16),
        ),
        ButtonSegment(
          value: TransactionDirection.given,
          label: Text(l10n.ocrReviewDirectionGiven),
          icon: const Icon(Icons.north_east, size: 16),
        ),
      ],
      // An empty selection is a real state here: neither the page nor the
      // batch default has supplied a direction yet, and showing one anyway
      // would be inventing an answer (FR-005).
      selected: direction == null ? const {} : {direction!},
      emptySelectionAllowed: true,
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        onChanged(selection.first);
      },
    );
  }
}

class _IncompleteNotice extends StatelessWidget {
  const _IncompleteNotice({
    required this.reasons,
    required this.emphasized,
    required this.color,
  });

  final List<String> reasons;
  final bool emphasized;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            emphasized ? Icons.error_outline : Icons.info_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ocrReviewIncompleteTitle,
                  style: AppTypography.label.copyWith(color: color),
                ),
                for (final reason in reasons)
                  Text(
                    reason,
                    style: AppTypography.bodyMuted.copyWith(color: color),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
