# Phase 12c decisions: localization, accessibility and RTL review (T156)

**A review by a native Arabic speaker (the owner) is still recommended** before release. The changes below are a careful non-native pass in Modern Standard Arabic, aimed to read naturally for Egyptian users. They fix copy, terminology and grammar only.

## Verification (observed)

| Check | Result |
|---|---|
| `fvm flutter gen-l10n` | Ran; the generated `app_localizations*.dart` files were updated |
| `fvm dart format` (l10n, sms_import presentation and tests) | 0 files changed after the edits were formatted |
| `fvm flutter analyze` (whole repo) | **No issues found** |
| `fvm flutter test test/features/sms_import/presentation/rtl_theme_test.dart` | **40 passed** (10 screens × 4) |
| `fvm flutter test test/features/sms_import test/features/dashboard test/widget` | **2427 passed, 0 failed** |

## Scope of the review

- All 283 `smsImport*` keys in `app_en.arb` / `app_ar.arb`. No other key was added by 023: the provenance label is `smsImportProvenanceLabel`, and the type labels reuse `financeType*` / `direction*`.
- Every EN key has an `@key` with a `description`. This was checked by script, and the existing `l10n_parity_test` still passes.
- Every count string is an ICU plural. In AR, every plural has the full set `=0/=1/=2/few/many/other`, which `l10n_parity_test` enforces. I re-read every plural by hand for agreement: `few` uses the plural noun, `many` the accusative singular with tanween, and `other` the genitive singular. No plural form needed a fix.
- English copy has no technical jargon in errors or permissions and was left unchanged.

## Terminology (binding for future 023 copy)

