import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/glass/app_modal_sheet.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'duplicate_comparison_card.dart';

/// What the user chose in the [ProbableDuplicateSheet]. Dismissing the
/// sheet (back, scrim, Cancel) is `null`: the item stays pending.
enum ProbableDuplicateChoice {
  /// "It's the same, don't add": close the item as a duplicate (FR-061).
  same,

  /// "It's different, add anyway": add with `duplicateOverride` (FR-063).
  addAnyway,
}

/// The side-by-side probable-duplicate choice (ui-contract §3.6, US5-2).
///
/// Named `ProbableDuplicateSheet` because the person-scoped
/// `DuplicateWarningSheet` of `transactions` already exists (unchanged).
/// Two cards, "Already in Daftary" at the start edge in both directions,
/// stacked when the text is large or the screen narrow; the differences
/// are spelled out in text. It never decides anything itself: it returns
/// the user's choice. On open it announces "Possible duplicate found".
class ProbableDuplicateSheet extends StatefulWidget {
  const ProbableDuplicateSheet({
    required this.existing,
    required this.incoming,
    this.phrases = const [],
    this.canAddAnyway = true,
    super.key,
  });

  final DuplicateSide existing;
  final DuplicateSide incoming;

  /// From `duplicateComparisonPhrases`.
  final List<String> phrases;

  /// Whether "add anyway" can succeed: `false` while the draft misses a
  /// required field (FR-046), which disables it.
  final bool canAddAnyway;

  /// Text scale from which the cards stack (ui-contract §3.6).
  static const double stackTextScale = 1.3;

  /// Width below which the cards stack.
  static const double stackWidth = 360;

  @override
  State<ProbableDuplicateSheet> createState() => _ProbableDuplicateSheetState();
}

class _ProbableDuplicateSheetState extends State<ProbableDuplicateSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        AppLocalizations.of(context)!.smsImportDuplicateFound,
        Directionality.of(context),
        assertiveness: Assertiveness.assertive,
      );
    });
  }

  void _choose(ProbableDuplicateChoice choice) =>
      Navigator.of(context).pop(choice);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final stackForText =
        MediaQuery.textScalerOf(context).scale(10) / 10 >=
        ProbableDuplicateSheet.stackTextScale;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey('probable_duplicate_sheet'),
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.smsImportDuplicateTitle,
                style: AppTypography.title,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.smsImportDuplicateMessage,
              style: AppTypography.bodyMuted.copyWith(color: muted),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final existing = DuplicateComparisonCard(
                  key: const ValueKey('probable_duplicate_existing'),
                  side: widget.existing,
                );
                final incoming = DuplicateComparisonCard(
                  key: const ValueKey('probable_duplicate_incoming'),
                  side: widget.incoming,
                );
                final stacked =
                    stackForText ||
                    constraints.maxWidth < ProbableDuplicateSheet.stackWidth;
                if (stacked) {
                  return Column(
                    key: const ValueKey('probable_duplicate_stacked'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      existing,
                      const SizedBox(height: AppSpacing.sm),
                      incoming,
                    ],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    key: const ValueKey('probable_duplicate_side_by_side'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: existing),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: incoming),
                    ],
                  ),
                );
              },
            ),
            if (widget.phrases.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                key: const ValueKey('probable_duplicate_phrases'),
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final phrase in widget.phrases)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.compare_arrows, size: 18, color: muted),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(phrase, style: AppTypography.body),
                        ),
                      ],
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('probable_duplicate_same'),
              label: l10n.smsImportDuplicateSame,
              onPressed: () => _choose(ProbableDuplicateChoice.same),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              key: const ValueKey('probable_duplicate_add_anyway'),
              label: l10n.smsImportDuplicateAddAnyway,
              onPressed: widget.canAddAnyway
                  ? () => _choose(ProbableDuplicateChoice.addAnyway)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              key: const ValueKey('probable_duplicate_cancel'),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  AppSizes.minTouchTarget,
                  AppSizes.minTouchTarget,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.smsImportDuplicateCancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the [ProbableDuplicateSheet] through `AppModalSheet`; `null` when
/// dismissed.
Future<ProbableDuplicateChoice?> showProbableDuplicateSheet(
  BuildContext context, {
  required DuplicateSide existing,
  required DuplicateSide incoming,
  List<String> phrases = const [],
  bool canAddAnyway = true,
}) => showAppModalSheet<ProbableDuplicateChoice>(
  context: context,
  isScrollControlled: true,
  builder: (_) => ProbableDuplicateSheet(
    existing: existing,
    incoming: incoming,
    phrases: phrases,
    canAddAnyway: canAddAnyway,
  ),
);
