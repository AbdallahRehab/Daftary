import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import 'placeholder_section_card.dart';

/// Home's Upcoming section while there is nothing real to list — no active
/// savings goal with a target date yet, and bill reminders not built (012
/// FR-010) — worded distinctly from the Financial Snapshot's balance
/// totals. Like `InsightsPlaceholderCard`, it takes no data, so it can
/// never show fabricated content (SC-004). Once a goal qualifies, Home
/// shows `UpcomingSavingsGoalsCard` instead (011 FR-031).
class UpcomingPlaceholderCard extends StatelessWidget {
  const UpcomingPlaceholderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlaceholderSectionCard(
      icon: Icons.event_outlined,
      title: l10n.homeUpcomingTitle,
      message: l10n.homeUpcomingPlaceholder,
    );
  }
}