| Concept | Arabic term |
|---|---|
| Bank message | رسالة بنكية / الرسائل البنكية |
| Scan (noun / button) | الفحص / «افحص الآن» (بحث is no longer used) |
| Pending | معلّق / العناصر المعلّقة (with shadda) |
| Ignore | تجاهل (used only for Ignore; Discard is now «إلغاء التعديلات») |
| Mute | كتم / المرسلون المكتومون; the action is «إيقاف الاقتراحات من هذا المرسل» |
| Expense / spending | مصروف (the app's `financeTypeExpense`), never إنفاق |
| Tap | اضغط (not انقر) |
| Couldn't … | تعذّر (with shadda) |
| On-screen label inside a sentence | quoted with «…» |

## Arabic copy changes

| Key | Before | After | Reason |
|---|---|---|---|
| `smsImportEnableScan` | ابحث | افحص | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportEnableDoneTitle` | انتهى البحث | انتهى الفحص | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportScanNow` | ابحث الآن | افحص الآن | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportScanCancelled` | توقف البحث. تم الاحتفاظ بما وُجد حتى الآن. | توقف الفحص. تم الاحتفاظ بما وُجد حتى الآن. | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportScanSummaryTitle` | ملخص البحث | ملخص الفحص | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportScanFailedTitle` | توقف البحث | توقف الفحص | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportSettingsScanTitle` | البحث | الفحص | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportSettingsWindowTitle` | مدة البحث | مدة الفحص | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportSettingsLastScan` | آخر بحث: {date} | آخر فحص: {date} | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportSettingsNeverScanned` | لم يتم البحث بعد | لم يتم الفحص بعد | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportIgnoredComesBack` | سيعود عندما تضغط فحص الآن، أو تلصق هذه الرسالة أو تشاركها مرة أخرى. | سيعود عندما تضغط «افحص الآن»، أو تلصق هذه الرسالة أو تشاركها مرة أخرى. | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportIgnoredRestored` | تمت الاستعادة. اضغط فحص الآن، أو الصقها مرة أخرى، لتظهر. | تمت الاستعادة. اضغط «افحص الآن»، أو الصقها مرة أخرى، لتظهر. | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportEnableWindowTitle` | إلى أي مدى يبحث دفتري في الرسائل السابقة؟ | إلى أي مدى يفحص دفتري الرسائل السابقة؟ | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportScanTurnOnTitle` | اعثر على المعاملات البنكية في رسائلك | اكتشف المعاملات البنكية في رسائلك | «اعثر على» is an unnatural imperative; also avoids the retired بحث verb |
| `smsImportSuggestHint` | {type, select, ignore{المقترح: تجاهل. لا يُحسب شيء دخلًا أو إنفاقًا.} unset{لم يُقترح نوع. اختر نوعًا أو تجاهل هذا العنصر.} other{راجع النوع المقترح قبل الإضافة.}} | {type, select, ignore{المقترح: تجاهل. لا يُحسب شيء دخلًا ولا مصروفًا.} unset{لم يُقترح نوع. اختر نوعًا أو تجاهل هذا العنصر.} other{راجع النوع المقترح قبل الإضافة.}} | Terminology: the app's term for Expense is مصروف (financeTypeExpense), not إنفاق |
| `smsImportSuggestCashLink` | {state, select, on{السحب النقدي يُحسب إنفاقًا. غيّر ذلك من الإعدادات} other{السحب النقدي لا يُحسب إنفاقًا. غيّر ذلك من الإعدادات}} | {state, select, on{السحب النقدي يُحسب مصروفًا. غيّر ذلك من الإعدادات} other{السحب النقدي لا يُحسب مصروفًا. غيّر ذلك من الإعدادات}} | Terminology: the app's term for Expense is مصروف (financeTypeExpense), not إنفاق |
| `smsImportReviewDiscardTitle` | تجاهل تعديلاتك؟ | هل تريد إلغاء تعديلاتك؟ | Discard used تجاهل, the same word as the Ignore action on the same screen |
| `smsImportReviewDiscardConfirm` | تجاهل | إلغاء التعديلات | Discard used تجاهل, the same word as the Ignore action on the same screen |
| `smsImportMuteConfirmMessage` | سيتوقف دفتري عن اقتراح معاملات من {sender}. ستتم إزالة العناصر المعلقة منه. لن تتغير المعاملات المحفوظة. يمكنك التراجع عن ذلك من المرسلون المكتومون. | سيتوقف دفتري عن اقتراح معاملات من {sender}. ستتم إزالة العناصر المعلّقة منه. لن تتغير المعاملات المحفوظة. يمكنك التراجع عن ذلك من شاشة «المرسلون المكتومون». | Grammar: «من المرسلون المكتومون» (nominative after a preposition); now names the screen in quotes. Also shadda normalization |
| `smsImportErrorPermissionRevoked` | الاستيراد التلقائي متوقف لأن إذن الرسائل تم إيقافه. العناصر المعلّقة محفوظة. | الاستيراد التلقائي متوقف لأن إذن الرسائل أُوقف. العناصر المعلّقة محفوظة. | Passive calque «تم إيقافه» replaced by «أُوقف» |
| `smsImportErrorPermissionDenied` | يحتاج دفتري إلى إذن قراءة الرسائل للعثور على رسائل البنك. لن يضيع شيء: يمكنك لصق رسالة بنكية بدلًا من ذلك. | يحتاج دفتري إلى إذن قراءة الرسائل للعثور على رسائلك البنكية. لن يضيع شيء: يمكنك لصق رسالة بنكية بدلًا من ذلك. | Terminology: «رسائلك البنكية» (bank message) instead of «رسائل البنك» |
| `smsImportReviewSourceLabel` | {source, select, inboxScan{من الرسائل القصيرة} catchUpScan{من الرسائل القصيرة} paste{ملصوق} share{تمت مشاركته} other{من الرسائل القصيرة}} | {source, select, inboxScan{من الرسائل القصيرة} catchUpScan{من الرسائل القصيرة} paste{تم لصقها} share{تمت مشاركتها} other{من الرسائل القصيرة}} | «ملصوق» is unnatural; «تم لصقها» matches «تمت مشاركتها» |
| `smsImportSettingsStatusLabel` | {status, select, off{متوقف} on{يعمل} permissionOff{الإذن متوقف} blocked{محظور من أندرويد} other{متوقف}} | {status, select, off{متوقف} on{يعمل} permissionOff{الإذن متوقف} blocked{يمنعه أندرويد} other{متوقف}} | «محظور من أندرويد» is a calque; «يمنعه أندرويد» matches the restricted-settings copy |
| `smsImportEnableTurnOffTitle` | كيف توقفه | كيف تُوقفه | Vocalization of the verb (تُوقفه) to avoid misreading |
| `smsImportReviewMissing` | ناقص: {fields} | بيانات ناقصة: {fields} | «ناقص:» alone is terse/ungrammatical before a list; «بيانات ناقصة:» |
| `smsImportSemanticsAddUnavailable` | الإضافة غير متاحة. ناقص: {fields} | الإضافة غير متاحة. بيانات ناقصة: {fields} | «ناقص:» alone is terse/ungrammatical before a list; «بيانات ناقصة:» |
| `smsImportDuplicateSame` | هو نفسه، لا تضفه | نفس المعاملة، لا تُضفها | Masculine «هو/مختلف» had no referent; now refers to the transaction (feminine) |
| `smsImportDuplicateAddAnyway` | مختلف، أضفه على أي حال | مختلفة، أضفها على أي حال | Masculine «هو/مختلف» had no referent; now refers to the transaction (feminine) |
| `smsImportSuggestPersonNotInList` | {name} ليس ضمن أشخاصك. لا يُنشأ شخص إلا إذا نقرت على إنشاء شخص جديد. | {name} ليس ضمن أشخاصك. لا يُنشأ شخص إلا إذا ضغطت «إنشاء شخص جديد». | Terminology: one verb for tap (اضغط) instead of نقر; button name quoted |
| `smsImportPermissionPermanentDetail` | للسماح به، افتح معلومات التطبيق، ثم الأذونات، ثم الرسائل القصيرة، واختر سماح. ثم عد إلى دفتري. | للسماح به، افتح «معلومات التطبيق»، ثم «الأذونات»، ثم «الرسائل القصيرة»، واختر «السماح». ثم عد إلى دفتري. | On-screen labels quoted with Arabic guillemets «» (ASCII quotes in Step3) so button/setting names read as names |
| `smsImportRestrictedStep1` | 1. افتح معلومات التطبيق. | 1. افتح «معلومات التطبيق». | On-screen labels quoted with Arabic guillemets «» (ASCII quotes in Step3) so button/setting names read as names |
| `smsImportRestrictedStep3` | 3. اختر "السماح بالإعدادات المقيّدة". | 3. اختر «السماح بالإعدادات المقيّدة». | On-screen labels quoted with Arabic guillemets «» (ASCII quotes in Step3) so button/setting names read as names |
| `smsImportRestrictedStep4` | 4. عد إلى دفتري واضغط حاول مرة أخرى. | 4. عد إلى دفتري واضغط «حاول مرة أخرى». | On-screen labels quoted with Arabic guillemets «» (ASCII quotes in Step3) so button/setting names read as names |
| `smsImportPendingEmptyMessage` | تظهر هنا الرسائل البنكية التي تفحصها أو تلصقها أو تشاركها لتراجعها. لا يُحفظ شيء حتى تضغط إضافة. | تظهر هنا الرسائل البنكية التي تفحصها أو تلصقها أو تشاركها لتراجعها. لا يُحفظ شيء حتى تضغط «إضافة». | On-screen labels quoted with Arabic guillemets «» (ASCII quotes in Step3) so button/setting names read as names |
| `smsImportPasteIntro` | انسخ رسالة من البنك ثم اضغط لصق، أو الصقها في المربع بنفسك. لا يُحفظ شيء حتى تراجعها وتضغط إضافة. | انسخ رسالة من البنك ثم اضغط «لصق»، أو الصقها في المربع بنفسك. لا يُحفظ شيء حتى تراجعها وتضغط «إضافة». | On-screen labels quoted with Arabic guillemets «» (ASCII quotes in Step3) so button/setting names read as names |
| `smsImportEnableNever` | لا يتم رفع أي شيء، ولا يُحفظ أي شيء حتى تراجعه وتضغط إضافة. | لا يتم رفع أي شيء، ولا يُحفظ أي شيء حتى تراجعه وتضغط «إضافة». | On-screen labels quoted with Arabic guillemets «» (ASCII quotes in Step3) so button/setting names read as names |
| `smsImportSettingsPrivacyText` | تُقرأ الرسائل على هذا الجهاز فقط. لا يُحفظ أي شيء دون أن تضغط إضافة. | تُقرأ الرسائل على هذا الجهاز فقط. لا يُحفظ أي شيء دون أن تضغط «إضافة». | On-screen labels quoted with Arabic guillemets «» (ASCII quotes in Step3) so button/setting names read as names |
| `smsImportEnableTurnOff` | في أي وقت من الإعدادات ثم الرسائل البنكية. | في أي وقت من «الإعدادات» ثم «الرسائل البنكية». | On-screen labels quoted with Arabic guillemets «» (ASCII quotes in Step3) so button/setting names read as names |
| `smsImportIgnoredEmptyTitle` | لا شيء متجاهل مؤخرًا | لا توجد عناصر متجاهلة مؤخرًا | «لا شيء متجاهل» is awkward; «لا توجد عناصر متجاهلة» |
| `smsImportShareProcessing` | جارٍ قراءة الرسالة المشتركة… | جارٍ قراءة الرسالة التي تمت مشاركتها… | «المشتركة» means common/joint; «التي تمت مشاركتها» means shared |
| `smsImportErrorScanAlreadyRunning` | هناك فحص قيد التشغيل بالفعل. | هناك فحص جارٍ بالفعل. | Terminology: one verb for Scan (فحص/افحص) instead of mixing بحث and فحص; the Ignored copy named a button «فحص الآن» that read «ابحث الآن» |
| `smsImportPendingLoadErrorTitle` | تعذر تحميل رسائلك البنكية | تعذّر تحميل رسائلك البنكية | Consistency: تعذّر with shadda as in every other key |
| `smsImportReviewLoadErrorTitle` | تعذر فتح هذه الرسالة البنكية | تعذّر فتح هذه الرسالة البنكية | Consistency: تعذّر with shadda as in every other key |
| `smsImportMuteDone` | {count, plural, =0{تم كتم المرسل.} =1{تم كتم المرسل. أُزيل عنصر معلق واحد.} =2{تم كتم المرسل. أُزيل عنصران معلقان.} few{تم كتم المرسل. أُزيلت {count} عناصر معلقة.} many{تم كتم المرسل. أُزيل {count} عنصرًا معلقًا.} other{تم كتم المرسل. أُزيل {count} عنصر معلق.}} | {count, plural, =0{تم كتم المرسل.} =1{تم كتم المرسل. أُزيل عنصر معلّق واحد.} =2{تم كتم المرسل. أُزيل عنصران معلّقان.} few{تم كتم المرسل. أُزيلت {count} عناصر معلّقة.} many{تم كتم المرسل. أُزيل {count} عنصرًا معلّقًا.} other{تم كتم المرسل. أُزيل {count} عنصر معلّق.}} | Consistency: المعلّقة (pending) with shadda as in every other key |
| `smsImportMuteLoadError` | تعذر تحميل المرسلين المكتومين | تعذّر تحميل المرسلين المكتومين | Consistency: تعذّر with shadda as in every other key |
| `smsImportIgnoredLoadError` | تعذر تحميل العناصر المتجاهلة | تعذّر تحميل العناصر المتجاهلة | Consistency: تعذّر with shadda as in every other key |
| `smsImportSettingsTurnOffTitle` | هل تحذف العناصر المعلقة أيضًا؟ | هل تحذف العناصر المعلّقة أيضًا؟ | Consistency: المعلّقة (pending) with shadda as in every other key |
| `smsImportSettingsTurnOffMessage` | يتوقف استيراد الرسائل البنكية الآن. يمكن أن تبقى عناصرك المعلقة لتراجعها لاحقًا، أو أن تُحذف. لن تتغير المعاملات المحفوظة ولا المرسلون المكتومون ولا الفئات المتعلَّمة. | يتوقف استيراد الرسائل البنكية الآن. يمكن أن تبقى عناصرك المعلّقة لتراجعها لاحقًا، أو أن تُحذف. لن تتغير المعاملات المحفوظة ولا المرسلون المكتومون ولا الفئات المتعلَّمة. | Consistency: المعلّقة (pending) with shadda as in every other key |
| `smsImportSettingsTurnedOffKept` | تم الإيقاف. عناصرك المعلقة ما زالت هنا. | تم الإيقاف. عناصرك المعلّقة ما زالت هنا. | Consistency: المعلّقة (pending) with shadda as in every other key |
| `smsImportSettingsTurnedOffDeleted` | {count, plural, =0{تم الإيقاف. لم تكن هناك عناصر معلقة.} =1{تم الإيقاف. حُذف عنصر معلق واحد.} =2{تم الإيقاف. حُذف عنصران معلقان.} few{تم الإيقاف. حُذفت {count} عناصر معلقة.} many{تم الإيقاف. حُذف {count} عنصرًا معلقًا.} other{تم الإيقاف. حُذف {count} عنصر معلق.}} | {count, plural, =0{تم الإيقاف. لم تكن هناك عناصر معلّقة.} =1{تم الإيقاف. حُذف عنصر معلّق واحد.} =2{تم الإيقاف. حُذف عنصران معلّقان.} few{تم الإيقاف. حُذفت {count} عناصر معلّقة.} many{تم الإيقاف. حُذف {count} عنصرًا معلّقًا.} other{تم الإيقاف. حُذف {count} عنصر معلّق.}} | Consistency: المعلّقة (pending) with shadda as in every other key |

## Presentation fixes (minimal)

| File | Fix | Why |
|---|---|---|
| `pages/paste_bank_message_page.dart` | `_summaryText` built `"<recognized>. <skipped>."` with hard-coded `. ` punctuation between localized fragments. It now joins two whole localized lines with `\n`, as the result panel already does. | ui-contract §8.6: no concatenation of localized fragments. Arabic punctuation and order must not be glued in code. |
| `pages/import_review_page.dart` | The "Which amount?" chips' semantics label read the raw `formatMinor` value (`125.50`, no currency) while the chip showed the `CurrencyFormatter` amount. Both now use one `_candidateLabel` helper: `SmsImportLabels.money` (CurrencyFormatter, LTR-isolated) when the currency is known, and the bare decimal otherwise. | FR-090 / ui-contract §7.1: screen readers hear the same formatted amount as sighted users see. |

## Audit results (no change needed)

- **Amounts and dates**: every display path goes through `SmsImportLabels.money` (`CurrencyFormatter.formatWithSymbol`, Western digits, LRI/PDI isolate) or `SmsImportLabels.date` (`AppDateFormatter`). The message time uses `DateFormat.jm(numeralLocaleFor)` plus `NumeralParser.toWesternDigits`, as ui-contract §5 specifies. `formatMinor` is used only for the editable amount input and for a currency-less candidate.
- **List joins**: row and summary semantics join whole units with the localized `smsImportReviewListSeparator` (`، ` in AR). This is a list of complete values, not sentence assembly, so it was kept.
- **Announcements**:
  - Scan progress: `liveRegion` on the "Processed N" text in `ScanProgressPanel`. The total is unknown while paging, so the "25% steps" of ui-contract §7.5 can't be computed, and each count update is a polite live-region change instead.
  - Scan summary: `liveRegion` on the card, and `sendAnnouncement` on the enable page.
  - Paste result, Saving and Added: `sendAnnouncement`.
  - Possible duplicate: `sendAnnouncement`, **assertive**, in `ProbableDuplicateSheet`.
  - Ignored N, Restored, Unmuted, Learned removed/cleared, Turn off: `sendAnnouncement`.
  - Also live regions: the selection count, the scan failure and the expired notice.
- **Contrast and tokens**: there are no `Colors.*`, `Color(0x…)`, `withOpacity` or `withValues(alpha…)` in `sms_import/presentation` or `bank_messages_home_card.dart`. All colors come from `Theme.of(context).colorScheme` and the design tokens, and the light and dark themes are exercised by the matrix.
- **RTL**: no `EdgeInsets.only(left/right)`, `Alignment.centerLeft/Right` or `TextAlign.left/right` in the feature.

## New test

`test/features/sms_import/presentation/rtl_theme_test.dart` covers 10 screens × (ar RTL, en LTR) × (light, dark) at `TextScaler.linear(2.0)` on a 412×915 surface, for 40 tests. The screens are the hub, review, paste, enable, settings, ignored, muted senders, learned categories, the Home count card and the Home onboarding card. Each test asserts:

- no exception or overflow (`takeException`);
- the ambient `Directionality` matches the locale;
- the theme brightness matches the variant;
- the screen's key semantics:
  - hub: the row label has the type, and its hint is "Open to review";
  - review and paste: field labels;
  - Undo label;
  - unmute label with the sender;
  - learned row with the merchant;
  - Home count plural in semantics;
  - onboarding Dismiss.

It reuses `widget_harness.dart` (`pumpSmsPage`, `smsLocales`, `smsThemes`), `scan_presentation.dart`, `review_harness.dart` and the fakes. No helper was changed.

## Ambiguities and choices

1. **"Native Arabic review"** can't be done by an agent. I made a conservative copy pass and recorded every change above. The owner's review stays recommended.
2. **Scan verb**: بحث (search) and فحص (check/scan) were both in use. I chose فحص: it is the term for scanning the inbox, and «ابحث» clashes with a search feature.
3. **Discard**: Android Arabic often uses تجاهل for Discard, but the review screen also has an Ignore action with the same word. I chose «إلغاء التعديلات» to remove the ambiguity.
4. **English copy**: left unchanged. `Cancelled authorization` (kind label) is slightly technical. Its Arabic («إلغاء حجز مبلغ») is already plain, so I left the English as is. The owner may want to reword it.
5. `smsImportEnableWindowDays =0` (`آخر 0 يوم`) is unreachable (the window is 7/30/90), so I kept it.
6. No ARB keys were added or removed, so no placeholder or parity changes were needed.
