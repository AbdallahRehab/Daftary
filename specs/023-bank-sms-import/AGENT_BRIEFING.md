# Agent briefing — 023 Bank SMS Import implementation

Every subagent reads this file first, then the docs listed for its slice.

## Source of truth
- `specs/023-bank-sms-import/`: spec.md, plan.md, research.md, data-model.md, contracts/*.md, quickstart.md, tasks.md
- `.specify/memory/constitution.md` (v1.1.0, Principle X covers SMS)
- Discovery notes (written in Phase 1): `specs/023-bank-sms-import/discovery/*.md`. Read the ones relevant to your slice before you code.
- Decision logs: `specs/023-bank-sms-import/decisions/*.md`. Read them all; write your own.

## Non-negotiable rules (from the owner)
1. Don't rewrite unrelated code. Make changes to existing files additive and minimal.
2. Use only the existing state management (flutter_bloc Cubits + Equatable + injectable/get_it). Add no second approach.
3. Don't duplicate transaction or finance domain models. Reuse MoneyTransaction / FinanceEntry and the existing repositories.
4. Don't change existing financial calculations.
5. Never create a transaction from SMS automatically. The only write path is SmsImportRepositoryImpl.confirm, called from AddImportedTransaction after an explicit Add on one item. No batch add.
6. Keep raw SMS private and minimal: mask, then seal with AES-GCM, purge on decision. Never log SMS content: no print, debugPrint, developer.log or Log.* in sms_import or the Kotlin SMS files, and nothing in exceptions or toString (redact). No analytics or crash-reporting imports in sms_import. Never send SMS text to any network or AI service.
7. Offline-first: nothing in the feature needs the network.
8. Arabic + English with full Arabic plurals (=0/=1/=2/few/many/other). RTL/LTR, dark mode. All user strings come from the ARB files.
9. Reuse existing design-system widgets (AppCard, AppTextField, AppDateField, CurrencyPicker, CategoryPickerField, PersonPickerField, AppModalSheet, AppConfirmDialog, ConfidenceIndicator …). Never import the manual form pages or their Cubits into the review page.
10. iOS gets paste only, never SMS inbox access. Add no Info.plist keys, entitlements or extensions.
11. Keep Android behind ports (domain/services) with Platform* and Unavailable* adapters. Domain and presentation never branch on Platform.isX. Read availability only through GetSmsCapability.
12. Don't bypass Android security restrictions.

## Coordination rules
- **No git commits, no pushes, no branch switching.** The orchestrator owns git. Work happens in the working tree on branch `023-bank-sms-import`.
- **Never run `supabase db push`** or touch a remote database.
- Toolchain: use `fvm flutter …` and `fvm dart …` (Flutter 3.47.0).
- **build_runner**: run `fvm dart run build_runner build --delete-conflicting-outputs` only when your prompt says you own codegen for your slice. If you need generated code and you don't own codegen, say so in your report.
- Stay inside the files of your task slice. If a fix outside your slice is unavoidable, keep it minimal and list it in your report.
- Mark each task `[X]` in tasks.md **only** when it is fully done and its tests pass. Edit only the checkbox characters of your own tasks. If a task is partly done or blocked, leave `[ ]` and explain in your decisions file.
- Before reporting, run `fvm dart format` on the files you touched, `fvm flutter analyze` (zero new issues), and the tests for your slice. Report the real results with counts. Never claim a pass you didn't observe. Never skip, delete or weaken a test to make it pass. Fix the root cause.
- Write your decisions to `specs/023-bank-sms-import/decisions/<your-slice-name>.md`: every place where the docs conflicted or were ambiguous, what you chose (most conservative/safe reading), and why.

## Orchestrator decisions on known spec conflicts (binding)
- **Capability switch (CHK013)**: the Android Gradle variable `DAFTARY_SMS_IMPORT` (fallback `-Pdaftary.smsImport=true`) controls whether READ_SMS is declared. There is no Dart const for the capability; Dart reads `readSmsDeclared` from the channel. `kBankMessageImportFeatureEnabled` (Dart) gates only the Home quick action and Home card. The Settings tile shows whenever the feature can be used (paste works everywhere); SMS-scan rows show only when the capability is available.
- **Paste-only platforms (CHK036)**: the `/bank-messages` hub and the pending list work on every platform. iOS, macOS and SMS-free Android can hold pending items from paste or share. Scan and enable UI is hidden when the capability is unavailable.
- **Skipped/unreadable list (CHK003)**: shown only in-memory in the scan summary of the current scan (bank, date, reason, never text). It is not persisted and is not a history screen.
- **Decimal comma / ambiguous separators (CHK045)**: never produce a silently wrong amount. A comma is a thousands separator only when followed by exactly 3 digits; otherwise (e.g. "100,50", "1.234,50") the amount is unreadable/null with Low confidence and must be entered by the user. Space grouping ("1 500") and amounts glued to currency ("1500EGP", "EGP1,500.00") must parse correctly.
- **Year inference (CHK050)**: when the year is missing, use the current year. If that yields a date more than 1 day after "now" (AppClock), use the previous year.
- **Bank profiles (OQ2/OQ3, no real samples available)**: build the profiles for NBE, Banque Misr, CIB, QNB Alahli, Banque du Caire, AAIB and InstaPay from **synthetic** fixtures modeled on public, generic bank-SMS phrasing. Each profile carries `verified: false`. Register them (so the Android allow-list of senders works), but the parser caps overall confidence at **Medium** for any unverified profile and adds a warning. Flipping to `verified: true` requires real samples (owner TODO). Fixtures must be `synthetic: true`, with no real card numbers or phone numbers.
- **Device spikes S1–S5**: they can't run in this environment (no physical devices). Use the defaults the research/contract docs already state as the primary choice. Mark spike tasks as not done (`[ ]`), and record in spikes/*.md that each is "NOT RUN — device required" plus the default chosen.
- **Owner-only tasks** (T160 device walkthrough, T162 release, T167 usability, T166 device benchmark run, OQ5/OQ6 gates): leave them unchecked.

## Additional orchestrator decisions (after Phase 1 discovery)
- Ignore `.kilo/worktrees/**`, a stale untracked repo copy. Never edit it, and exclude it from greps and guards.
- `MoneyTransaction.provenance` (T032): add a small enum `RecordProvenance { manual, ocr, sms }` next to `ImportProvenance` in `lib/core/provenance/`. The getter returns it.
- Neither entity has `copyWith` today. Don't add one unless a task strictly needs it; T032 only needs the field in the constructor and `props`.
- `confirm` must map every inner failure to a fixed, content-free failure. Never pass through `CacheFailure('...: $e')` text, because SQLite errors include bound parameters.
- Every Equatable type that carries SMS-derived data (draft, pending item, parse result, states) overrides `toString` with a redacted form.
- SMS amount parsing validates separators itself before it calls `CurrencyFormatter.parse` (which strips every comma), and never copies `FormatException.message`.
- `addSmsSourcedEntry` adds an archived-category check locally. Don't change `addEntry`.
