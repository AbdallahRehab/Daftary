import 'package:flutter/material.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/glass/app_modal_sheet.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/sms_permission_status.dart';

/// The permission and capability banner (T119, ui-contract §3.7), used on
/// the hub and in Settings. It never prompts: "Allow" and "Turn on again"
/// hand over to the enable flow, which is the only place the system
/// dialog can appear (FR-002, FR-012). The paste/share fallback is always
/// offered.
///
/// [status] `granted` or `unavailable` renders nothing.
class SmsPermissionBanner extends StatelessWidget {
  const SmsPermissionBanner({
    required this.status,
    required this.onPaste,
    this.onAllow,
    this.onOpenAppInfo,
    this.onShowMeHow,
    super.key,
  });

  final SmsPermissionStatus status;

  /// "Paste or share instead": always offered.
  final VoidCallback onPaste;

  /// "Allow" (denied) and "Turn on again" (revoked): open the enable flow.
  final VoidCallback? onAllow;
  final VoidCallback? onOpenAppInfo;

  /// "Show me how" (restricted): the numbered steps.
  final VoidCallback? onShowMeHow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final (String message, List<(String, VoidCallback?)> actions)? content =
        switch (status) {
          SmsPermissionStatus.granted ||
          SmsPermissionStatus.unavailable => null,
          SmsPermissionStatus.denied => (
            l10n.smsImportPermissionDeniedBanner,
            [(l10n.smsImportPermissionAllow, onAllow)],
          ),
          SmsPermissionStatus.permanentlyDenied => (
            l10n.smsImportPermissionPermanentBanner,
            [(l10n.smsImportPermissionOpenAppInfo, onOpenAppInfo)],
          ),
          SmsPermissionStatus.restrictedBlocked => (
            l10n.smsImportRestrictedBanner,
            [(l10n.smsImportPermissionShowMeHow, onShowMeHow)],
          ),
          SmsPermissionStatus.revoked => (
            l10n.smsImportPermissionRevokedBanner,
            [
              (l10n.smsImportPermissionTurnOnAgain, onAllow),
              (l10n.smsImportPermissionOpenAppInfo, onOpenAppInfo),
            ],
          ),
        };
    if (content == null) return const SizedBox.shrink();
    final (message, actions) = content;
    return Semantics(
      container: true,
      liveRegion: true,
      child: AppCard(
        key: ValueKey('sms_permission_banner_${status.name}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sms_failed_outlined, color: scheme.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(message, style: AppTypography.body)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.end,
              children: [
                for (final (label, onPressed) in actions)
                  if (onPressed != null)
                    TextButton(onPressed: onPressed, child: Text(label)),
                TextButton(
                  onPressed: onPaste,
                  child: Text(l10n.smsImportPermissionPasteInstead),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The restricted-settings guidance (ui-contract §3.2, T013 default copy
/// since spike S4 was not run): a numbered list authored per language,
/// Western digits in both, and copy that never claims certainty.
class RestrictedSettingsSteps extends StatelessWidget {
  const RestrictedSettingsSteps({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      l10n.smsImportRestrictedStep1,
      l10n.smsImportRestrictedStep2,
      l10n.smsImportRestrictedStep3,
      l10n.smsImportRestrictedStep4,
    ];
    return Column(
      key: const ValueKey('sms_restricted_steps'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.smsImportRestrictedIntro, style: AppTypography.body),
        const SizedBox(height: AppSpacing.sm),
        for (final step in steps)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Text(step, style: AppTypography.body),
          ),
        // Spike S4 fallback: the restricted inference may be wrong, so the
        // plain App info path is offered too.
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.smsImportRestrictedAltPath,
          key: const ValueKey('sms_restricted_alt_path'),
          style: AppTypography.body,
        ),
      ],
    );
  }
}

/// "Show me how" from a banner: the steps plus "Open App info" and the
/// paste fallback, in a sheet. Prompts nothing.
Future<void> showRestrictedGuidanceSheet(
  BuildContext context, {
  required VoidCallback onOpenAppInfo,
  required VoidCallback onPaste,
}) => showAppModalSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) {
    final l10n = AppLocalizations.of(sheetContext)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.smsImportRestrictedTitle, style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            const RestrictedSettingsSteps(),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.smsImportPermissionOpenAppInfo,
              icon: Icons.open_in_new,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onOpenAppInfo();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: l10n.smsImportPermissionPasteInstead,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onPaste();
              },
            ),
          ],
        ),
      ),
    );
  },
);
