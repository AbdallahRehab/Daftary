import 'package:flutter/material.dart';

import '../../../../core/design_system/app_icon_badge.dart';
import '../../../../core/design_system/tokens.dart';

/// One Home quick action: an icon badge over a localized label (012 T026).
///
/// [onPressed] returns a `Future` that completes when the action is done
/// (for a navigation, when the pushed route pops). The button disables
/// itself synchronously on tap and stays disabled until that future
/// completes, so a rapid double-tap can never navigate twice (FR-013).
class QuickActionButton extends StatefulWidget {
  const QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
    this.width = defaultWidth,
  });

  /// The tile width used when the parent does not size it.
  static const double defaultWidth = 88;

  final IconData icon;
  final String label;
  final Future<void> Function() onPressed;
  final double width;

  @override
  State<QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<QuickActionButton> {
  bool _busy = false;

  Future<void> _handleTap() async {
    // Checked synchronously, before any await, so a second tap delivered in
    // the same frame is ignored even before the rebuild lands.
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.md);
    return SizedBox(
      width: widget.width,
      child: Semantics(
        button: true,
        enabled: !_busy,
        excludeSemantics: true,
        label: widget.label,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: _busy ? null : _handleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.xs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconBadge(icon: widget.icon, size: 48),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.label,
                    style: AppTypography.label.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
