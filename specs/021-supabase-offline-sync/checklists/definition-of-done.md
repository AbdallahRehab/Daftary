# Definition of Done: 021 Offline-First Cloud Sync

**Date**: 2026-09-27 · **Branch**: `021-supabase-offline-sync` · **Source**: plan.md §26

| Requirement | Status | Evidence |
| --- | --- | --- |
| The app works offline | ✅ No regressions | 5 of the 11 existing flows pass. The other 6 fail identically on pre-021 `fbce88f`, so the failures are pre-existing test and environment issues (baseline.md, T043). |
| Data persists locally | ✅ | `outbox_persistence_test`, `sync_bootstrap_test`, T062 scenario 1 (restart) |
| Offline changes are queued | ✅ | `dao_outbox_guard_test` (every DAO write), `table_classification_guard_test` |
| Reconnecting triggers sync | ✅ | `sync_scheduler_test` (offline→online, flapping, single-flight) |
| Supabase receives the changes | ✅ | T062 scenarios 1–3 on the simulator against local Supabase |
| Remote changes reach the local DB | ✅ | `sync_applier_test`, `sync_engine_pull_test` |
| The UI updates automatically | ✅ | `person_detail_remote_update_test`, the Cubit `bloc_test`s (T033–T040) |
| No duplicate financial records | ✅ | `021_sync_push.test.sql`, `sync_engine_push_test`, T062 scenario 5 (0 duplicate idempotency keys) |
| Conflicts are handled safely | ✅ | `sync_engine_conflict_test` (two devices), `conflict_resolver_test` |
| Existing data is preserved | ✅ | `sync_v9_migration_test`, `sync_bootstrap_test` (overview identical before and after) |
| RLS protects user data | ✅ locally | `021_rls.test.sql`, `021_views.test.sql`, `021_revision_guard.test.sql` (203 pgTAP assertions). The remote project is not deployed yet (T050). |
| Android works | ◐ Builds only | Debug and release APKs build. Not yet run on a device. |
| iOS works | ◐ Builds + simulator | The release build succeeds, and T062 passes on the simulator. Not yet run on a physical device. |
| All tests pass | ✅ | `flutter analyze` 0 issues · `flutter test` 1758/1758 · `supabase test db` 203/203 |

## Remaining before sign-off (T091 stays open)

1. **T050 (manual, needs the user)**:
   - `supabase link --project-ref nnrmghwqihqnmtnuxzoq`, then `supabase db push`. The database password is entered at the prompt.
   - In the dashboard: enable anonymous sign-ins, and set the email templates to a one-time code.
   - Create a local `config/supabase.dev.json` with the publishable key.
   - Pushing also completes the deploy steps of **T066** and **T082**.
2. **T087 / T088**: run quickstart scenarios 1–10 on a physical Android device and a physical iPhone, including the upgrade from the previous release.
3. **T089**: run the remote Security Advisor after T050, and run `/security-review` on the branch.
4. **T043**: the 6 pre-existing integration-flow failures are outside 021's scope. Track them as a separate fix.
