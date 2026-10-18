-- #218 (localization epic #220): the user's last-used dictation (speech)
-- language, kept separately from the UI language — an Estonian UI with
-- Russian notes is a normal case.
--
-- NULL = not chosen yet (the app picks a default). Same shape and access
-- as `profiles.language` (#236): covered by the existing table-level
-- `grant select, update on public.profiles to authenticated` and the
-- own-row `profiles_select_own` / `profiles_update_own` policies.
--
-- Revert: alter table public.profiles drop column dictation_language;

alter table public.profiles
  add column dictation_language text
  constraint profiles_dictation_language_check
    check (dictation_language in ('en', 'ru', 'et'));

comment on column public.profiles.dictation_language is
  'Last-used dictation language: en | ru | et; NULL = not chosen yet.';
