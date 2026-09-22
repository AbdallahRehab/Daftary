import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../people/domain/entities/person.dart';

/// A text field with live search-as-you-type against active people, plus an
/// inline "create new person" affordance so the user never has to leave the
/// transaction flow to add someone new (FR-002).
class PersonPickerField extends StatefulWidget {
  const PersonPickerField({
    required this.query,
    required this.results,
    required this.selectedPerson,
    required this.onQueryChanged,
    required this.onPersonSelected,
    required this.onCreateNew,
    super.key,
    this.errorText,
  });

  final String query;
  final List<Person> results;
  final Person? selectedPerson;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Person> onPersonSelected;
  final ValueChanged<String> onCreateNew;
  final String? errorText;

  @override
  State<PersonPickerField> createState() => _PersonPickerFieldState();
}

class _PersonPickerFieldState extends State<PersonPickerField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void didUpdateWidget(covariant PersonPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reconcile when `query` changed for a reason other than the
    // user's own typing (e.g. pre-binding to a known person, or picking a
    // search result/duplicate match) — otherwise every keystroke would
    // reset the cursor to the end of the field.
    if (widget.query != oldWidget.query && widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showCreateAffordance =
        widget.query.trim().isNotEmpty &&
        widget.selectedPerson?.name != widget.query &&
        !widget.results.any(
          (p) => p.name.toLowerCase() == widget.query.toLowerCase(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: l10n.personLabel,
          controller: _controller,
          errorText: widget.errorText,
          onChanged: widget.onQueryChanged,
        ),
        if (widget.results.isNotEmpty || showCreateAffordance) ...[
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final person in widget.results)
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      title: Text(person.name),
                      onTap: () => widget.onPersonSelected(person),
                    ),
                  ),
                if (showCreateAffordance)
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.person_add_alt_1),
                      title: Text(
                        '${l10n.createPersonInlineAction} "${widget.query}"',
                      ),
                      onTap: () => widget.onCreateNew(widget.query),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
