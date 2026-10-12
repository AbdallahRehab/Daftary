import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/imported_from_sms_label.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/money.dart';
import '../../domain/rules/calendar_days.dart';
import 'sms_import_labels.dart';

/// One side of the probable-duplicate comparison (ui-contract §3.6): what
/// is already in Daftary (or another pending bank message), or the bank
/// message under review with the draft's current values. Display values
/// only; never the message text.
class DuplicateSide extends Equatable {
  const DuplicateSide({
    required this.title,
    this.typeLabel,
    this.amount,
    this.date,
    this.note,
    this.sourceLabel,
    this.importedFromSms = false,
  });

  /// "Already in Daftary", "Another bank message" or "This message".
  final String title;
  final String? typeLabel;
  final Money? amount;

  /// Date-only.
  final DateTime? date;

  /// The saved record's note; only its first line is shown.
  final String? note;

  /// "From SMS", "Pasted", "Shared" (the side under review or another
  /// pending message).
  final String? sourceLabel;

  /// The saved record was imported from a bank message (FR-057).
  final bool importedFromSms;

  @override
  List<Object?> get props => [
    title,
    typeLabel,
    amount,
    date,
    note,
    sourceLabel,
    importedFromSms,
  ];

  /// Redacted: never the amount, the date or the note.
  @override
  String toString() => 'DuplicateSide()';
}

/// The comparison phrases shown under the two cards, so the difference is
/// carried by text, never by colour alone (ui-contract §3.6): "Same
/// amount" (or "Same as the original amount in the message", FR-059) and
/// "Same day" / "1 day apart" (calendar days).
List<String> duplicateComparisonPhrases(
  AppLocalizations l10n, {
  required DuplicateSide existing,
  required DuplicateSide incoming,
  Money? statedOriginalAmount,
}) {
  final existingAmount = existing.amount;
  final existingDate = existing.date;
  final incomingDate = incoming.date;
  return [
    if (existingAmount != null && existingAmount == incoming.amount)
      l10n.smsImportDuplicateSameAmount
    else if (existingAmount != null && existingAmount == statedOriginalAmount)
      l10n.smsImportDuplicateSameOriginalAmount,
    if (existingDate != null && incomingDate != null)
      l10n.smsImportDuplicateDaysApart(
        calendarDaysApart(existingDate, incomingDate),
      ),
  ];
}

/// One card of the side-by-side comparison. The whole card is one
/// screen-reader node read in the order shown.
class DuplicateComparisonCard extends StatelessWidget {
  const DuplicateComparisonCard({required this.side, super.key});

  final DuplicateSide side;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final amount = side.amount;
    final date = side.date;
    final noteLine = _firstLine(side.note);

    return MergeSemantics(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(side.title, style: AppTypography.label.copyWith(color: muted)),
            const SizedBox(height: AppSpacing.xs),
            if (side.typeLabel case final type?)
              Text(type, style: AppTypography.body),
            if (amount != null)
              Text(
                SmsImportLabels.money(context, amount),
                style: AppTypography.title,
              ),
            if (date != null)
              Text(
                SmsImportLabels.date(context, date),
                style: AppTypography.body,
              ),
            if (side.sourceLabel case final source?)
              Text(source, style: AppTypography.bodyMuted),
            if (noteLine != null)
              Text(
                l10n.smsImportDuplicateNote(noteLine),
                style: AppTypography.bodyMuted,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (side.importedFromSms) ...[
              const SizedBox(height: AppSpacing.xs),
              const ImportedFromSmsLabel(),
            ],
          ],
        ),
      ),
    );
  }

  static String? _firstLine(String? note) {
    final trimmed = note?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.split('\n').first.trim();
  }
}
