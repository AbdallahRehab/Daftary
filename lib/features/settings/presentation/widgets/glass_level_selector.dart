import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/glass_level.dart';

/// A titled Low / Medium / High picker for one Liquid Glass dimension
/// (transparency or intensity), built from a Material [SegmentedButton] so it
/// matches every other Settings row, gives three equal labelled targets and
/// mirrors in RTL (research Decision 14).
class GlassLevelSelector extends StatelessWidget {
  const GlassLevelSelector({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final GlassLevel value;
  final ValueChanged<GlassLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<GlassLevel>(
            segments: [
              ButtonSegment(
                value: GlassLevel.low,
                label: Text(l10n.glassLevelLow),
              ),
              ButtonSegment(
                value: GlassLevel.medium,
                label: Text(l10n.glassLevelMedium),
              ),
              ButtonSegment(
                value: GlassLevel.high,
                label: Text(l10n.glassLevelHigh),
              ),
            ],
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onChanged(selection.single),
          ),
        ],
      ),
    );
  }
}
