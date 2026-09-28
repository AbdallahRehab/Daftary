# Definition of Done: 021 Offline-First Cloud Sync

**Date**: 2026-09-27 · **Branch**: `021-supabase-offline-sync` · **Source**: plan.md §26

| Requirement | Status | Evidence |
| --- | --- | --- |
| The app works offline | ✅ | All 11 existing integration flows pass on the simulator after the T043 fixes (`7ea54c2`), which include 2 app bugs from before 021 |
| Data persists locally | ✅ | `outbox_persistence_test`, `sync_bootstrap_test`, T062 scenario 1 (restart) |
| Offline changes are queued | ✅ | `dao_outbox_guard_test` (every DAO write), `table_classification_guard_test` |
| Reconnecting triggers sync | ✅ | `sync_scheduler_test` (offline→online, flapping, single-flight) |
| Supabase receives the changes | ✅ | T062 scenarios 1–3 on the simulator against local Supabase |
| Remote changes reach the local DB | ✅ | `sync_applier_test`, `sync_engine_pull_test` |
| The UI updates automatically | ✅ | `person_detail_remote_update_test`, the Cubit `bloc_test`s (T033–T040) |
| No duplicate financial records | ✅ | `021_sync_push.test.sql`, `sync_engine_push_test`, T062 scenario 5 (0 duplicate idempotency keys) |
| Conflicts are handled safely | ✅ | `sync_engine_conflict_test` (two devices), `conflict_resolver_test` |
| Existing data is preserved | ✅ | `sync_v9_migration_test`, `sync_bootstrap_test` (overview identical before and after) |
| RLS protects user data | ✅ | 241 pgTAP assertions locally. Deployed live: all 11 tables have RLS, anon has 0 grants, the advisors are clean except intended warnings, and the security review is done (T089). |
| Android works | ◐ Builds only | Debug and release APKs build. Not yet run on a device. |
| iOS works | ◐ Builds + simulator | The release build succeeds, and T062 passes on the simulator. Not yet run on a physical device. |
| All tests pass | ✅ | `flutter analyze` 0 issues · `flutter test` 1761/1761 · `supabase test db` 241/241 · 11/11 integration flows |

## Remaining before sign-off (T091 stays open)

1. **T087 / T088**: run quickstart scenarios 1–10 on a physical Android device and a physical iPhone, including the upgrade from the previous release. The user chose to keep automated runs on the simulator, so these are manual checks.
2. **Email one-time codes**: the free tier blocks custom templates with the default sender. Configure custom SMTP, then push the `{{ .Token }}` templates. Until then, "Link email" sends a magic link. Anonymous backup and sync are not affected.
3. **Performance check (from the T043 follow-up)**: the scroll-performance integration test uses a looser limit in debug builds. Confirm it in a profile build on real hardware.
