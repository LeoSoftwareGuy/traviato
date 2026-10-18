import '../../../../core/l10n/context_l10n.dart';
import '../../domain/entities/bonus_task_template_entity.dart';

// Generated from the seeded `bonus_task_templates` (#243). Keep the codes in
// step with supabase/migrations; an unknown code falls back to the DB text.

/// A bonus task's title in the UI language.
String bonusTemplateTitle(AppLocalizations l10n, BonusTaskTemplateEntity t) =>
    _title(l10n, t.code) ?? t.title;

/// A bonus task's detail line in the UI language (or `null` if it has none).
String? bonusTemplateDetail(AppLocalizations l10n, BonusTaskTemplateEntity t) =>
    t.detail == null ? null : _detail(l10n, t.code) ?? t.detail;

String? _title(AppLocalizations l10n, String code) => switch (code) {
  'worst_photo_of_day' => l10n.content_bonus_worst_photo_of_day_title,
  'something_free' => l10n.content_bonus_something_free_title,
  'local_snack' => l10n.content_bonus_local_snack_title,
  'menu_mystery' => l10n.content_bonus_menu_mystery_title,
  'stranger_kindness' => l10n.content_bonus_stranger_kindness_title,
  'overheard' => l10n.content_bonus_overheard_title,
  'souvenir_hunt' => l10n.content_bonus_souvenir_hunt_title,
  'sky_moment' => l10n.content_bonus_sky_moment_title,
  'local_transport' => l10n.content_bonus_local_transport_title,
  'unexpected_detour' => l10n.content_bonus_unexpected_detour_title,
  'color_hunt' => l10n.content_bonus_color_hunt_title,
  'closeup_texture' => l10n.content_bonus_closeup_texture_title,
  'reflection_shot' => l10n.content_bonus_reflection_shot_title,
  'halfway_selfie' => l10n.content_bonus_halfway_selfie_title,
  'local_hangout' => l10n.content_bonus_local_hangout_title,
  'comfort_food' => l10n.content_bonus_comfort_food_title,
  'new_skill' => l10n.content_bonus_new_skill_title,
  'market_haul' => l10n.content_bonus_market_haul_title,
  'quiet_moment' => l10n.content_bonus_quiet_moment_title,
  'view_from_bed' => l10n.content_bonus_view_from_bed_title,
  'unplanned_friend' => l10n.content_bonus_unplanned_friend_title,
  'touchdown' => l10n.content_bonus_touchdown_title,
  'first_impression' => l10n.content_bonus_first_impression_title,
  'unpacking_ritual' => l10n.content_bonus_unpacking_ritual_title,
  'last_look' => l10n.content_bonus_last_look_title,
  'farewell_meal' => l10n.content_bonus_farewell_meal_title,
  'souvenir_final' => l10n.content_bonus_souvenir_final_title,
  'snap_anything' => l10n.content_bonus_snap_anything_title,
  'snap_suitecase' => l10n.content_bonus_snap_suitecase_title,
  'stranger_portrait' => l10n.content_bonus_stranger_portrait_title,
  'no_phone_hour' => l10n.content_bonus_no_phone_hour_title,
  'try_the_dare' => l10n.content_bonus_try_the_dare_title,
  'milestone_week_one' => l10n.content_bonus_milestone_week_one_title,
  'milestone_two_weeks' => l10n.content_bonus_milestone_two_weeks_title,
  'milestone_three_weeks' => l10n.content_bonus_milestone_three_weeks_title,
  'streak_saver_checkin' => l10n.content_bonus_streak_saver_checkin_title,
  _ => null,
};

String? _detail(AppLocalizations l10n, String code) => switch (code) {
  'worst_photo_of_day' => l10n.content_bonus_worst_photo_of_day_detail,
  'something_free' => l10n.content_bonus_something_free_detail,
  'local_snack' => l10n.content_bonus_local_snack_detail,
  'menu_mystery' => l10n.content_bonus_menu_mystery_detail,
  'stranger_kindness' => l10n.content_bonus_stranger_kindness_detail,
  'overheard' => l10n.content_bonus_overheard_detail,
  'souvenir_hunt' => l10n.content_bonus_souvenir_hunt_detail,
  'sky_moment' => l10n.content_bonus_sky_moment_detail,
  'local_transport' => l10n.content_bonus_local_transport_detail,
  'unexpected_detour' => l10n.content_bonus_unexpected_detour_detail,
  'color_hunt' => l10n.content_bonus_color_hunt_detail,
  'closeup_texture' => l10n.content_bonus_closeup_texture_detail,
  'reflection_shot' => l10n.content_bonus_reflection_shot_detail,
  'halfway_selfie' => l10n.content_bonus_halfway_selfie_detail,
  'local_hangout' => l10n.content_bonus_local_hangout_detail,
  'comfort_food' => l10n.content_bonus_comfort_food_detail,
  'new_skill' => l10n.content_bonus_new_skill_detail,
  'market_haul' => l10n.content_bonus_market_haul_detail,
  'quiet_moment' => l10n.content_bonus_quiet_moment_detail,
  'view_from_bed' => l10n.content_bonus_view_from_bed_detail,
  'unplanned_friend' => l10n.content_bonus_unplanned_friend_detail,
  'touchdown' => l10n.content_bonus_touchdown_detail,
  'first_impression' => l10n.content_bonus_first_impression_detail,
  'unpacking_ritual' => l10n.content_bonus_unpacking_ritual_detail,
  'last_look' => l10n.content_bonus_last_look_detail,
  'farewell_meal' => l10n.content_bonus_farewell_meal_detail,
  'souvenir_final' => l10n.content_bonus_souvenir_final_detail,
  'snap_anything' => l10n.content_bonus_snap_anything_detail,
  'snap_suitecase' => l10n.content_bonus_snap_suitecase_detail,
  'stranger_portrait' => l10n.content_bonus_stranger_portrait_detail,
  'no_phone_hour' => l10n.content_bonus_no_phone_hour_detail,
  'try_the_dare' => l10n.content_bonus_try_the_dare_detail,
  'milestone_week_one' => l10n.content_bonus_milestone_week_one_detail,
  'milestone_two_weeks' => l10n.content_bonus_milestone_two_weeks_detail,
  'milestone_three_weeks' => l10n.content_bonus_milestone_three_weeks_detail,
  'streak_saver_checkin' => l10n.content_bonus_streak_saver_checkin_detail,
  _ => null,
};
