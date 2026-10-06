-- Draft wrap-ups follow the user's edits; AI regeneration is capped (#187).
--
-- `content` stays the assembled film (what the client plays). The AI-written
-- slice is now stored on its own so generate_wrap_up can rebuild a draft's
-- film from current photos/notes for free and only call Anthropic when the
-- AI's inputs change:
--   ai_fields            — invitation_line2, bridges, unlock_reason,
--                          keepsake_closing_quote (ai_fields.ts shape)
--   ai_input_hash        — SHA-256 of the AI inputs the fields were written
--                          from; NULL = unknown (backfilled rows), adopted on
--                          the next open without an AI call
--   ai_generation_count  — Anthropic calls spent on this memory; capped at 4
--                          (1 initial + 3 regenerations) in the function
--
-- A row with published_at set is frozen: the function returns it untouched.
--
-- Down/revert notes: `alter table public.wrap_ups drop column ai_fields,
-- drop column ai_input_hash, drop column ai_generation_count;` and recreate
-- "wrap_ups_update_own" without the published_at check.

alter table public.wrap_ups
  add column ai_fields jsonb,
  add column ai_input_hash text,
  add column ai_generation_count int not null default 0
    check (ai_generation_count >= 0);

-- Backfill: every generated wrap-up has already spent one Anthropic call.
-- The stored unlock.reason may be the achievement-description fallback
-- rather than AI text; carrying it over is harmless.
update public.wrap_ups
set
  ai_fields = jsonb_build_object(
    'invitation_line2', coalesce(content -> 'invitation' ->> 'line2', ''),
    'bridges', coalesce(content -> 'bridges', '["", "", ""]'::jsonb),
    'unlock_reason', content -> 'unlock' -> 'reason',
    'keepsake_closing_quote',
      coalesce(content -> 'keepsake' ->> 'closing_quote', '')
  ),
  ai_generation_count = 1
where content is not null;

-- The client may only ever set published_at (column-scoped grant from
-- create_wrap_ups, unchanged — the new columns stay service-role only).
-- The check also stops a client un-publishing a frozen wrap-up to get it
-- rebuilt.
drop policy "wrap_ups_update_own" on public.wrap_ups;

create policy "wrap_ups_update_own" on public.wrap_ups
for update to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
)
with check (
  published_at is not null
  and exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);
