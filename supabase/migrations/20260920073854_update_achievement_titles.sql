-- Rename 4 of the 8 seeded achievement titles to punchier copy (codes/targets
-- unchanged, so this doesn't affect check_achievements() or any earned rows).
--
-- Down/revert notes:
--   update public.achievement_templates set title = 'Globetrotter' where code = 'globetrotter';
--   update public.achievement_templates set title = 'Century' where code = 'century';
--   update public.achievement_templates set title = 'Shutterbug' where code = 'shutterbug';
--   update public.achievement_templates set title = 'Jetsetter' where code = 'jetsetter';

update public.achievement_templates set title = 'World Wanderer' where code = 'globetrotter';
update public.achievement_templates set title = '100 Days Deep' where code = 'century';
update public.achievement_templates set title = 'Say Cheese' where code = 'shutterbug';
update public.achievement_templates set title = 'Wanderlust Certified' where code = 'jetsetter';
