import 'package:flutter/material.dart';

import 'tokens.dart';

/// The app's single surface-card container: consistent radius, padding, and
/// a hairline border instead of a heavy shadow.
class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.md);
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    return Container(
      // Clips inner content (e.g. a zero-padding list of `ListTile`s) to
      // the card's own rounded corners, so tap ripples never square off
      // past the border.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: borderRadius,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      // Always provides a `Material` ancestor, not just when the card
      // itself is tappable: a `ListTile`/`RadioListTile` nested inside
      // (e.g. a zero-padding settings/picker card) paints its own
      // background and ink splashes on the nearest `Material`, and this
      // card's own colored `Container` would otherwise hide them.
      child: Material(
        color: Colors.transparent,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
