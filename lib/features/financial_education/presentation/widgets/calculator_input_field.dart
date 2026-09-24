import 'package:flutter/material.dart';

import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/calculator_field_error.dart';

/// A numeric [AppTextField] bound to one calculator input held in Cubit
/// state. The controller is re-synced from [value] only when the text
/// actually differs (e.g. after the savings-goal pre-fill), so the caret is
/// never moved out from under the user while typing.
class CalculatorInputField extends StatefulWidget {
  const CalculatorInputField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.errorText,
    this.allowDecimal = true,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool allowDecimal;
  final TextInputAction textInputAction;

  @override
  State<CalculatorInputField> createState() => _CalculatorInputFieldState();
}

class _CalculatorInputFieldState extends State<CalculatorInputField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(CalculatorInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
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
    return AppTextField(
      label: widget.label,
      controller: _controller,
      // Arabic-Indic digits are normalized on parse (`NumeralParser`), so
      // both numeral systems are typeable here.
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.allowDecimal,
      ),
      textInputAction: widget.textInputAction,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
    );
  }
}

/// The localized inline message for [error] on one field. The two
/// sign-related messages are field-specific, so each call site supplies
/// its own wording for them.
String? calculatorFieldErrorText(
  AppLocalizations l10n,
  CalculatorFieldError? error, {
  required String mustBePositive,
  String? mustNotBeNegative,
}) {
  return switch (error) {
    null => null,
    CalculatorFieldError.required => l10n.finEduCalcErrorRequired,
    CalculatorFieldError.invalidNumber => l10n.finEduCalcErrorInvalidNumber,
    CalculatorFieldError.wholeNumberRequired => l10n.finEduCalcErrorWholeYears,
    CalculatorFieldError.mustBePositive => mustBePositive,
    CalculatorFieldError.mustNotBeNegative =>
      mustNotBeNegative ?? mustBePositive,
  };
}
