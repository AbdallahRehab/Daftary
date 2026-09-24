import 'currency_formatter.dart';
import 'money.dart';

/// The pre-018 EGP formatter, kept as a thin wrapper over
/// [CurrencyFormatter] with `currency: EGP` so its output for EGP amounts is
/// structurally byte-identical to before (018 research.md Decision 5,
/// FR-015/SC-008). [parse] produces EGP; [format]/[formatWithSymbol] render
/// each amount in its own currency.
class EgpFormatter {
  EgpFormatter({String locale = 'en'})
    : _delegate = CurrencyFormatter(currency: Currency.egp, locale: locale);

  final CurrencyFormatter _delegate;

  /// Formats [money] as a locale-grouped decimal string, e.g. `15050`
  /// piastres -> `150.50`. Always Western digits (0-9), even under Arabic.
  String format(Money money) => _delegate.format(money);

  /// Formats [money] with its currency code suffix, e.g. `150.50 EGP`.
  String formatWithSymbol(Money money) => _delegate.formatWithSymbol(money);

  /// Parses a decimal EGP string into exact piastres. Throws
  /// [FormatException] on invalid input.
  Money parse(String input) => _delegate.parse(input);
}
