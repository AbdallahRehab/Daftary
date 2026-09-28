import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/glass/app_modal_sheet.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../occasions/domain/entities/occasion.dart';
import '../../../occasions/domain/repositories/occasions_repository.dart';

/// Tags the whole scan batch to an existing occasion, or clears the tag
/// (FR-014).
///
/// Reads the occasions list through the repository abstraction resolved
/// from the DI container — the same way `OccasionFormPage` loads the
/// occasion it edits. The picker owns no state that matters: the chosen id
/// goes straight to `ScanReviewCubit`, which is where the batch tag
/// actually lives.
class OccasionTagPicker extends StatefulWidget {
  const OccasionTagPicker({
    required this.selectedOccasionId,
    required this.onOccasionSelected,
    super.key,
  });

  final String? selectedOccasionId;

  /// `null` clears the tag, which the repository treats as "save these as
  /// plain transactions again".
  final ValueChanged<String?> onOccasionSelected;

  @override
  State<OccasionTagPicker> createState() => _OccasionTagPickerState();
}

class _OccasionTagPickerState extends State<OccasionTagPicker> {
  List<Occasion> _occasions = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOccasions();
  }

  Future<void> _loadOccasions() async {
    final result = await getIt<OccasionsRepository>().getOccasionsList();
    if (!mounted) return;
    result.match(
      // A failed list is not a failed review: the batch simply stays
      // untagged, which is the valid default, so this never blocks confirm.
      (_) => setState(() => _isLoading = false),
      (occasions) => setState(() {
        _occasions = occasions;
        _isLoading = false;
      }),
    );
  }

  Occasion? get _selected {
    final id = widget.selectedOccasionId;
    if (id == null) return null;
    for (final occasion in _occasions) {
      if (occasion.id == id) return occasion;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selected;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: _isLoading ? null : () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.ocrReviewOccasionLabel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected?.name ?? l10n.ocrReviewOccasionNone,
                style: AppTypography.body.copyWith(
                  color: selected == null
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                ),
              ),
            ),
            if (selected != null)
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.ocrReviewOccasionClear,
                onPressed: () => widget.onOccasionSelected(null),
              )
            else
              const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return showAppModalSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.ocrReviewOccasionPickerTitle,
                style: AppTypography.title,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_occasions.isEmpty)
                Text(
                  l10n.ocrReviewOccasionEmpty,
                  style: AppTypography.bodyMuted.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Flexible(
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.block),
                          title: Text(l10n.ocrReviewOccasionNone),
                          selected: widget.selectedOccasionId == null,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            widget.onOccasionSelected(null);
                          },
                        ),
                        for (final occasion in _occasions)
                          ListTile(
                            leading: const Icon(Icons.celebration_outlined),
                            title: Text(occasion.name),
                            selected: occasion.id == widget.selectedOccasionId,
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              widget.onOccasionSelected(occasion.id);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
