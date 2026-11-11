import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_copy.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_fixture.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_tokens.dart';
import 'package:traviato/l10n/app_localizations.dart';

/// The characters a TrueType font maps (its `cmap` table, formats 4 and
/// 12), so a test can prove the film never falls back to a system font.
Set<int> _codepoints(String path) {
  final data = ByteData.sublistView(File(path).readAsBytesSync());
  final tables = data.getUint16(4);
  var cmap = -1;
  for (var i = 0; i < tables; i++) {
    final record = 12 + 16 * i;
    final tag = String.fromCharCodes([
      for (var b = 0; b < 4; b++) data.getUint8(record + b),
    ]);
    if (tag == 'cmap') cmap = data.getUint32(record + 8);
  }
  final points = <int>{};
  final subtables = data.getUint16(cmap + 2);
  for (var i = 0; i < subtables; i++) {
    final at = cmap + data.getUint32(cmap + 4 + 8 * i + 4);
    switch (data.getUint16(at)) {
      case 4:
        final segments = data.getUint16(at + 6) ~/ 2;
        for (var s = 0; s < segments; s++) {
          final end = data.getUint16(at + 14 + 2 * s);
          final start = data.getUint16(at + 16 + 2 * segments + 2 * s);
          if (start != 0xFFFF) {
            for (var c = start; c <= end; c++) {
              points.add(c);
            }
          }
        }
      case 12:
        final groups = data.getUint32(at + 12);
        for (var g = 0; g < groups; g++) {
          final start = data.getUint32(at + 16 + 12 * g);
          final end = data.getUint32(at + 20 + 12 * g);
          for (var c = start; c <= end; c++) {
            points.add(c);
          }
        }
    }
  }
  return points;
}

Set<int> _missing(Set<int> font, Iterable<String> texts) => {
  for (final text in texts)
    for (final rune in text.runes)
      if (rune > 0x20 && !font.contains(rune)) rune,
};

void main() {
  final serif = _codepoints('assets/fonts/DMSerifDisplay-Regular.ttf');
  final serifCyrillic = _codepoints('assets/fonts/PlayfairDisplay[wght].ttf');
  final sans = _codepoints('assets/fonts/OpenSans[wdth,wght].ttf');
  final hand = _codepoints('assets/fonts/Caveat[wght].ttf');

  for (final (locale, story) in [
    ('en', SkyStoryFixtures.lisbon),
    ('ru', SkyStoryFixtures.lisbonRu),
  ]) {
    test('the $locale film has every glyph it needs', () {
      final copy = SkyStoryCopy.resolve(
        story,
        lookupAppLocalizations(Locale(locale)),
        locale,
      );
      final display = [
        copy.title.title,
        copy.outro.moments,
        for (final page in copy.pages) ...[
          page.headline,
          if (page.badgeCount != null) page.badgeCount!,
        ],
      ];
      for (final text in display) {
        final font = SkyStoryText.needsCyrillicSerif(text)
            ? serifCyrillic
            : serif;
        expect(_missing(font, [text]), isEmpty, reason: text);
      }
      expect(
        _missing(sans, [
          copy.title.eyebrow,
          SkyOutroCopy.brand,
          for (final page in copy.pages) ...[
            page.eyebrow,
            if (page.badgeLabel != null) page.badgeLabel!,
          ],
        ]),
        isEmpty,
      );
      expect(
        _missing(hand, [
          copy.title.subtitle,
          copy.outro.tagline,
          for (final page in copy.pages) ...[
            page.heroCaption,
            if (page.note != null) page.note!,
            if (page.signature != null) page.signature!,
          ],
        ]),
        isEmpty,
      );
    });
  }

  test('DM Serif Display has no Cyrillic, so Russian titles switch', () {
    expect(serif.contains('Л'.runes.single), isFalse);
    expect(SkyStoryText.needsCyrillicSerif('Лиссабон, вдвоём'), isTrue);
    expect(SkyStoryText.needsCyrillicSerif('Tallinn, Pärnu'), isFalse);
    expect(_missing(serif, ['Tallinn, Pärnu – Õismäe']), isEmpty);
  });
}
