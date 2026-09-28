import 'package:flutter/material.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Shows the data-sharing disclosure (FR-003/FR-004) as a modal sheet and
/// resolves to `true` only when the user explicitly accepts it. Dismissing
/// the sheet any other way (swipe, back, barrier tap, "Not now") resolves
/// to `false` — consent is never implied.
Future<bool> showConsentDisclosureSheet(
  BuildContext context, {
  required String providerName,
}) async {
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ConsentDisclosureSheet(providerName: providerName),
  );
  return accepted ?? false;
}

/// The plain-language disclosure itself: only minimal, per-question,
/// structured data is ever sent — never a full data dump — and only to the
/// user's own chosen provider (spec User Story 1 AC4, FR-003/FR-004).
class ConsentDisclosureSheet extends StatelessWidget {
  const ConsentDisclosureSheet({required this.providerName, super.key});

  final String providerName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final points = <(IconData, String)>[
      (Icons.filter_alt_outlined, l10n.aiConsentPointMinimal),
      (Icons.lock_outline, l10n.aiConsentPointProviderOnly(providerName)),
      (Icons.touch_app_outlined, l10n.aiConsentPointOnDemand),
      (Icons.visibility_outlined, l10n.aiConsentPointReadOnly),
      (Icons.receipt_long_outlined, l10n.aiConsentPointCost),
      (Icons.power_settings_new, l10n.aiConsentPointDisable),
    ];
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.aiConsentTitle, style: AppTypography.title),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.aiConsentIntro, style: AppTypography.body),
            const SizedBox(height: AppSpacing.md),
            for (final (icon, text) in points)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: muted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(text, style: AppTypography.body)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.aiConsentAcceptAction,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: l10n.aiConsentDeclineAction,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
