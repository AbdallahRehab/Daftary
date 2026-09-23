import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'quick_action_button.dart';

/// Home's one-tap shortcuts into the existing entry forms (012 T027,
/// FR-007/FR-008). No form is built here — every action pushes an
/// already-shipped route, pre-set where the route supports it.
///
/// The Occasion and Scan slots front whole features, so they are rendered
/// only when their flag is on (never a live route to a missing screen).
/// The flags default to the compile-time constants and are overridable so
/// both states stay testable.
class QuickActionRow extends StatelessWidget {
  const QuickActionRow({
    super.key,
    this.onReturn,
    this.showOccasion = kOccasionsFeatureEnabled,
    this.showScan = kOcrScanFeatureEnabled,
  });

  /// Called after any pushed route pops, so Home can refresh (FR-011).
  final VoidCallback? onReturn;
  final bool showOccasion;
  final bool showScan;

  static const String addExpenseLocation = '/finance/entries/new?type=expense';
  static const String addIncomeLocation = '/finance/entries/new?type=income';
  static const String addPersonLocation = '/people/new';
  static const String moneyReceivedLocation =
      '/transactions/new?direction=received';
  static const String moneyGivenLocation = '/transactions/new?direction=given';
  static const String addOccasionLocation = '/occasions/new';
  static const String scanPaperLocation = '/ocr/scan';

  static const double _spacing = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Future<void> open(String location) async {
      await context.push<void>(location);
      onReturn?.call();
    }

    final actions = <(IconData, String, String)>[
      (
        Icons.remove_circle_outline,
        l10n.homeQuickAddExpense,
        addExpenseLocation,
      ),
      (Icons.add_circle_outline, l10n.homeQuickAddIncome, addIncomeLocation),
      (
        Icons.person_add_alt_1_outlined,
        l10n.homeQuickAddPerson,
        addPersonLocation,
      ),
      (Icons.call_received, l10n.homeQuickMoneyReceived, moneyReceivedLocation),
      (Icons.call_made, l10n.homeQuickMoneyGiven, moneyGivenLocation),
      if (showOccasion)
        (
          Icons.celebration_outlined,
          l10n.homeQuickAddOccasion,
          addOccasionLocation,
        ),
      if (showScan)
        (
          Icons.document_scanner_outlined,
          l10n.homeQuickScanPaper,
          scanPaperLocation,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Evenly fills the available width with as many default-width
        // tiles per line as fit (never fewer than three), wrapping the rest
        // — works at narrow phone widths and mirrors naturally under RTL.
        var tileWidth = QuickActionButton.defaultWidth;
        if (constraints.hasBoundedWidth) {
          final perLine = math.max(
            3,
            ((constraints.maxWidth + _spacing) / (tileWidth + _spacing))
                .floor(),
          );
          // Floored so accumulated fractions never push the last tile of a
          // line onto the next one.
          tileWidth =
              ((constraints.maxWidth - _spacing * (perLine - 1)) / perLine)
                  .floorToDouble();
        }
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final (icon, label, location) in actions)
              QuickActionButton(
                key: ValueKey(location),
                icon: icon,
                label: label,
                width: tileWidth,
                onPressed: () => open(location),
              ),
          ],
        );
      },
    );
  }
}
