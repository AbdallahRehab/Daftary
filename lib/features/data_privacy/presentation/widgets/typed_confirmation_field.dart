import 'package:flutter/material.dart';

import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/l10n/app_localizations.dart';

/// The typed half of the delete gate (FR-015, research.md Decision 8): an
/// [AppTextField] whose label names the exact phrase to type. It only
/// reports what was typed — whether that unlocks deletion is decided by
/// `DeleteConfirmationInput`, so the rule lives in one place.
class TypedConfirmationField extends StatelessWidget {
  const TypedConfirmationField({
    required this.expectedPhrase,
    required this.onChanged,
    super.key,
  });

  final String expectedPhrase;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppTextField(
      label: l10n.deleteDataConfirmLabel(expectedPhrase),
      onChanged: onChanged,
      textInputAction: TextInputAction.done,
    );
  }
}
