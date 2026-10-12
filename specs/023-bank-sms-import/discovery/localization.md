# Discovery T007: Localization

Read-only inspection, working tree on `023-bank-sms-import` (HEAD `4a5565d`). Line numbers are as of this commit.

## 1. ARB files and gen-l10n config

| Item | Location | Notes |
|---|---|---|
| Config | `l10n.yaml:1-3` | `arb-dir: lib/core/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`. No `nullable-getter` option, so `AppLocalizations.of(context)!` is the idiom (e.g. `lib/features/ocr/presentation/pages/scan_capture_page.dart:48`). |
| pubspec | `pubspec.yaml:147` `generate: true`; `flutter_localizations` `:38`; `intl: ^0.20.2` `:54` | |
| Template | `lib/core/l10n/app_en.arb` (2809 lines), `"@@locale": "en"` at `:2` | Keys are flat camelCase with a feature prefix (`finEdu*`, `ocr*`, `sync*`, `ai*` …). Not every key has an `@key`; newer features do. |
| Arabic | `lib/core/l10n/app_ar.arb` (1505 lines), `"@@locale": "ar"` at `:2` | Some features also carry empty `@key: {}` entries in AR (e.g. `app_ar.arb:711-719` for `ocrConfidence*`); harmless, optional. |
| Generated | `lib/core/l10n/app_localizations.dart`, `app_localizations_ar.dart`, `app_localizations_en.dart` | **Committed to git** (`git ls-files lib/core/l10n`). After adding keys, run `fvm flutter gen-l10n` and include the regenerated files. |
| Prefix check | `grep -c '"sms' app_en.arb` = 0 | The `smsImport*` prefix is free; no collision. |

`@key` metadata style to copy (description + typed placeholders), `app_en.arb:720-728`:

```json
"syncStatusPending": "{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}",
"@syncStatusPending": {
  "description": "Sync status: changes not yet uploaded.",
  "placeholders": { "count": { "type": "int" } }
},
```

Select precedent (ui-contract §6): `repaymentFlipConfirmMessage` `app_en.arb:2687` (`{direction, select, owe{…} other{…}}`, placeholders typed `String` at `:2688-2700`), AR `app_ar.arb:1420`.

Confidence strings that SMS must reuse (no `smsImportConfidence*` family, ui-contract §5): `ocrConfidenceLow/Medium/High/Inferred` at `app_en.arb:1311,1313,1315,1317` and `app_ar.arb:712,714,716,718`.

## 2. Arabic plural precedent

**Correction to plan/tasks**: `app_ar.arb:284` (`notificationSavingsBehindPaceBody`) has `=1/=2/few/many/other` but **no `=0`**, so it is not the full six-form precedent. The keys that carry the full `=0/=1/=2/few/many/other` set are:

| Key | AR line | EN line |
|---|---|---|
| `occasionDeleteConfirmMessage` | `app_ar.arb:615` | `app_en.arb:1193` (`=0/=1/other`) |
| `savingsOverviewGoalCount` | `app_ar.arb:1360` | `app_en.arb:2326` (`=1/other`, `@` meta `:2327-2334`) |

Use `savingsOverviewGoalCount` (`app_ar.arb:1360`) as the template for count phrases:
`{count, plural, =0{لا توجد أهداف} =1{في هدف واحد} =2{في هدفين} few{في {count} أهداف} many{في {count} هدفًا} other{في {count} هدف}}`
(few → plural noun, many → singular accusative with tanween, other → singular genitive).

Other partial-set Arabic plurals (left alone): `app_ar.arb:286`, `:1321`, `:1322`, `:1424` (no `=0`), and `syncStatusPending` `app_ar.arb:368` (no `=0`, no `many`; the known follow-up named in ui-contract §6 / plan l10n section). English plural count in `app_en.arb`: 8.

## 3. Parity test to clone

**Path**: `test/features/ai_assistant/presentation/l10n_parity_test.dart` (47 lines). It is the only parity test in the repo.

