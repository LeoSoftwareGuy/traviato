-- #236 (localization epic #220): the user's UI-language choice, so it
-- follows them across devices and server-side work (wrap-up generation,
-- later push) knows their language.
--
-- NULL = "System default" (follow the device). Only the app's supported
-- locales are allowed. Covered by the existing table-level
-- `grant select, update on public.profiles to authenticated` and the
-- `profiles_select_own` / `profiles_update_own` policies, so no new grant
-- or policy is needed.
--
-- Revert: alter table public.profiles drop column language;

alter table public.profiles
  add column language text
  constraint profiles_language_check check (language in ('en', 'ru', 'et'));

comment on column public.profiles.language is
  'UI language: en | ru | et; NULL follows the device (System default).';
