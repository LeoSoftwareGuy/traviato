import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hard-coded `Text('…')` literals still waiting to move into the ARB files
/// (#220), counted per file. Each localization PR lowers or removes its
/// files' entries; the test fails if a file gains literals or a new file
/// starts using them. User content is never a literal, so the target is an
/// empty map.
const _baseline = <String, int>{
  'lib/features/auth/presentation/pages/auth_page.dart': 5,
  'lib/features/auth/presentation/pages/guest_landing_page.dart': 7,
  'lib/features/auth/presentation/widgets/confirm_email_card.dart': 4,
  'lib/features/auth/presentation/widgets/how_it_works_section.dart': 1,
  'lib/features/auth/presentation/widgets/sample_memories_scroller.dart': 2,
  'lib/features/auth/presentation/widgets/social_sign_in_buttons.dart': 3,
  'lib/features/bonus/presentation/pages/bonus_tasks_empty_page.dart': 4,
  'lib/features/bonus/presentation/pages/bonus_tasks_page.dart': 3,
  'lib/features/bonus/presentation/widgets/bonus_earned_banner.dart': 2,
  'lib/features/bonus/presentation/widgets/bonus_task_popup_sheet.dart': 3,
  'lib/features/bonus/presentation/widgets/bonus_task_tile.dart': 1,
  'lib/features/bonus/presentation/widgets/stretch_offer_card.dart': 2,
  'lib/features/checklist/presentation/pages/checklist_page.dart': 3,
  'lib/features/checklist/presentation/widgets/add_checklist_item_input.dart':
      1,
  'lib/features/checklist/presentation/widgets/category_tabs.dart': 1,
  'lib/features/checklist/presentation/widgets/checklist_item_tile.dart': 1,
  'lib/features/checklist/presentation/widgets/checklist_progress_bar.dart': 1,
  'lib/features/expense/presentation/pages/expense_compare_page.dart': 6,
  'lib/features/expense/presentation/pages/expenses_page.dart': 12,
  'lib/features/expense/presentation/widgets/add_expense_sheet.dart': 6,
  'lib/features/expense/presentation/widgets/expense_biggest_category_card.dart':
      3,
  'lib/features/expense/presentation/widgets/expense_category_breakdown.dart':
      1,
  'lib/features/expense/presentation/widgets/expense_compare_table.dart': 3,
  'lib/features/expense/presentation/widgets/expense_empty_selection_panel.dart':
      3,
  'lib/features/expense/presentation/widgets/expense_trip_selector.dart': 1,
  'lib/features/home/presentation/pages/home_page.dart': 5,
  'lib/features/home/presentation/widgets/coming_up_section.dart': 2,
  'lib/features/home/presentation/widgets/home_header.dart': 2,
  'lib/features/home/presentation/widgets/home_stats_bar.dart': 1,
  'lib/features/home/presentation/widgets/memories_grid_section.dart': 3,
  'lib/features/home/presentation/widgets/upcoming_hero_card.dart': 2,
  'lib/features/journal/presentation/pages/journal_page.dart': 2,
  'lib/features/journal/presentation/pages/note_page.dart': 3,
  'lib/features/journal/presentation/widgets/day_note_card.dart': 2,
  'lib/features/journal/presentation/widgets/empty_day_nudge.dart': 4,
  'lib/features/journal/presentation/widgets/journal_action_buttons.dart': 3,
  'lib/features/journal/presentation/widgets/journal_header.dart': 2,
  'lib/features/journal/presentation/widgets/note_page/note_dock.dart': 3,
  'lib/features/journal/presentation/widgets/note_page/note_writing_page.dart':
      2,
  'lib/features/journal/presentation/widgets/photos_strip.dart': 3,
  'lib/features/journal/presentation/widgets/to_do_sheet.dart': 1,
  'lib/features/journal/presentation/widgets/wrap_up_explainer_card.dart': 3,
  'lib/features/notifications/presentation/widgets/notification_permission_prompt.dart':
      4,
  'lib/features/photo/presentation/pages/photo_viewer_page.dart': 1,
  'lib/features/photo/presentation/widgets/add_photo_sheet.dart': 3,
  'lib/features/photo/presentation/widgets/batch_add_photo_sheet.dart': 6,
  'lib/features/photo/presentation/widgets/location_permission_prompt.dart': 4,
  'lib/features/profile/presentation/pages/profile_page.dart': 1,
  'lib/features/profile/presentation/widgets/achievements_grid.dart': 2,
  'lib/features/profile/presentation/widgets/avatar_upload_tile.dart': 1,
  'lib/features/profile/presentation/widgets/profile_edit_sheet.dart': 4,
  'lib/features/profile/presentation/widgets/profile_header.dart': 4,
  'lib/features/profile/presentation/widgets/profile_stats_row.dart': 1,
  'lib/features/profile/presentation/widgets/profile_top_bar.dart': 1,
  'lib/features/profile/presentation/widgets/subscription_section.dart': 5,
  'lib/features/quest/presentation/pages/plan_page.dart': 2,
  'lib/features/quest/presentation/widgets/add_edit_quest_sheet.dart': 3,
  'lib/features/quest/presentation/widgets/manage_memory_sheet.dart': 6,
  'lib/features/quest/presentation/widgets/plan_header.dart': 3,
  'lib/features/subscription/presentation/pages/paywall_page.dart': 9,
  'lib/features/trip/presentation/pages/create_memory_page.dart': 6,
  'lib/features/trip/presentation/widgets/cover_picker.dart': 3,
  'lib/features/trip/presentation/widgets/cover_upload_tile.dart': 1,
  'lib/features/trip/presentation/widgets/delete_memory_sheet.dart': 3,
  'lib/features/trip/presentation/widgets/vibe_chip_group.dart': 2,
  'lib/features/wrap_up/presentation/film/frames/wrap_up_film_footnote.dart': 1,
  'lib/features/wrap_up/presentation/film/frames/wrap_up_film_keepsake.dart': 2,
  'lib/features/wrap_up/presentation/film/frames/wrap_up_film_unlock.dart': 1,
  'lib/features/wrap_up/presentation/film/wrap_up_film_hud.dart': 3,
  'lib/features/wrap_up/presentation/widgets/wrap_up_generating_view.dart': 1,
};

final _literalText = RegExp(r'''Text\(\s*['"]''');

void main() {
  test('no new hard-coded Text literals in lib/features', () {
    final offenders = <String>[];
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      final count = _literalText.allMatches(file.readAsStringSync()).length;
      final allowed = _baseline[path] ?? 0;
      if (count > allowed) {
        offenders.add('$path: $count literal Text(…) (allowed $allowed)');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Move UI strings into lib/l10n/app_en.arb (+ ru/et) and use '
          'context.l10n instead of Text(\'…\').',
    );
  });

  test('baseline only lists files that still have literals', () {
    final stale = <String>[];
    for (final MapEntry(key: path, value: allowed) in _baseline.entries) {
      final file = File(path);
      final count = file.existsSync()
          ? _literalText.allMatches(file.readAsStringSync()).length
          : 0;
      if (count < allowed) stale.add('$path: now $count (baseline $allowed)');
    }
    expect(
      stale,
      isEmpty,
      reason: 'Lower these baseline entries so the guard stays tight.',
    );
  });
}
