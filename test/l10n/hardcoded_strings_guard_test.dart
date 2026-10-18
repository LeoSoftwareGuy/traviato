import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hard-coded `Text('…')` literals still waiting to move into the ARB files
/// (#220), counted per file. Each localization PR lowers or removes its
/// files' entries; the test fails if a file gains literals or a new file
/// starts using them. User content is never a literal, so the target is an
/// empty map.
const _baseline = <String, int>{
  'lib/features/bonus/presentation/pages/bonus_tasks_empty_page.dart': 3,
  'lib/features/bonus/presentation/pages/bonus_tasks_page.dart': 3,
  'lib/features/bonus/presentation/widgets/bonus_earned_banner.dart': 2,
  'lib/features/bonus/presentation/widgets/bonus_task_popup_sheet.dart': 3,
  'lib/features/bonus/presentation/widgets/bonus_task_tile.dart': 1,
  'lib/features/bonus/presentation/widgets/stretch_offer_card.dart': 2,
  'lib/features/checklist/presentation/widgets/category_tabs.dart': 1,
  'lib/features/expense/presentation/pages/expense_compare_page.dart': 6,
  'lib/features/expense/presentation/pages/expenses_page.dart': 10,
  'lib/features/expense/presentation/widgets/add_expense_sheet.dart': 6,
  'lib/features/expense/presentation/widgets/expense_biggest_category_card.dart':
      2,
  'lib/features/expense/presentation/widgets/expense_category_breakdown.dart':
      1,
  'lib/features/expense/presentation/widgets/expense_compare_table.dart': 2,
  'lib/features/expense/presentation/widgets/expense_empty_selection_panel.dart':
      2,
  'lib/features/expense/presentation/widgets/expense_trip_selector.dart': 1,
  'lib/features/home/presentation/widgets/home_header.dart': 1,
  'lib/features/home/presentation/widgets/home_stats_bar.dart': 1,
  'lib/features/journal/presentation/widgets/journal_header.dart': 1,
  'lib/features/journal/presentation/widgets/note_page/note_dock.dart': 1,
  'lib/features/journal/presentation/widgets/wrap_up_explainer_card.dart': 1,
  'lib/features/notifications/presentation/widgets/notification_permission_prompt.dart':
      3,
  'lib/features/profile/presentation/pages/profile_page.dart': 1,
  'lib/features/profile/presentation/widgets/achievements_grid.dart': 2,
  'lib/features/profile/presentation/widgets/avatar_upload_tile.dart': 1,
  'lib/features/profile/presentation/widgets/profile_edit_sheet.dart': 4,
  'lib/features/profile/presentation/widgets/profile_header.dart': 4,
  'lib/features/profile/presentation/widgets/profile_stats_row.dart': 1,
  'lib/features/profile/presentation/widgets/profile_top_bar.dart': 1,
  'lib/features/profile/presentation/widgets/subscription_section.dart': 5,
  'lib/features/subscription/presentation/pages/paywall_page.dart': 7,
  'lib/features/wrap_up/presentation/film/frames/wrap_up_film_footnote.dart': 1,
  'lib/features/wrap_up/presentation/film/wrap_up_film_hud.dart': 3,
};

/// `Text('…')` whose literal starts with a word (two letters in a row, any
/// script). Glyphs ('✦', the Google 'G') and strings that open with an
/// interpolation of already-localized text are not UI copy.
final _literalText = RegExp(
  r'''Text\(\s*(['"])(?!\$\{)[^'"\n]*?\p{L}{2,}''',
  unicode: true,
);

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
