import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import 'placeholder_section_card.dart';

/// Home's Insights section until the AI Assistant exists (012 FR-009).
///
/// Deliberately takes no data: with nothing to bind to, it is structurally
/// impossible for this card to show a fabricated insight (SC-004).
class InsightsPlaceholderCard extends StatelessWidget {
  const InsightsPlaceholderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlaceholderSectionCard(
      icon: Icons.auto_awesome_outlined,
      title: l10n.homeInsightsTitle,
      message: l10n.homeInsightsPlaceholder,
    );
  }
}
