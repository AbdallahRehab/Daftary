# Spike S1: share launch path and MainActivity instance count (T010)

**Status: NOT RUN — device required.** This environment has no physical device or emulator. Nothing below was observed. T010 stays unchecked.

## Question

With Daftary in the background, sharing text from Google Messages to Daftary through the `ShareTargetActivity` trampoline: does exactly one `MainActivity` instance (and so one `FlutterEngine`) exist afterwards?

## Default approach (already designated; adopted as the primary choice)

Source: research.md Decision 4, contracts/sms-platform-channel.md §2.5 and §2.6, plan.md Unresolved Risk 4.

- A dedicated translucent `ShareTargetActivity` (`exported="true"`, `noHistory`, `excludeFromRecents`, `@style/Theme.Translucent`) carries the only `ACTION_SEND` + `text/plain` intent filter, in every build.
- `onCreate` reads `EXTRA_TEXT` as `CharSequence`, truncates at 10,001 characters, stores it in the in-process `SharedTextHolder` (never an Intent extra), starts `MainActivity` with `FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_CLEAR_TOP | FLAG_ACTIVITY_SINGLE_TOP`, then calls `finish()`.
- `MainActivity` keeps `launchMode="singleTop"` and `taskAffinity=""` (`android/app/src/main/AndroidManifest.xml:38-39`), unchanged.
- Cold start: `getInitialSharedText` drains the holder once. Warm start: the holder pushes to the `com.daftary.daftary/sms/shared_text` EventChannel, or buffers one pending event.

The trampoline is the baseline whatever S1 finds; S1 only confirms the instance count.

## Fallback (if a device shows a second MainActivity)

1. First check whether the OEM ignores `CLEAR_TOP|SINGLE_TOP` on a `NEW_TASK` start from a `taskAffinity=""` activity. Try adding `FLAG_ACTIVITY_REORDER_TO_FRONT` instead of `CLEAR_TOP` in the trampoline only. `MainActivity` stays untouched.
2. Do **not** switch `MainActivity` to `singleTask`. Research Decision 4 rejects it because of the notification-tap and cold-start regression risk.
3. If no flag combination gives one instance on the affected OEM, record the OEM as a known limitation. The second instance does not bypass App Lock (cold launch locks), but it does carry the two-engine/two-Drift-connection hazard, so the share path on that OEM would need a separate decision by the owner.

## What must be verified on a device

| # | Check | Expected |
|---|---|---|
| 1 | Daftary launched, sent to background (Home), then share one message from Google Messages → Daftary | Paste screen opens with the text (after unlock if App Lock is on) |
| 2 | `adb shell dumpsys activity activities \| grep -E "MainActivity\|ShareTargetActivity"` after step 1 | Exactly one `MainActivity` record; no live `ShareTargetActivity` |
| 3 | Same as 1, but Daftary process killed first (cold start) | Text is delivered once via `getInitialSharedText`; rotating the device or process restore does not replay it |
| 4 | Same as 1 with App Lock enabled and the lock timeout elapsed | Lock screen first; text parsed only after unlock |
| 5 | Notification tap after a share | Still opens in the single existing task (no regression) |
| 6 | Recents screen | No separate Daftary task inside the Messages task |

Devices to cover: one Pixel (stock), one Samsung (One UI), one Egyptian-market OEM (e.g. Xiaomi/Oppo/Realme/Infinix), Android 13-16. Record the device, OS version and the observed instance count for each.

## Result

Not available. To be filled in on a device run.
