# T050 Content & Copy Audit (SC-004)

**Date**: 2026-09-24 | **Scope**: all `en`/`ar` bundled content under `lib/features/financial_education/data/content/` (3 categories, 10 articles × 2 locales) and every `finEdu*` / `finEduCalc*` UI string in `lib/core/l10n/app_{en,ar}.arb`.

| Check | Result |
|---|---|
| Names a specific investment product, asset, fund, platform, bank or broker | None found (grep over brand/product/asset terms; only false-positive substrings) |
| Directive phrasing ("you should", "we recommend", "buy", "يجب عليك", "ننصحك", "عليك أن") | None found. One idiom ("don't put all your eggs in one basket") reworded to non-imperative form in both locales |
| Promised returns | None. Every rate is framed as illustrative; calculator result card carries "Illustrative only … not guaranteed" |
| Personal-profiling inputs (risk tolerance, net worth, income profiling used to tailor content) | None. Calculator inputs are user-typed values used only in the displayed calculation (monthly amount, rate, years, income, savings); nothing is persisted |
| Persistent disclaimer copy | `finEduDisclaimer` present in both locales, rendered by the stateless `PersistentDisclaimerBanner` on all 6 screens |

**Reviewer note**: The article title "Building Your First Budget" / «إعداد ميزانيتك الأولى» uses a possessive but is descriptive, not directive — kept.

**Outcome**: PASS — no violations remaining.
