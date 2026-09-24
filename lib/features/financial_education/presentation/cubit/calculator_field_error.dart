import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../domain/entities/calculator_validation_result.dart';

/// A per-field inline error on one of the calculator forms.
///
/// A flag rather than a message, so the page renders it via `l10n` in the
/// active locale (same rationale as `FinanceEntryFormState.amountInvalid`).
/// The first three are this layer's own parse checks on the raw text; the
/// rest are the domain calculators' [CalculatorInputProblem]s mapped onto
/// the field they concern.
enum CalculatorFieldError {
  /// The field is empty.
  required,

  /// The text is not a number (or an amount with more than 2 decimals).
  invalidNumber,

  /// A whole number was expected (the duration in years).
  wholeNumberRequired,

  /// Must be strictly greater than zero.
  mustBePositive,

  /// Must not be negative (zero allowed).
  mustNotBeNegative,
}

/// The outcome of parsing one text field: either a value or an error.
class ParsedField<T> {
  const ParsedField.value(T this.value) : error = null;
  const ParsedField.error(CalculatorFieldError this.error) : value = null;

  final T? value;
  final CalculatorFieldError? error;
}

/// Parses the calculators' raw text inputs. Arabic-Indic digits and the
/// Arabic decimal separator are accepted everywhere (`NumeralParser`), and
/// nothing here throws — unparseable text becomes a [CalculatorFieldError].
///
/// Sign checks are deliberately NOT done here: a parsed negative number is
/// passed through so the domain calculator remains the single source of
/// truth for what is valid (FR-008/FR-011/FR-012).
class CalculatorInputParser {
  const CalculatorInputParser(this._egpFormatter);

  final EgpFormatter _egpFormatter;

  /// An EGP amount in major units (e.g. `1,000.50`) → exact minor units.
  ParsedField<int> parseAmountMinorUnits(String text) {
    final normalized = NumeralParser.toWesternDigits(text).trim();
    if (normalized.isEmpty) {
      return const ParsedField.error(CalculatorFieldError.required);
    }
    try {
      return ParsedField.value(_egpFormatter.parse(normalized).minorUnits);
    } on FormatException {
      return const ParsedField.error(CalculatorFieldError.invalidNumber);
    }
  }

  /// A percentage such as `8`, `7.5` or `٧٫٥` → a finite `double`.
  ParsedField<double> parsePercent(String text) {
    final normalized = NumeralParser.toWesternDigits(
      text,
    ).trim().replaceAll('%', '').replaceAll('٪', '').trim();
    if (normalized.isEmpty) {
      return const ParsedField.error(CalculatorFieldError.required);
    }
    if (!RegExp(r'^-?(\d+\.?\d*|\.\d+)$').hasMatch(normalized)) {
      return const ParsedField.error(CalculatorFieldError.invalidNumber);
    }
    final value = double.tryParse(normalized);
    if (value == null || !value.isFinite) {
      return const ParsedField.error(CalculatorFieldError.invalidNumber);
    }
    return ParsedField.value(value);
  }

  /// A whole number of years → `int`.
  ParsedField<int> parseWholeYears(String text) {
    final normalized = NumeralParser.toWesternDigits(text).trim();
    if (normalized.isEmpty) {
      return const ParsedField.error(CalculatorFieldError.required);
    }
    if (RegExp(r'^-?\d+$').hasMatch(normalized)) {
      final value = int.tryParse(normalized);
      return value == null
          ? const ParsedField.error(CalculatorFieldError.invalidNumber)
          : ParsedField.value(value);
    }
    if (RegExp(r'^-?(\d+\.\d*|\.\d+)$').hasMatch(normalized)) {
      return const ParsedField.error(CalculatorFieldError.wholeNumberRequired);
    }
    return const ParsedField.error(CalculatorFieldError.invalidNumber);
  }

  /// Minor units → plain, ungrouped editable text (`150050` → `1500.50`,
  /// `100000` → `1000`), suitable for seeding an input field.
  static String formatMinorUnitsForInput(int minorUnits) {
    final sign = minorUnits < 0 ? '-' : '';
    final abs = minorUnits.abs();
    final major = abs ~/ 100;
    final minor = abs % 100;
    return minor == 0
        ? '$sign$major'
        : '$sign$major.${minor.toString().padLeft(2, '0')}';
  }
}
