import 'package:flutter/material.dart';

/// A large icon inside a soft tinted circular surface. Used where a single
/// icon needs to feel like a considered illustration rather than a bare
/// Material glyph (e.g. onboarding topics, future empty/success moments).
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    required this.icon,
    super.key,
    this.size = 96,
    this.color,
  });

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveColor.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: size * 0.5, color: effectiveColor),
    );
  }
}
