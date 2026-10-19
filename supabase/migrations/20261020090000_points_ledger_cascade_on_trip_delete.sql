-- #247: deleting a memory now removes the stars it earned, matching the
-- delete sheet's "Your earned stars are lost". The ledger's trip link moves
-- from `on delete set null` to `on delete cascade`, so the memory's rows go
-- with it and every SUM over the ledger (profile_stats_view.stars_total,
-- trip_card_view.stars, check_achievements) drops on its own.
--
-- Kept as they are:
--   - Rows already orphaned by earlier deletes (trip_id NULL): those memories
--     were deleted under the old "stars are kept" promise.
--   - Unlocked achievements: user_achievements doesn't reference the ledger.
--
-- Revert:
--   alter table public.points_ledger drop constraint points_ledger_trip_id_fkey;
--   alter table public.points_ledger add constraint points_ledger_trip_id_fkey
--     foreign key (trip_id) references public.trips (id) on delete set null;

alter table public.points_ledger drop constraint points_ledger_trip_id_fkey;

alter table public.points_ledger
  add constraint points_ledger_trip_id_fkey
  foreign key (trip_id) references public.trips (id) on delete cascade;
