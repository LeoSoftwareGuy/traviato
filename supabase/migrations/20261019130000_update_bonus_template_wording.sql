-- #248: the English bonus-task copy was reworded in the app (8411ad7);
-- bring the seeded English in line so the DB stays the source of truth for
-- English (#243). Only text changes: codes, points, phases and kinds don't.
--
-- Revert: set each field back to its text in
-- 20260829120313_reseed_bonus_task_templates.sql.

update public.bonus_task_templates set detail = 'A view, a smile, a street performance: snap whatever cost you nothing today.' where code = 'something_free';
update public.bonus_task_templates set detail = 'Not the postcard spot but the real one.' where code = 'local_hangout';
update public.bonus_task_templates set detail = 'The view, the smell, the chaos just capture it before it becomes normal.' where code = 'first_impression';
update public.bonus_task_templates set detail = 'Make it count or make it whatever''s left in the fridge.' where code = 'farewell_meal';
update public.bonus_task_templates set title = 'One week in. How has this trip changed you already?' where code = 'milestone_week_one';
update public.bonus_task_templates set title = 'Two weeks deep. What do you know now that you didn''t at the start?' where code = 'milestone_two_weeks';
update public.bonus_task_templates set title = 'Three weeks out. What will you miss most when this ends?' where code = 'milestone_three_weeks';
update public.bonus_task_templates set detail = 'No pressure, no theme just one photo of wherever you are right now.' where code = 'streak_saver_checkin';
