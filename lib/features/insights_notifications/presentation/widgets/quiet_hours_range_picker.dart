import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// The quiet-hours control (FR-013): a switch, and — while on — the
/// editable "from"/"to" times, each opening the platform time picker.
///
/// Times are minutes since local midnight, matching the Domain. When the
/// switch is off no window is stored; turning it on stores the suggested
/// 22:00–08:00 window (spec.md Assumptions), which [suggestedStart] and
/// [suggestedEnd] also show as the starting point of the pickers.
class QuietHoursRangePicker extends StatelessWidget {
  const QuietHoursRangePicker({
    required this.start,
    required this.end,
    required this.suggestedStart,
    required this.suggestedEnd,
    required this.onEnabledChanged,
    required this.onRangeChanged,
    super.key,
  });

  /// The stored window, or `null` when quiet hours are off.
  final int? start;
  final int? end;

  final int suggestedStart;
  final int suggestedEnd;

  final ValueChanged<bool> onEnabledChanged;

  /// Called with the full new window whenever either end is edited.
  final void Function(int start, int end) onRangeChanged;

  static const int _minutesPerHour = 60;

  bool get _isEnabled => start != null && end != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveStart = start ?? suggestedStart;
    final effectiveEnd = end ?? suggestedEnd;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          key: const Key('notification_quiet_hours_switch'),
          value: _isEnabled,
          onChanged: onEnabledChanged,
          secondary: Icon(
            Icons.bedtime_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          title: Text(
            l10n.notificationQuietHoursTitle,
            style: AppTypography.body,
          ),
          subtitle: Text(
            l10n.notificationQuietHoursSubtitle,
            style: AppTypography.bodyMuted.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (_isEnabled) ...[
          const Divider(height: 1, indent: AppSpacing.md),
          _TimeRow(
            key: const Key('notification_quiet_hours_start'),
            label: l10n.notificationQuietHoursFrom,
            minutes: effectiveStart,
            onTap: () async {
              final picked = await _pick(context, effectiveStart);
              if (picked != null && picked != effectiveStart) {
                onRangeChanged(picked, effectiveEnd);
              }
            },
          ),
          const Divider(height: 1, indent: AppSpacing.md),
          _TimeRow(
            key: const Key('notification_quiet_hours_end'),
            label: l10n.notificationQuietHoursTo,
            minutes: effectiveEnd,
            // A window like 22:00–08:00 ends the following morning.
            note: effectiveEnd <= effectiveStart
                ? l10n.notificationQuietHoursNextDay
                : null,
            onTap: () async {
              final picked = await _pick(context, effectiveEnd);
              if (picked != null && picked != effectiveEnd) {
                onRangeChanged(effectiveStart, picked);
              }
            },
          ),
        ],
      ],
    );
  }

  Future<int?> _pick(BuildContext context, int minutes) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _toTimeOfDay(minutes),
    );
    if (picked == null) return null;
    return picked.hour * _minutesPerHour + picked.minute;
  }
}

TimeOfDay _toTimeOfDay(int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minutes,
    required this.onTap,
    this.note,
    super.key,
  });

  final String label;
  final int minutes;
  final VoidCallback onTap;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatted = MaterialLocalizations.of(context).formatTimeOfDay(
      _toTimeOfDay(minutes),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return ListTile(
      onTap: onTap,
      title: Text(label, style: AppTypography.body),
      // The note sits under the label rather than beside the time, so the
      // trailing area stays narrow enough for long translations.
      subtitle: note == null
          ? null
          : Text(
              note!,
              style: AppTypography.bodyMuted.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatted,
            style: AppTypography.title.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.edit_outlined, size: 18, color: colorScheme.primary),
        ],
      ),
    );
  }
}
