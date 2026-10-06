import 'package:flutter/material.dart';

import '../tokens.dart';

/// The "Edited" marker on a list row (022 C3). Plain text when [onTap] is
/// null; otherwise a button at least [AppSizes.minTouchTarget] square that
/// opens the change history, announced as "[semanticLabel], [tooltip]".
class AppEditedMarker extends StatelessWidget {
  const AppEditedMarker({
    required this.label,
    required this.semanticLabel,
    required this.tooltip,
    required this.style,
    this.onTap,
    this.overflow,
    this.alignment = Alignment.center,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final String tooltip;
  final TextStyle style;
  final VoidCallback? onTap;
  final TextOverflow? overflow;

  /// Where the text sits inside the touch target.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, style: style, overflow: overflow);
    if (onTap == null) return text;
    return Semantics(
      button: true,
      label: '$semanticLabel, $tooltip',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('edited-marker'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minTouchTarget,
            minWidth: AppSizes.minTouchTarget,
          ),
          child: Align(alignment: alignment, widthFactor: 1, child: text),
        ),
      ),
    );
  }
}
