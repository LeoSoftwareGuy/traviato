import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/bonus/presentation/widgets/bonus_template_text.dart';
import 'package:traviato/features/checklist/domain/entities/checklist_category.dart';
import 'package:traviato/features/checklist/domain/entities/checklist_suggestion_entity.dart';
import 'package:traviato/features/checklist/presentation/widgets/checklist_suggestion_title.dart';
import 'package:traviato/features/profile/domain/entities/achievement_entity.dart';
import 'package:traviato/features/profile/presentation/widgets/achievement_text.dart';
import 'package:traviato/l10n/app_localizations.dart';

/// The SQL seeds are the source of truth for the English text (#243): these
/// tests re-read them so the ARB can't drift from the database.
String _sql(String name) =>
    File('supabase/migrations/$name').readAsStringSync();

String _unquote(String s) => s.replaceAll("''", "'");

/// Later rewordings of seeded bonus text (#248), applied in migration order
/// on top of the reseed: `{code: {field: text}}`.
Map<String, Map<String, String>> _bonusUpdates() {
  final files =
      Directory('supabase/migrations')
          .listSync()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.sql'))
          .toList()
        ..sort();
  final updates = <String, Map<String, String>>{};
  final pattern = RegExp(
    r"update public\.bonus_task_templates set (title|detail) = "
    r"'((?:[^']|'')*)' where code = '([a-z_]+)';",
  );
  for (final name in files) {
    for (final m in pattern.allMatches(_sql(name))) {
      (updates[m[3]!] ??= {})[m[1]!] = _unquote(m[2]!);
    }
  }
  return updates;
}

final _en = lookupAppLocalizations(const Locale('en'));
final _ru = lookupAppLocalizations(const Locale('ru'));
final _et = lookupAppLocalizations(const Locale('et'));

BonusTaskTemplateEntity _template(String code, String title, String? detail) =>
    BonusTaskTemplateEntity(
      id: 1,
      code: code,
      title: title,
      detail: detail,
      points: 1,
      phase: BonusTaskPhase.anytime,
      kind: BonusTaskKind.regular,
    );

void main() {
  group('bonus task templates', () {
    final rows = RegExp(
      r"\('([a-z_]+)', '((?:[^']|'')*)', '((?:[^']|'')*)'",
    ).allMatches(_sql('20260829120313_reseed_bonus_task_templates.sql'));

    test('every seeded template has English copy equal to the DB', () {
      expect(rows, isNotEmpty);
      final updates = _bonusUpdates();
      for (final row in rows) {
        final updated = updates[row[1]!] ?? const {};
        final t = _template(
          row[1]!,
          updated['title'] ?? _unquote(row[2]!),
          updated['detail'] ?? _unquote(row[3]!),
        );
        expect(bonusTemplateTitle(_en, t), t.title, reason: t.code);
        expect(bonusTemplateDetail(_en, t), t.detail, reason: t.code);
        expect(bonusTemplateTitle(_ru, t), isNot(t.title), reason: t.code);
        expect(bonusTemplateTitle(_et, t), isNot(t.title), reason: t.code);
      }
    });

    test('an unknown code falls back to the DB text', () {
      final t = _template('brand_new', 'Brand new dare', 'Fresh.');
      expect(bonusTemplateTitle(_ru, t), 'Brand new dare');
      expect(bonusTemplateDetail(_ru, t), 'Fresh.');
      expect(
        bonusTemplateDetail(_ru, _template('x', 'X', null)),
        isNull,
      );
    });
  });

  group('achievements', () {
    // Seeded titles, then renamed by a later migration.
    final seeded = RegExp(
      r"\(\s*'([a-z_]+)',\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)'",
    ).allMatches(_sql('20260821100611_seed_achievement_templates.sql'));
    final renames = {
      for (final m in RegExp(
        r"set title = '((?:[^']|'')*)' where code = '([a-z_]+)'",
      ).allMatches(_sql('20260920073854_update_achievement_titles.sql')))
        m[2]!: _unquote(m[1]!),
    };

    test('every achievement has English copy equal to the DB', () {
      expect(seeded, hasLength(8));
      for (final row in seeded) {
        final code = row[1]!;
        final a = AchievementEntity(
          id: 1,
          code: code,
          title: renames[code] ?? _unquote(row[2]!),
          description: _unquote(row[3]!),
          metric: AchievementMetric.trips,
          target: 1,
          position: 1,
          currentValue: 0,
        );
        expect(achievementTitle(_en, a), a.title, reason: code);
        expect(achievementDescription(_en, a), a.description, reason: code);
        // Russian always differs; Estonian may share a word ("Legend").
        expect(achievementTitle(_ru, a), isNot(a.title), reason: code);
        expect(achievementTitle(_et, a), isNotEmpty, reason: code);
      }
    });

    test('storyteller matches the name used in the app copy', () {
      final storyteller = seeded.firstWhere((r) => r[1] == 'storyteller');
      final a = AchievementEntity(
        id: 1,
        code: 'storyteller',
        title: _unquote(storyteller[2]!),
        description: _unquote(storyteller[3]!),
        metric: AchievementMetric.notes,
        target: 20,
        position: 1,
        currentValue: 0,
      );
      expect(achievementTitle(_ru, a), 'Рассказчик');
      expect(_ru.auth_rewardTease('X'), contains('«Рассказчик»'));
      expect(achievementTitle(_et, a), 'Jutustaja');
      expect(_et.auth_rewardTease('X'), contains('Jutustaja'));
    });
  });

  group('checklist suggestions', () {
    final backfill = RegExp(
      r"\('((?:[^']|'')*)', '([a-z0-9_]+)'\)",
    ).allMatches(_sql('20261019090000_add_checklist_suggestion_codes.sql'));
    final seededTitles = RegExp(
      r"\('((?:[^']|'')*)',\s*'[a-z_]+',\s*(?:true|false)\)",
    ).allMatches(_sql('20260820130248_seed_checklist_suggestions.sql'));

    test('the backfill covers every seeded suggestion', () {
      expect(
        [for (final m in backfill) _unquote(m[1]!)],
        [for (final m in seededTitles) _unquote(m[1]!)],
      );
    });

    test('every code has English equal to the DB and its own translation', () {
      for (final row in backfill) {
        final s = ChecklistSuggestionEntity(
          id: 1,
          code: row[2]!,
          title: _unquote(row[1]!),
          category: ChecklistCategory.travelEssentials,
          isEssential: false,
        );
        expect(checklistSuggestionTitle(_en, s), s.title, reason: s.code);
        // Russian always differs; Estonian may share a word ("Deodorant").
        expect(checklistSuggestionTitle(_ru, s), isNot(s.title));
        expect(checklistSuggestionTitle(_et, s), isNotEmpty);
      }
    });
  });
}
