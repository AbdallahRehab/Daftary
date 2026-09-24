import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';

/// Where a `RateNeededBanner`'s "Set exchange rate" action leads (018).
const String exchangeRatesRoute = '/settings/currency/rates';

/// Opens exchange-rate settings from a blocked-total indicator.
void openExchangeRateSettings(BuildContext context) {
  context.push(exchangeRatesRoute);
}

/// Renders each of a blocked balance's per-currency nets in its own
/// currency, as magnitudes joined by " + " (e.g. `100.00 USD + 20.00 EUR`).
/// Used where a converted total is unavailable (FR-009) but what is known
/// in each record's original currency can still be shown (FR-010).
String formatNativeNets(List<Money> nativeNets, {required String locale}) {
  final formatter = EgpFormatter(locale: locale);
  return nativeNets.map((m) => formatter.formatWithSymbol(m.abs())).join(' + ');
}
