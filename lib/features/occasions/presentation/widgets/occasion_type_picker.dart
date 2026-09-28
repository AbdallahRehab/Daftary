import 'package:flutter/material.dart';

import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/occasion_type.dart';
import 'occasion_type_chip.dart';

/// Picks an occasion type: one of [OccasionType.standardValues] as a chip,
/// or a free-text custom value typed into the field the "Custom type" chip
/// reveals (FR-002).
///
/// Mirrors the standard-set-plus-custom pattern 001 established for a
/// person's relationship tag, so both read and behave the same way.
class OccasionTypePicker extends StatefulWidget {
  const OccasionTypePicker({
    required this.selectedType,
    required this.onTypeSelected,
    super.key,
    this.errorText,
  });

  /// The current value — a standard key, a custom free-text value, or
  /// `null` when nothing has been chosen yet.
  final String? selectedType;

  /// Emits the chosen value, or `null` when the custom field is emptied
  /// (which leaves the form invalid rather than silently picking a type).
  final ValueChanged<String?> onTypeSelected;
  final String? errorText;

  @override
  State<OccasionTypePicker> createState() => _OccasionTypePickerState();
}

class _OccasionTypePickerState extends State<OccasionTypePicker> {
  late final TextEditingController _customController = TextEditingController(
    text: _customValueOf(widget.selectedType),
  );

  /// Sticky once the user opts into a custom type, so clearing the field
  /// does not yank the text input away mid-edit.
  late bool _customMode = _customValueOf(widget.selectedType).isNotEmpty;

  static String _customValueOf(String? type) =>
      (type == null || type.isEmpty || OccasionType.isStandard(type))
      ? ''
      : type;

  @override
  void didUpdateWidget(covariant OccasionTypePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reconcile only when the value changed from the outside (e.g. an edit
    // form finished prefilling) — never on the user's own keystrokes,
    // which would reset the caret.
    final incoming = _customValueOf(widget.selectedType);
    if (widget.selectedType != oldWidget.selectedType &&
        incoming.isNotEmpty &&
        incoming != _customController.text) {
      _customController.value = TextEditingValue(
        text: incoming,
        selection: TextSelection.collapsed(offset: incoming.length),
      );
      _customMode = true;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final selected = widget.selectedType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.occasionTypeLabel,
          style: AppTypography.label.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final type in OccasionType.standardValues)
              ChoiceChip(
                label: Text(occasionTypeLabel(l10n, type)),
                selected: !_customMode && selected == type,
                onSelected: (_) {
                  setState(() => _customMode = false);
                  widget.onTypeSelected(type);
                },
              ),
            ChoiceChip(
              label: Text(l10n.occasionTypeCustomLabel),
              selected: _customMode,
              onSelected: (_) {
                setState(() => _customMode = true);
                final custom = _customController.text.trim();
                widget.onTypeSelected(custom.isEmpty ? null : custom);
              },
            ),
          ],
        ),
        if (_customMode) ...[
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: l10n.occasionTypeCustomHint,
            controller: _customController,
            textInputAction: TextInputAction.done,
            onChanged: (value) {
              final trimmed = value.trim();
              widget.onTypeSelected(trimmed.isEmpty ? null : trimmed);
            },
          ),
        ],
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: AppTypography.bodyMuted.copyWith(color: colorScheme.error),
          ),
        ],
      ],
    );
  }
}
