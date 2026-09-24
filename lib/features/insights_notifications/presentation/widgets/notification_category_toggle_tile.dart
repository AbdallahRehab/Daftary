import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';

/// One independently toggleable notification category (FR-009) — a
/// leading icon, a title, a one-line explanation of what triggers it, and
/// a switch.
class NotificationCategoryToggleTile extends StatelessWidget {
  const NotificationCategoryToggleTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;

  /// `null` renders the tile disabled.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(title, style: AppTypography.body),
      subtitle: Text(
        description,
        style: AppTypography.bodyMuted.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