- `:10-12` loads both ARBs with `jsonDecode(File('lib/core/l10n/app_$locale.arb'))` (cwd = repo root under `flutter test`).
- `:16` selects keys by prefix: `en.keys.where((k) => k.startsWith('ai'))` (the `@`-meta keys start with `@`, so they are excluded automatically). Clone with `'smsImport'`.
- `:21-23` non-empty key set; `:25-36` every key exists and is non-empty in AR, and no AR-only keys; `:38-46` placeholder names match.
- **Caveat for the clone**: the placeholder extractor `:18-19` is `RegExp(r'\{(\w+)')`. On an ICU plural/select string it also captures the first word inside each branch (`=1{Across 1 goal}` → `Across`), so EN and AR placeholder sets would differ for every plural key. It is unexercised today because no `ai*` key is a plural. The `smsImport` clone must extract placeholders from the `@key.placeholders` map of `app_en.arb` (or strip ICU branches) and add the plural/select category-set comparison required by ui-contract §6 (EN `=0/=1/other`, AR exactly `=0/=1/=2/few/many/other` for `smsImport*` only).
- Target path per tasks T066: `test/features/sms_import/presentation/l10n_parity_test.dart` (`t/sms/...`).

## 4. Hardcoded-string guard to clone

There is **no directory-wide** hardcoded-string guard today. The existing one is single-file:

- `test/widget/data_export_page_test.dart:239-245`: reads `lib/features/data_privacy/presentation/pages/data_export_page.dart` and asserts `isNot(matches(RegExp(r'''Text\(\s*['"]''')))`.

Directory-walk pattern to combine it with (sorted, recursive, `.dart` only, asserts the dir exists):

- `test/features/financial_education/architecture_boundary_test.dart:60-69` (`_dartFilesUnder`), and the violation-collector shape at `:78-83`.

The T066 clone = `_dartFilesUnder('lib/features/sms_import/presentation')` + the `Text\(\s*['"]` regex per file, reporting `path` for each hit. Target: `test/features/sms_import/presentation/hardcoded_string_guard_test.dart`. Consider also catching `semanticsLabel: '` / `tooltip: '` / `labelText: '` literals (ui-contract §7 requires localized semantics), but at minimum match the existing regex.

## 5. Number, currency and date formatting

| Helper | Location | Contract |
|---|---|---|
| `numeralLocaleFor(languageCode)` | `lib/core/l10n/numeral_locale.dart:8-9` | `'ar' → 'ar_u_nu_latn'`, else unchanged. Single source of the Western-digits rule. 14 call sites in lib. |
| `CurrencyFormatter({required currency, locale = 'en'})` | `lib/core/money/currency_formatter.dart:16-18` | `format(Money)` `:43-54` (Western digits, post-processed through `NumeralParser.toWesternDigits` at `:50`); `formatWithSymbol(Money)` `:60-61` → `"150.50 EGP"` (ISO code suffix, reads the same in RTL/LTR); `parse(String)` `:67-112`; `maxWholeDigits = 12` `:24`. Formats are cached per locale `:32-39`. |
| `AppDateFormatter({locale = 'en'})` | `lib/core/date/app_date_formatter.dart:11-14` | `format(DateTime)` `:48-49` = `yMd` + `toWesternDigits`; `formatDateTime` `:53-54` = `yMd().add_jm()` + `toWesternDigits`. The doc at `:39-47` explains why post-processing is mandatory: `DateFormat` sometimes drops `_u_nu_latn` and renders Eastern digits. |
| Time-of-day precedent (ui-contract §6 "message time") | `lib/features/cloud_sync/presentation/pages/sync_settings_page.dart:200-205` | `NumeralParser.toWesternDigits(DateFormat.jm(numeralLocaleFor(locale)).format(at))`. Copy this exactly for "Message time 10:15". |

**Findings the parser slice must respect (CurrencyFormatter.parse)**:

