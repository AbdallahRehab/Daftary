/// Resolves the effective `intl` locale string to use for number/date
/// formatting: the ICU `_u_nu_latn` Unicode locale extension is appended
/// under Arabic so digits stay Western (0-9) rather than `intl`'s default
/// Eastern Arabic-Indic glyphs (٠-٩) — the spec's Clarifications reject
/// Eastern digits for this financial app (FR-011, research.md Decision 5).
/// `EgpFormatter` and `AppDateFormatter` both resolve through this one
/// helper so the rule lives in exactly one place.
String numeralLocaleFor(String languageCode) =>
    languageCode == 'ar' ? 'ar_u_nu_latn' : languageCode;
