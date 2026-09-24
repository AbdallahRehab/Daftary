import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Shown at the assistant's (start) edge while a question is in flight
/// (T042). Three pulsing dots; when the platform asks for reduced motion
/// (`MediaQuery.disableAnimations`) the dots are drawn static. Announced to
/// screen readers via a localized live-region label.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  static const _dotCount = 3;
  static const _dotSize = 8.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _opacityFor(int index) {
    if (!_controller.isAnimating) return 0.6;
    // Each dot peaks a third of a cycle after the previous one.
    final phase = (_controller.value - index / _dotCount) % 1.0;
    final wave = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return 0.3 + 0.7 * wave;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    const corner = Radius.circular(AppRadius.lg);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          liveRegion: true,
          label: l10n.aiChatTypingLabel,
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: corner,
                  topEnd: corner,
                  bottomEnd: corner,
                  bottomStart: Radius.circular(AppRadius.sm / 2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 4,
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _dotCount; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.xs + 2),
                        Opacity(
                          opacity: _opacityFor(i),
                          child: Container(
                            width: _dotSize,
                            height: _dotSize,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurfaceVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
