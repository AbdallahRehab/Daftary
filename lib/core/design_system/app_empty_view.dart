import 'package:flutter/material.dart';

import 'tokens.dart';

/// The app's single empty-state layout: always explains what's empty, why
/// it matters, and (optionally) what action closes the gap — an infinite
/// spinner or a bare "no data" label is never an acceptable substitute.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    required this.title,
    required this.message,
    super.key,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    // Scrollable so the message and action stay reachable when the space
    // is short (landscape, a large system font, or a small parent box),
    // while still centering in the available height when it fits.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
          ),
          child: Center(child: _content(context, onSurfaceVariant)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Color onSurfaceVariant) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.bodyMuted.copyWith(color: onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
