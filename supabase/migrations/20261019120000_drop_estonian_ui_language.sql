-- #245 (localization epic #220): the UI ships in English and Russian only;
-- Estonian users read the app in English. Estonian stays a dictation
-- language, so profiles.dictation_language keeps 'et'.
--
-- A UI choice of 'et' becomes NULL ("System default"), which the app
-- resolves to English on an Estonian phone.
--
-- Revert:
--   alter table public.profiles drop constraint profiles_language_check;
--   alter table public.profiles add constraint profiles_language_check
--     check (language in ('en', 'ru', 'et'));
--   (the cleared 'et' values aren't restored)

update public.profiles set language = null where language = 'et';

alter table public.profiles drop constraint profiles_language_check;

alter table public.profiles
  add constraint profiles_language_check check (language in ('en', 'ru'));

comment on column public.profiles.language is
  'UI language: en | ru; NULL follows the device (System default).';
