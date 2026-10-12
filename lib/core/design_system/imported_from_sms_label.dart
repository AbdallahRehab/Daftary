import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'tokens.dart';

/// "Imported from a bank message" (Arabic "مستورد من رسالة بنكية"): marks
/// a saved record the user added from a bank message (023 FR-057, US1-9).
///
/// Icon plus text, never colour alone, with its own screen-reader label.
/// It lives in core because both the people ledger and the finance history
/// render it. It says nothing about the message itself: the saved record
/// holds only the fields the user confirmed.
class ImportedFromSmsLabel extends StatelessWidget {
  const ImportedFromSmsLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      label: l10n.smsImportProvenanceSemantics,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sms_outlined, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              l10n.smsImportProvenanceLabel,
              style: AppTypography.label.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
