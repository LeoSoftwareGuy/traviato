-- #294 (part 1): the user decides, per photo, whether the Wrap-Up Film uses
-- it. Three states in one nullable column:
--   null  = Auto      — the generator decides (every existing row)
--   true  = Always    — gets a main moment (M1–M8) before automatic picks
--   false = Leave out — never appears anywhere in the film
-- data-model.md planned `use_in_wrap_up bool default false`, but no
-- migration ever created it, so there are no existing values to map.
--
-- use_in_wrap_up_set_at records when the pick last changed. The app
-- compares it with wrap_ups.generated_at to tell a kept film that its
-- photos changed (both are server time). Set by the trigger below, never
-- by the client, so it can't drift with the phone's clock.
--
-- Written by the owner with a plain update (photos_update_own + the
-- existing table-level update grant). Read by generate_wrap_up through the
-- service role's existing select grant.
--
-- Down/revert notes: `drop trigger photos_stamp_use_in_wrap_up on
-- public.photos; drop function public.stamp_photo_use_in_wrap_up();
-- alter table public.photos drop column use_in_wrap_up_set_at, drop column
-- use_in_wrap_up;`

alter table public.photos
  add column use_in_wrap_up boolean,
  add column use_in_wrap_up_set_at timestamptz;

create function public.stamp_photo_use_in_wrap_up()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.use_in_wrap_up is distinct from old.use_in_wrap_up then
    new.use_in_wrap_up_set_at := now();
  else
    -- Only a real pick change moves the stamp.
    new.use_in_wrap_up_set_at := old.use_in_wrap_up_set_at;
  end if;
  return new;
end;
$$;

create trigger photos_stamp_use_in_wrap_up
before update on public.photos
for each row
execute function public.stamp_photo_use_in_wrap_up();
