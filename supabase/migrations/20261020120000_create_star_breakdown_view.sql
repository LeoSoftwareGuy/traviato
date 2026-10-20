-- star_breakdown_view (#219): the Bonus page's star summary when no tray
-- is open today — totals by source type, then by memory — in one read.
--
-- Down/revert notes: `drop view public.star_breakdown_view;`
--
-- One row per (user, memory, source). trip_id is NULL only for rows
-- orphaned before #247 made the ledger cascade on memory delete; the app
-- folds those into an "Earlier memories" row. security_invoker keeps the
-- ledger's own owner-only RLS in force, so a caller only ever sees their
-- own rows.

create view public.star_breakdown_view
with (security_invoker = true) as
select
  pl.user_id,
  pl.trip_id,
  pl.source,
  count(*)::int as entry_count,
  sum(pl.points)::int as points_total
from public.points_ledger pl
group by pl.user_id, pl.trip_id, pl.source;

grant select on public.star_breakdown_view to authenticated;
