import 'package:equatable/equatable.dart';

/// An ISO 4217 currency from the bundled starter catalog (018 research.md
/// Decision 1). The catalog is static, version-controlled Dart data — never
/// fetched from the network (FR-014) — so every lookup is synchronous and
/// `const`, which is what lets [Money] carry a [Currency] without any I/O.
class Currency extends Equatable {
  const Currency({
    required this.code,
    required this.symbol,
    required this.nameEn,
    required this.nameAr,
    this.minorUnitsPerMajor = 100,
    this.isRemovable = true,
  });

  /// ISO 4217 code, e.g. `EGP`. Unique within the catalog.
  final String code;

  /// Display symbol, e.g. `$`.
  final String symbol;
  final String nameEn;
  final String nameAr;

  /// Smallest-unit divisor (100 for every starter currency).
  final int minorUnitsPerMajor;

  /// `false` only for [egp] (spec Key Entities: EGP can never be removed).
  final bool isRemovable;

  static const Currency egp = Currency(
    code: 'EGP',
    symbol: 'E£',
    nameEn: 'Egyptian Pound',
    nameAr: 'جنيه مصري',
    isRemovable: false,
  );
  static const Currency usd = Currency(
    code: 'USD',
    symbol: r'$',
    nameEn: 'US Dollar',
    nameAr: 'دولار أمريكي',
  );
  static const Currency eur = Currency(
    code: 'EUR',
    symbol: '€',
    nameEn: 'Euro',
    nameAr: 'يورو',
  );
  static const Currency sar = Currency(
    code: 'SAR',
    symbol: 'SR',
    nameEn: 'Saudi Riyal',
    nameAr: 'ريال سعودي',
  );
  static const Currency aed = Currency(
    code: 'AED',
    symbol: 'AED',
    nameEn: 'UAE Dirham',
    nameAr: 'درهم إماراتي',
  );
  static const Currency gbp = Currency(
    code: 'GBP',
    symbol: '£',
    nameEn: 'British Pound',
    nameAr: 'جنيه إسترليني',
  );

  /// The full bundled starter catalog, EGP first.
  static const List<Currency> catalog = [egp, usd, eur, sar, aed, gbp];

  /// Looks up [code] in the catalog; `null` for an unknown code.
  static Currency? tryFromCode(String code) {
    for (final currency in catalog) {
      if (currency.code == code) return currency;
    }
    return null;
  }

  /// Looks up [code] in the catalog. Throws [ArgumentError] for an unknown
  /// code — only ever reached by a corrupted row, since every write path
  /// goes through the catalog.
  static Currency fromCode(String code) =>
      tryFromCode(code) ??
      (throw ArgumentError.value(code, 'code', 'Unknown currency code'));

  /// The localized display name for [languageCode] (`ar` or anything else).
  String displayName(String languageCode) =>
      languageCode == 'ar' ? nameAr : nameEn;

  @override
  List<Object?> get props => [code];

  @override
  String toString() => code;
}
