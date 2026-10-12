# Discovery T009: Importer inventory

Read-only inspection, working tree on `023-bank-sms-import` (HEAD `4a5565d`). Commands: `grep -rn "<file>.dart" lib test` (covers relative and `package:` imports). `integration_test/`, `test_driver/` and `tool/` hold no importer of any of the three files. No file in `lib/features/ocr` uses `export`, so there is no indirect re-export to chase.

Ignore `.kilo/worktrees/galvanized-hair/`: an untracked stale worktree copy of the repo (another tool's) that shows up in a plain `grep -r .`. It is not part of the build; T016 must not edit it.

## 1. `field_confidence.dart` (moves to `lib/core/confidence/field_confidence.dart`)

Current path: `lib/features/ocr/domain/entities/field_confidence.dart`. It imports only `package:equatable/equatable.dart`, so the file itself needs no import change after `git mv`.

### lib importers (8 = 7 OCR files + `confidence_indicator.dart`, which also moves)

| # | File:line | Current import | After T016 |
|---|---|---|---|
| 1 | `lib/features/ocr/data/models/candidate_entry_mapper.dart:3` | `'../../domain/entities/field_confidence.dart'` | `'../../../../core/confidence/field_confidence.dart'` |
| 2 | `lib/features/ocr/data/parsing/candidate_entry_parser.dart:5` | `'../../domain/entities/field_confidence.dart'` | `'../../../../core/confidence/field_confidence.dart'` |
| 3 | `lib/features/ocr/data/recognition/text_recognition_service_impl.dart:11` | `'../../domain/entities/field_confidence.dart'` | `'../../../../core/confidence/field_confidence.dart'` |
| 4 | `lib/features/ocr/data/repositories/ocr_repository_impl.dart:19` | `'../../domain/entities/field_confidence.dart'` | `'../../../../core/confidence/field_confidence.dart'` |
| 5 | `lib/features/ocr/domain/entities/candidate_entry.dart:4` | `'field_confidence.dart'` | `'../../../../core/confidence/field_confidence.dart'` |
| 6 | `lib/features/ocr/domain/repositories/text_recognition_service.dart:5` | `'../entities/field_confidence.dart'` | `'../../../../core/confidence/field_confidence.dart'` |
| 7 | `lib/features/ocr/presentation/widgets/candidate_entry_card.dart:15` | `'../../domain/entities/field_confidence.dart'` | `'../../../../core/confidence/field_confidence.dart'` |
| 8 | `lib/features/ocr/presentation/widgets/confidence_indicator.dart:5` (moves) | `'../../domain/entities/field_confidence.dart'` | `'../confidence/field_confidence.dart'` (from `lib/core/design_system/`) |

`lib/core/database/app_database.dart:219` mentions `FieldConfidence` in a doc comment only (no import); leave it.

### test importers (10)

| # | File:line | Import (all `package:daftary/features/ocr/domain/entities/field_confidence.dart` → `package:daftary/core/confidence/field_confidence.dart`) |
|---|---|---|
| 1 | `test/features/ocr/data/parsing/candidate_entry_parser_test.dart:3` | |
| 2 | `test/features/ocr/data/repositories/ocr_repository_impl_test.dart:11` | |
| 3 | `test/features/ocr/domain/usecases/edit_candidate_entry_test.dart:3` | |
| 4 | `test/features/ocr/domain/usecases/scan_history_test.dart:4` | |
| 5 | `test/features/ocr/presentation/cubit/scan_detail_cubit_test.dart:5` | |
| 6 | `test/features/ocr/presentation/cubit/scan_review_cubit_test.dart:6` | |
| 7 | `test/features/ocr/presentation/widgets/ocr_rtl_theme_test.dart:5` | |
| 8 | `test/performance/ocr_batch_scale_test.dart:9` | |
| 9 | `test/widget/candidate_entry_card_test.dart:4` | |
| 10 | `test/widget/confidence_indicator_test.dart:3` | (this file also moves, see §2) |

**There is no `field_confidence_test.dart` today** (`find test -name '*field_confidence*'` is empty). plan.md's tree lists `test/core/confidence/field_confidence_test.dart` as "moved / extended"; in practice T016 has nothing to move into `test/core/confidence/`. Whether to create a new test there is a T016/T028 decision; T016's "diff contains only import lines and the moves" rule argues against creating it in T016.

## 2. `confidence_indicator.dart` (moves to `lib/core/design_system/confidence_indicator.dart`)

Current path: `lib/features/ocr/presentation/widgets/confidence_indicator.dart`. **Its own imports must change after the move** (they are relative to the old location), lines `:3-5`:

| Current | After move to `lib/core/design_system/` |
|---|---|
| `'../../../../core/design_system/tokens.dart'` | `'tokens.dart'` |
| `'../../../../core/l10n/app_localizations.dart'` | `'../l10n/app_localizations.dart'` |
| `'../../domain/entities/field_confidence.dart'` | `'../confidence/field_confidence.dart'` |

### lib importers (1)

| File:line | Current | After |
|---|---|---|
| `lib/features/ocr/presentation/widgets/candidate_entry_card.dart:16` | `'confidence_indicator.dart'` | `'../../../../core/design_system/confidence_indicator.dart'` |

### test importers (3)

| File:line | Current → after |
|---|---|
| `test/features/ocr/presentation/widgets/ocr_rtl_theme_test.dart:8` | `package:daftary/features/ocr/presentation/widgets/confidence_indicator.dart` → `package:daftary/core/design_system/confidence_indicator.dart` |
| `test/widget/candidate_entry_card_test.dart:6` | same change |
| `test/widget/confidence_indicator_test.dart:4` | same change; **the file moves** to `test/core/design_system/confidence_indicator_test.dart` (T016) |

## 3. Exact file list T016 edits (union)

Moves (`git mv`):
- `lib/features/ocr/domain/entities/field_confidence.dart` → `lib/core/confidence/field_confidence.dart`
- `lib/features/ocr/presentation/widgets/confidence_indicator.dart` → `lib/core/design_system/confidence_indicator.dart` (+ its 3 import lines)
- `test/widget/confidence_indicator_test.dart` → `test/core/design_system/confidence_indicator_test.dart` (+ its 2 import lines)

Import-only edits, lib (7): `candidate_entry_mapper.dart`, `candidate_entry_parser.dart`, `text_recognition_service_impl.dart`, `ocr_repository_impl.dart`, `candidate_entry.dart`, `text_recognition_service.dart`, `candidate_entry_card.dart` (2 lines).

Import-only edits, test (9 besides the moved one): `candidate_entry_parser_test.dart`, `ocr_repository_impl_test.dart`, `edit_candidate_entry_test.dart`, `scan_history_test.dart`, `scan_detail_cubit_test.dart`, `scan_review_cubit_test.dart`, `ocr_rtl_theme_test.dart` (2 lines), `ocr_batch_scale_test.dart`, `candidate_entry_card_test.dart` (2 lines).

This matches plan Step 1's "8 lib importers and 10 test importers". After the move, `fvm dart run build_runner` is **not** needed: neither file is annotated for injectable/drift/json codegen. Run `fvm dart format` on the edited files (`analysis_options.yaml` enables no `directives_ordering`, so import order is not lint-checked; keep each replaced line in place).

## 4. `NumeralParser` importers (23 = 20 lib + 3 test)

Source: `lib/core/money/numeral_parser.dart` (`toWesternDigits` `:14-30`; maps U+0660-0669, `٫` U+066B → `.`, `٬` U+066C → `,`).

### Role A: input parsing (user- or OCR-typed text → Western digits) — 12 lib files

Becoming more permissive (accepting U+06F0-06F9) is the intended change for these.

| File | Use site(s) |
|---|---|
| `lib/features/budgets/presentation/cubit/budget_form_cubit.dart` | import `:9`; `:445` `_egpFormatter.parse(NumeralParser.toWesternDigits(input))` |
| `lib/features/currency/presentation/cubit/rate_input.dart` | import `:1`; `:13` (then `,` → `.`) |
| `lib/features/finance/presentation/cubit/finance_entry_form_cubit.dart` | import `:8`; `:165` |
| `lib/features/financial_education/presentation/cubit/calculator_field_error.dart` | import `:2`; `:52`, `:65`, `:83` |
| `lib/features/occasions/presentation/cubit/participant_form_cubit.dart` | import `:7`; `:238` |
| `lib/features/ocr/data/parsing/candidate_entry_parser.dart` (OCR) | import `:3`; `:225` |
| `lib/features/ocr/presentation/cubit/scan_review_cubit.dart` (OCR review edit) | import `:8`; `:171` |
| `lib/features/savings/presentation/cubit/contribution_form_cubit.dart` | import `:8`; `:137` |
| `lib/features/savings/presentation/cubit/goal_form_cubit.dart` | import `:8`; `:259` |
| `lib/features/savings/presentation/cubit/what_if_cubit.dart` | import `:8`; `:196` |
| `lib/features/transactions/presentation/cubit/repayment_form_cubit.dart` | import `:11`; `:133`, `:215` |
| `lib/features/transactions/presentation/cubit/transaction_form_cubit.dart` | import `:7`; `:313` |

(plan.md summarized these as "8 form cubits, OCR, rate input"; the exact set is 7 form cubits (budget, finance entry, participant, contribution, goal, repayment, transaction) + `what_if_cubit` + `calculator_field_error` + `rate_input` + 2 OCR files.)

### Role B: post-processing of `intl` output (`NumberFormat`/`DateFormat` → force Western digits) — 8 lib files

These format through `numeralLocaleFor` (`ar` → `ar_u_nu_latn`) and only guard against `intl` falling back to plain `ar` (U+0660-0669). The app's `supportedLocales` are exactly `ar` and `en` (`lib/core/l10n/app_localizations.dart:96-99`), and `intl` emits U+06F0-06F9 only for locales such as `fa`/`ur`, which are never requested, so the extension is a no-op for them.

| File | Use site(s) |
|---|---|
| `lib/core/date/app_date_formatter.dart` | import `:4`; `:49` (`yMd`), `:54` (`yMd().add_jm()`) |
| `lib/core/money/currency_formatter.dart` | import `:5`; `:50` (`format`); doc mention `:64` |
| `lib/features/ai_assistant/presentation/widgets/chat_bubble.dart` | import `:7`; `:71` (time) |
| `lib/features/budgets/presentation/widgets/budget_month_format.dart` | import `:5`; `:25`, `:36`, `:46` (`yMMMM`/`MMM`/`yMMM`) |
| `lib/features/budgets/presentation/widgets/budget_trend_chart.dart` | import `:10`; `:132` (compact number) |
| `lib/features/cloud_sync/presentation/pages/sync_settings_page.dart` | import `:16`; `:202` (`DateFormat.jm`) |
| `lib/features/finance/presentation/widgets/monthly_trend_chart.dart` | import `:11`; `:79` (compact axis label), `:209` (date) |
| `lib/features/financial_education/presentation/widgets/calculator_result_card.dart` | import `:8`; `:162` |

### Tests (3)

| File | Role |
|---|---|
| `test/core/money/numeral_parser_test.dart` | unit tests of `toWesternDigits` (`:9`, `:13`, `:17`, `:21`, `:25`, `:33`); T017 adds the U+06F0 cases here |
| `test/core/money/amount_input_catalogue_test.dart` | Role A: `formatter.parse(NumeralParser.toWesternDigits(input))` `:26` |
| `test/core/money/egp_formatter_regression_test.dart` | Role B: a frozen pre-018 `EgpFormatter` copy calling `toWesternDigits` at `:197` (also a precedent for the "frozen legacy copy" pattern T149 needs, header `:9-14`) |

## 5. U+06F0-U+06F9 absence (T017 precondition)

Confirmed: **no source or test contains Extended Arabic-Indic digits U+06F0-U+06F9**, either as literal characters or escaped (`\u06F0`, `\u{06F0}`, `0x06F0`, `U+06F0`).

- `LC_ALL=en_US.UTF-8 grep -rnP '[\x{06F0}-\x{06F9}]' lib test integration_test test_driver tool supabase android/app/src ios/Runner macos/Runner assets pubspec.yaml l10n.yaml` → no match.
- `grep -rniE '\\u\{?06f[0-9]|0x06f[0-9]|U\+06F[0-9]'` over the same paths → no match.
- A Python scan of 3622 text files (`.dart .arb .kt .java .swift .sql .yaml .yml .json .xml .md .txt .gradle .kts`) across the repo, excluding `.git`, `build`, `.dart_tool`, `.kilo`, `specs` and `my-project`, found none.
- Positive control: the same `grep -P` for U+0660-0669 matches 24 files in `lib`+`test`, so the pattern itself works.

(`specs/` is excluded on purpose: the spec documents themselves contain `۱۲۳٫۴۵` as the example to add.)
