import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';

/// One entry in a category's article list: title plus short description
/// (FR-003). Also reused for categories and calculators on the library
/// home, which share the same "title, one-line summary, chevron" shape.
class ArticleListTile extends StatelessWidget {
  const ArticleListTile({
    required this.title,
    required this.shortDescription,
    required this.onTap,
    super.key,
    this.icon,
  });

  final String title;
  final String shortDescription;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  shortDescription,
                  style: AppTypography.bodyMuted.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
            // Mirrors automatically under RTL via `matchTextDirection`.
          ),
        ],
      ),
    );
  }
}
