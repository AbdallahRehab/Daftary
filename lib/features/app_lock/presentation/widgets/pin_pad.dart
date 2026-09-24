import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// The app's numeric keypad for entering a 4-6 digit PIN (FR-003), used by
/// the lock screen and the PIN setup/change screens.
///
/// The digits typed so far live only in this widget's state — never in a
/// Cubit state — and are cleared the moment they are submitted, when the
/// pad is disabled, and when the widget goes away (FR-016).
///
/// PINs have a variable length and only their hash is stored, so the pad
/// can't know when a PIN is "complete": the user confirms with the check
/// key, enabled once [minLength] digits are in.
///
/// The keypad grid and the entered-digit dots are always laid out left to
/// right, like every phone keypad — also in Arabic — so muscle memory and
/// digit order don't flip under RTL. Everything else follows the ambient
/// direction.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onSubmitted,
    this.enabled = true,
    this.minLength = minPinLength,
    this.maxLength = maxPinLength,
  }) : assert(minLength > 0 && maxLength >= minLength);

  static const int minPinLength = 4;
  static const int maxPinLength = 6;

  /// Called with the entered digits when the user confirms.
  final ValueChanged<String> onSubmitted;

  /// When `false` every key is inert and any partial entry is cleared
  /// (e.g. during a lockout cooldown or while a PIN is being checked).
  final bool enabled;
  final int minLength;
  final int maxLength;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _digits = '';

  bool get _canSubmit => widget.enabled && _digits.length >= widget.minLength;

  @override
  void didUpdateWidget(covariant PinPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _digits.isNotEmpty) _digits = '';
  }

  @override
  void dispose() {
    _digits = '';
    super.dispose();
  }

  void _append(String digit) {
    if (!widget.enabled || _digits.length >= widget.maxLength) return;
    HapticFeedback.selectionClick();
    setState(() => _digits += digit);
  }

  void _deleteLast() {
    if (!widget.enabled || _digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _submit() {
    if (!_canSubmit) return;
    final pin = _digits;
    setState(() => _digits = '');
    widget.onSubmitted(pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: TextDirection.ltr,
      // Narrow phones (320 dp) can't fit three keys plus the default gaps:
      // shrink the gaps between keys, never the keys (touch targets).
      child: LayoutBuilder(
        builder: (context, constraints) =>
            _buildPad(l10n, _keyGapFor(constraints.maxWidth)),
      ),
    );
  }

  /// Horizontal padding on each side of a key: [AppSpacing.md] when there
  /// is room, less on narrow screens.
  static double _keyGapFor(double maxWidth) {
    if (!maxWidth.isFinite) return AppSpacing.md;
    return ((maxWidth - 3 * _keySize) / 6).clamp(0, AppSpacing.md);
  }

  Widget _buildPad(AppLocalizations l10n, double keyGap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PinDots(
          filled: _digits.length,
          total: widget.maxLength,
          semanticLabel: l10n.appLockPinPadDigitsEntered(_digits.length),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          _KeyRow(
            gap: keyGap,
            children: [
              for (final digit in row)
                _DigitKey(
                  digit: digit,
                  onPressed: widget.enabled ? () => _append(digit) : null,
                ),
            ],
          ),
        _KeyRow(
          gap: keyGap,
          children: [
            _IconKey(
              key: const Key('pin_pad.delete'),
              icon: Icons.backspace_outlined,
              tooltip: l10n.appLockPinPadDelete,
              onPressed: widget.enabled && _digits.isNotEmpty
                  ? _deleteLast
                  : null,
            ),
            _DigitKey(
              digit: '0',
              onPressed: widget.enabled ? () => _append('0') : null,
            ),
            _IconKey(
              key: const Key('pin_pad.submit'),
              icon: Icons.check_rounded,
              tooltip: l10n.appLockPinPadSubmit,
              emphasized: true,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// One slot per possible digit; filled slots show how many are typed. The
/// digits themselves are never shown.
class _PinDots extends StatelessWidget {
  const _PinDots({
    required this.filled,
    required this.total,
    required this.semanticLabel,
  });

  final int filled;
  final int total;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: i < filled
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.gap, required this.children});

  /// Horizontal padding on each side of every key.
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final child in children)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gap),
              child: child,
            ),
        ],
      ),
    );
  }
}

const double _keySize = 68;

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.digit, required this.onPressed});

  final String digit;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return SizedBox.square(
      dimension: _keySize,
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(
          alpha: enabled ? 1 : 0.5,
        ),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('pin_pad.digit.$digit'),
          onTap: onPressed,
          child: Center(
            child: Text(
              digit,
              style: AppTypography.headline.copyWith(
                fontWeight: FontWeight.w500,
                color: enabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconKey extends StatelessWidget {
  const _IconKey({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: _keySize,
      child: emphasized
          ? IconButton.filled(
              onPressed: onPressed,
              tooltip: tooltip,
              icon: Icon(icon),
              iconSize: 28,
            )
          : IconButton(
              onPressed: onPressed,
              tooltip: tooltip,
              icon: Icon(icon),
              iconSize: 26,
              color: colorScheme.onSurfaceVariant,
            ),
    );
  }
}
