-- #406: drop the old one-note-per-day table.
--
-- #400 copied every non-empty day_notes row into journal_notes as a legacy
-- note with the same id and made day_notes read-only for one release. No
-- function, view or edge function reads it any more (checked against the
-- replayed schema: only its own policies depended on it), so it goes,
-- with its policies, index and updated_at trigger.
--
-- Revert: recreate it from 20260820154535_create_day_notes_and_photos.sql;
-- its rows are not restorable from here (journal_notes keeps their text).

drop table public.day_notes;