1. `parse` requires Western digits (doc `:63-66`); run `NumeralParser.toWesternDigits` first.
2. **Privacy**: its `FormatException` messages embed the raw input (`'Invalid amount: $input'` `:78,82,86`; `:89-91`; `:98-100`). The SMS parser must catch it and never copy `e.message`/`e.toString()` anywhere (plan Step 3 "`e.message` never copied"; briefing rule 6).
3. **Decimal comma (CHK045)**: `parse` strips every `,` and whitespace from the whole part (`:80`, `RegExp(r'[,\s]')`), so `"100,50"` parses silently as `10050` and `"1.234,50"` throws only because of `.`-split fraction. The SMS amount extractor must validate grouping itself (comma only when followed by exactly 3 digits) **before** calling `parse`; `parse` is not a sufficient guard. Space grouping (`"1 500"`) is accepted by `:80`.
4. More than `fractionDigits` decimals and more than 12 whole digits throw (`:88-101`), which maps to "unreadable".

## 6. Bidi isolation

There is **no shared bidi helper/widget** in lib today (no `BidiText`, no `Bidi.detectRtlDirectionality`, no `BidiFormatter` usage). The existing pattern is inline Unicode isolates:

| Pattern | Location |
|---|---|
| LRI/PDI around an LTR value inside a localized sentence | `lib/features/cloud_sync/presentation/pages/sync_settings_page.dart:251-252` → `l10n.syncLinkedAs('⁦$masked⁩')` |
| LRI/PDI around a formatted value | `lib/features/app_lock/presentation/widgets/lockout_countdown_banner.dart:19-25` → `'⁦$minutes:$seconds⁩'` (tests: `test/features/app_lock/presentation/widgets/pin_pad_test.dart:91,97`, `lock_screen_page_test.dart:146`) |
| FSI/PDI inside the ARB string itself | `app_ar.arb:1477` `"changeHistoryChange": "{field}: ⁨{from}⁩ ← ⁨{to}⁩"` (literal U+2068/U+2069 characters; test `test/features/transactions/presentation/mappers/transaction_audit_row_mapper_test.dart:190-203`) |
| Explicit LTR `Directionality` wrapper for a code/number chip | `lib/core/design_system/currency_indicator_chip.dart:8,24` |

So the new `BidiText` (ui-contract §5, `lib/features/sms_import/presentation/widgets/bidi_text.dart`) should wrap with `⁦…⁩` (LRI/PDI) for known-LTR tokens (masked card, sender id, amount + code) and may use `⁨…⁩` (FSI) for mixed merchant names. `Bidi.detectRtlDirectionality` (package `intl`, already a dependency) is new to the codebase; it is the plan's choice for the original-message direction (ui-contract §8.3).

## 7. Failure → message mapping

- `lib/core/l10n/failure_message.dart:7-31`: `extension FailureMessage on AppLocalizations { String messageFor(Failure? failure) => switch (failure) { … _ => errorUnknown }; }`. Typed failures map to ARB getters; parameterized cases destructure fields (`EmailAuthFailure(:final reason)` nested switch `:19-25`; `RatesMissingFailure(:final missingRatesFor)` `:26-28`).
- Doc `:4-6`: a failure's own `message` is developer diagnostics and is **never** shown on screen.
- `Failure` base: `lib/core/error/failure.dart:7-14` (`abstract class Failure extends Equatable`, `final String message`, `props => [message]`). No `EquatableConfig.stringify` anywhere, so `toString()` is the default `Instance of …`; still, `SmsImportFailure.message` must stay content-free (briefing rule 6).
- Feature-local failure precedent: `lib/features/savings/domain/entities/savings_failures.dart:13-48`, `lib/features/insights_notifications/domain/entities/notification_failures.dart:5-12`.
- T066 adds a `SmsImportFailure` arm (or one arm per subclass, since `switch` order matters: put SMS cases **before** the `_` fallback; `ValidationFailure`/`CacheFailure`/`NotFoundFailure` keep their existing generic arms, which is what ui-contract expects for save/storage errors reusing `CacheFailure`).
- Existing mapping test precedent: `test/widget/savings_contribution_form_page_test.dart:133` (`en.messageFor(RatesMissingFailure(...))`, using `lookupAppLocalizations(const Locale('en'))`). There is no `test/core/l10n/` directory yet.
