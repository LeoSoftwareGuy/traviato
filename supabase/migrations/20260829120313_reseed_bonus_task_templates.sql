-- Reseed bonus_task_templates for the daily-tray mechanic (docs/data-model.md
-- v4, docs/functionality.md §12). Replaces the 5-row seed from #27 with 35
-- templates shaped for reshape_bonus_tasks.sql's new columns. Part of #31.
--
-- Distribution: 21 anytime+middle (regular), 3 arrival (regular), 3
-- departure (regular), 1 starter, 3 stretch, 3 milestone, 1 streak_saver.
--
-- Down/revert notes: `delete from public.bonus_task_templates;` (re-seeding
-- the old 5-row set would require re-adding duration_hours/trigger first).

delete from public.bonus_task_templates;

insert into public.bonus_task_templates (code, title, detail, points, phase, kind)
values
  -- Anytime (regular)
  ('worst_photo_of_day', 'The worst photo of the day', 'Not your best angle. Not your best moment. That''s the point.', 2, 'anytime', 'regular'),
  ('something_free', 'Find something free', 'A view, a smell, a street performance — snap whatever cost you nothing today.', 1, 'anytime', 'regular'),
  ('local_snack', 'Try a snack you can''t get at home', 'Bonus points if you can''t pronounce it.', 2, 'anytime', 'regular'),
  ('menu_mystery', 'Order something you can''t translate', 'Point at the menu and commit.', 2, 'anytime', 'regular'),
  ('stranger_kindness', 'Capture a small kindness from a stranger', 'A wave, a smile, directions when you were lost.', 2, 'anytime', 'regular'),
  ('overheard', 'Photograph what you''re listening to', 'Street music, a language you don''t speak, the sound of somewhere new.', 1, 'anytime', 'regular'),
  ('souvenir_hunt', 'Photograph the tackiest souvenir you can find', 'You don''t have to buy it. Just admire it.', 1, 'anytime', 'regular'),
  ('sky_moment', 'Catch the sky doing something', 'Sunset, storm clouds, an unreasonable number of stars.', 2, 'anytime', 'regular'),
  ('local_transport', 'Document how you got around today', 'Bus, bike, boat, blistered feet — all valid.', 1, 'anytime', 'regular'),
  ('unexpected_detour', 'Snap a detour you didn''t plan', 'The wrong turn that turned out fine.', 2, 'anytime', 'regular'),
  ('color_hunt', 'Find the most colorful thing around you', 'A wall, a market stall, someone''s questionable fashion choice.', 1, 'anytime', 'regular'),
  ('closeup_texture', 'Get up close on a texture', 'Cobblestones, tree bark, the weird pattern on your hotel bedspread.', 1, 'anytime', 'regular'),
  ('reflection_shot', 'Catch a reflection', 'Water, glass, a suspiciously shiny spoon.', 2, 'anytime', 'regular'),

  -- Middle (regular)
  ('halfway_selfie', 'Take a halfway-there selfie', 'Tired eyes optional. Big smile mandatory.', 2, 'middle', 'regular'),
  ('local_hangout', 'Photograph where the locals actually hang out', 'Not the postcard spot — the real one.', 2, 'middle', 'regular'),
  ('comfort_food', 'Snap the meal that felt like home', 'Even a thousand miles from it.', 1, 'middle', 'regular'),
  ('new_skill', 'Try something you''ve never done before', 'A dance move, a dish, a language you''re butchering on purpose.', 3, 'middle', 'regular'),
  ('market_haul', 'Document a market or shop visit', 'What did you almost buy and talk yourself out of?', 1, 'middle', 'regular'),
  ('quiet_moment', 'Capture a quiet moment mid-trip', 'Not everything has to be a highlight reel.', 1, 'middle', 'regular'),
  ('view_from_bed', 'Photograph the view from where you''re staying', 'Balcony, window, or just a very honest ceiling.', 1, 'middle', 'regular'),
  ('unplanned_friend', 'Snap someone you met along the way', 'A new friend, a fellow traveler, a very opinionated local cat.', 2, 'middle', 'regular'),

  -- Arrival (regular)
  ('touchdown', 'Mark the moment you arrived', 'Airport sign, train platform, that first breath of new air.', 2, 'arrival', 'regular'),
  ('first_impression', 'Snap your very first impression', 'The view, the smell, the chaos — capture it before it becomes normal.', 2, 'arrival', 'regular'),
  ('unpacking_ritual', 'Photograph your unpacking ritual', 'However messy. However fast.', 1, 'arrival', 'regular'),

  -- Departure (regular)
  ('last_look', 'Take one last look before you go', 'The view, the room, the spot you''ll miss most.', 2, 'departure', 'regular'),
  ('farewell_meal', 'Capture your final meal here', 'Make it count — or make it whatever''s left in the fridge.', 1, 'departure', 'regular'),
  ('souvenir_final', 'Photograph what you''re bringing home', 'Physical or otherwise.', 2, 'departure', 'regular'),

  -- Starter
  ('snap_anything', 'Snap anything at all', 'Seriously. Anything. This one''s just to get you started.', 1, 'arrival', 'starter'),

  -- Stretch
  ('stranger_portrait', 'Ask a stranger if you can take their photo', 'Bonus vulnerability points. They''ll probably say yes.', 3, 'anytime', 'stretch'),
  ('no_phone_hour', 'Go an hour without checking your phone, then tell us what you noticed', 'Write it, don''t just remember it.', 3, 'anytime', 'stretch'),
  ('try_the_dare', 'Do the thing you keep talking yourself out of', 'You know the one.', 3, 'anytime', 'stretch'),

  -- Milestone
  ('milestone_week_one', 'One week in — how has this trip changed you already?', 'A photo and a moment of honesty.', 5, 'anytime', 'milestone'),
  ('milestone_two_weeks', 'Two weeks deep — what do you know now that you didn''t at the start?', 'Capture the moment it clicked.', 5, 'anytime', 'milestone'),
  ('milestone_three_weeks', 'Three weeks out — what will you miss most when this ends?', 'Say it before you have to.', 5, 'anytime', 'milestone'),

  -- Streak-saver
  ('streak_saver_checkin', 'Just check in', 'No pressure, no theme — one photo of wherever you are right now.', 2, 'anytime', 'streak_saver');
