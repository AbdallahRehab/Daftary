-- =============================================================================
-- 024: privileges for the tables 022 added
--
-- 022 created occasions, budgets and budget_category_allocations but only
-- revoked them from anon. Supabase default privileges had already granted
-- authenticated everything on them, including DELETE and TRUNCATE. RLS has no
-- DELETE policy, so DELETE was blocked, but TRUNCATE is not subject to RLS:
-- any signed-in user could empty these tables for every owner.
--
-- This applies 021's rule to them: authenticated gets DML only through RLS.
-- No DELETE (no physical deletes, 021 FR-015), no TRUNCATE (it bypasses RLS),
-- no TRIGGER/REFERENCES. The sync functions and the account-deletion cascade
-- are unaffected: they do not run as authenticated.
--
-- Applied migrations are never edited; this one only changes privileges.
-- =============================================================================

revoke all on
  public.occasions, public.budgets, public.budget_category_allocations
from anon, authenticated, public;

grant select, insert, update on
  public.occasions, public.budgets, public.budget_category_allocations
to authenticated;
