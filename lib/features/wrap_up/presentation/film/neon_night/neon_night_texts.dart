import 'package:flutter/painting.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../../l10n/app_localizations.dart';
import 'neon_chapter_card.dart';
import 'neon_night_story.dart';
import 'neon_text_fx.dart';
import 'neon_tokens.dart';
import 'neon_type.dart';

/// Every word of the Neon Night film laid out once (#363), in canvas px:
/// frames only move, fade and light them. Rebuilt when the story or the
/// language changes; dispose when replaced.
class NeonNightTexts {
  NeonNightTexts(NeonNightStory story, AppLocalizations l10n)
    : ignition = NnIgnitionTexts(story, l10n.localeName),
      plan = story.hasPlan ? NnPlanTexts(story, l10n) : null,
      chapters = [
        for (var i = 0; i < story.chapters.length; i++)
          NnChapterTexts(story, i, l10n),
      ],
      note = story.note == null ? null : NnNoteTexts(story, l10n);

  final NnIgnitionTexts ignition;

  /// Null when the memory has no plan (the scene is cut).
  final NnPlanTexts? plan;

  /// One per chapter, in order.
  final List<NnChapterTexts> chapters;

  /// Null when the memory has no note (the scene is cut).
  final NnNoteTexts? note;

  void dispose() {
    ignition.dispose();
    plan?.dispose();
    for (final chapter in chapters) {
      chapter.dispose();
    }
    note?.dispose();
  }
}

/// Ignition (§5.1): the title as a pink neon tube, and the
/// night's date. No counts: those wait for the end card.
class NnIgnitionTexts {
  NnIgnitionTexts(NeonNightStory story, String localeName)
    : title = NeonTubeText(
        story.title.toUpperCase(),
        size: NeonType.fit(story.title, titleWidth, 230, 0.47),
        maxWidth: titleWidth,
        stroke: 5,
        // The spec says a cyan core; the reference render shows the
        // default white one (pale pink over the tube), and the render wins.
        color: NeonColors.pink,
      ),
      meta = neonLayout(
        formatDate(story.date, localeName),
        NeonType.mono(38, color: metaColor, letterSpacing: 3),
      );

  static const titleWidth = 960.0;
  static const metaColor = Color(0xFFCFEFFF);

  final NeonTubeText title;
  final TextPainter meta;

  /// 'SAT 14 NOV' in [localeName] ('СБ 14 НОЯБ.' in Russian).
  static String formatDate(DateTime date, String localeName) =>
      DateFormat('EEE d MMM', localeName).format(date).toUpperCase();

  void dispose() {
    title.dispose();
    meta.dispose();
  }
}

/// "Tonight's plan" (§5.2): the heading, up to [maxRows] rows and, for a
/// longer plan, "+N MORE".
class NnPlanTexts {
  NnPlanTexts(NeonNightStory story, AppLocalizations l10n)
    : title = NeonTubeText(
        l10n.neonNight_planTitle.toUpperCase(),
        size: NeonType.fit(l10n.neonNight_planTitle, 860, 150, 0.46),
        maxWidth: 860,
        stroke: 4,
        color: NeonColors.pink,
      ),
      rows = _rows(story.plan),
      more = story.plan.length > maxRows
          ? neonLayout(
              l10n
                  .neonNight_planMore(story.plan.length - maxRows)
                  .toUpperCase(),
              NeonType.mono(40, color: NeonColors.grey),
            )
          : null;

  static const maxRows = 5;

  final NeonTubeText title;
  final List<NnPlanRowTexts> rows;
  final TextPainter? more;

  /// The done rows' colours, by how many done rows came before.
  static const _colors = [NeonColors.cyan, NeonColors.pink, NeonColors.violet];
  static const _tints = [
    NeonColors.tintCyan,
    NeonColors.tintPink,
    NeonColors.tintViolet,
  ];

  static List<NnPlanRowTexts> _rows(List<NnPlanRow> plan) {
    var done = 0;
    return [
      for (final row in plan.take(maxRows))
        () {
          final d = row.done ? done++ : null;
          return NnPlanRowTexts(
            row,
            doneIndex: d,
            color: _colors[(d ?? 0) % 3],
            tint: _tints[(d ?? 0) % 3],
          );
        }(),
    ];
  }

  void dispose() {
    title.dispose();
    for (final row in rows) {
      row.dispose();
    }
    more?.dispose();
  }
}

/// One plan row: the time and the item, each grey and, if done, lit.
class NnPlanRowTexts {
  factory NnPlanRowTexts(
    NnPlanRow row, {
    required int? doneIndex,
    required Color color,
    required Color tint,
  }) {
    NeonGlowText text(String s, double size) => NeonGlowText(
      s,
      NeonType.display(size, weight: 900),
      plain: grey,
      lit: tint,
      glowColor: color,
    );
    final item = row.item.toUpperCase();
    var itemSize = NeonType.fit(item, itemWidth, 130, 0.44);
    // A wider face (Cyrillic) is also held to the measured width.
    final probe = text(item, itemSize);
    if (probe.size.width > itemWidth) {
      itemSize *= itemWidth / probe.size.width;
    }
    probe.dispose();
    return NnPlanRowTexts._(
      time: text(row.time, 130),
      item: text(item, itemSize),
      doneIndex: doneIndex,
      color: color,
      tint: tint,
    );
  }

  NnPlanRowTexts._({
    required this.time,
    required this.item,
    required this.doneIndex,
    required this.color,
    required this.tint,
  });

  static const itemWidth = 440.0;

  /// Rows not done: grey at α 0.85, no glow.
  static final grey = NeonColors.grey.withValues(alpha: 0.85);

  final NeonGlowText time;
  final NeonGlowText item;

  /// Which done row this is (0, 1, 2…), or null if not done.
  final int? doneIndex;
  final Color color;
  final Color tint;

  bool get isDone => doneIndex != null;

  /// How far below the time's top the item's top sits, so their
  /// baselines line up.
  double get itemDrop => time.baseline - item.baseline;

  void dispose() {
    time.dispose();
    item.dispose();
  }
}

/// A chapter card (§5.3): header, time range, ghost numeral (pink, then
/// the accent), title, the typed line and each zoom's time label.
class NnChapterTexts {
  factory NnChapterTexts(
    NeonNightStory story,
    int index,
    AppLocalizations l10n,
  ) {
    final chapter = story.chapters[index];
    final count = story.chapters.length;
    final accent = NeonColors.chapterAccent(index);
    String two(int n) => n.toString().padLeft(2, '0');
    NeonTubeText numeral(Color color) => NeonTubeText(
      two(index + 1),
      size: 380,
      maxWidth: 1000,
      stroke: 6,
      color: color,
      mono: true,
    );
    final title = NeonType.splitTitle(chapter.title.toUpperCase());
    final note = chapter.note;
    final typed =
        note == null
              ? null
              : TextPainter(
                  text: TextSpan(
                    text: '> ${note.toUpperCase()}',
                    style: NeonType.mono(40, color: accent, height: 52 / 40),
                  ),
                  textDirection: TextDirection.ltr,
                  maxLines: 2,
                  ellipsis: '…',
                )
          ?..layout(maxWidth: typedWidth);
    final sheet = NnContactSheet.forPhotos(chapter.photos.length);
    final tiles = sheet.tiles.length;
    final timing = NnCardTiming(
      chapterNumber: index + 1,
      beats: 16,
      zooms: 3,
      tiles: tiles,
    );
    return NnChapterTexts._(
      accent: accent,
      header: neonLayout(
        'CH ${two(index + 1)}/${two(count)}',
        NeonType.mono(52, color: accent),
      ),
      range: neonLayout(
        '${chapter.from} – ${chapter.to}',
        NeonType.mono(36, color: accent.withValues(alpha: 0.75)),
      ),
      numeralPink: numeral(NeonColors.pink),
      numeral: numeral(accent),
      title: NeonChromaticText(
        title,
        size: NeonType.fit(title, 860, 170, 0.5),
        maxWidth: 860,
        split: 4,
      ),
      typed: typed,
      moments: [
        for (final moment in chapter.moments)
          NnMomentTexts(moment, chapter, l10n),
      ],
      tileLabels: {
        for (final k in timing.zoomTiles)
          k: NeonLabelBox(chapter.photos[k].takenAt),
      },
    );
  }

  NnChapterTexts._({
    required this.accent,
    required this.header,
    required this.range,
    required this.numeralPink,
    required this.numeral,
    required this.title,
    required this.typed,
    required this.tileLabels,
    required this.moments,
  });

  static const typedWidth = 936.0;

  final Color accent;
  final TextPainter header;
  final TextPainter range;
  final NeonTubeText numeralPink;
  final NeonTubeText numeral;
  final NeonChromaticText title;

  /// `> NOTE`, at most 2 lines; null when the chapter has no note.
  final TextPainter? typed;

  /// The time label of each tile a zoom can pick.
  final Map<int, NeonLabelBox> tileLabels;

  /// One per moment, in order.
  final List<NnMomentTexts> moments;

  /// How many lines the typed note takes (0 without one).
  int get typedLines => typed?.computeLineMetrics().length ?? 0;

  /// How many characters the typed line has to type.
  int get typedLength =>
      typed == null ? 0 : (typed!.text! as TextSpan).text!.length;

  void dispose() {
    header.dispose();
    range.dispose();
    numeralPink.dispose();
    numeral.dispose();
    title.dispose();
    typed?.dispose();
    for (final moment in moments) {
      moment.dispose();
    }
    for (final label in tileLabels.values) {
      label.dispose();
    }
  }
}

/// A moment's words (§5.4–5.6): its label, or its title and times.
sealed class NnMomentTexts {
  factory NnMomentTexts(
    NnMoment moment,
    NnChapter chapter,
    AppLocalizations l10n,
  ) => switch (moment) {
    NnSplit(:final photos, :final place) => NnLabelTexts(
      place == null
          ? photos.first.takenAt
          : '${photos.first.takenAt} · ${place.toUpperCase()}',
    ),
    NnBurst(:final photos) => NnLabelTexts(
      '${l10n.neonNight_burst.toUpperCase()} · ${photos.first.takenAt}',
    ),
    NnTimeline() => NnTimelineTexts(moment, chapter),
    NnPeak() => NnPeakTexts(moment, chapter),
  };

  void dispose();
}

/// Split's and Burst's label box at (48, 1760): mono 38, no wrap.
class NnLabelTexts implements NnMomentTexts {
  NnLabelTexts(String text) : label = NeonLabelBox(text);

  final NeonLabelBox label;

  @override
  void dispose() => label.dispose();
}

/// Timeline: the chapter's title as a pink tube, and each item's time,
/// plain and lit.
class NnTimelineTexts implements NnMomentTexts {
  NnTimelineTexts(NnTimeline moment, NnChapter chapter)
    : title = NeonTubeText(
        chapter.title.toUpperCase(),
        size: NeonType.fit(chapter.title, titleWidth, 140, 0.46),
        maxWidth: titleWidth,
        stroke: 4,
        color: NeonColors.pink,
        core: NeonColors.tintViolet,
      ),
      times = [
        for (final photo in moment.photos)
          (
            neonLayout(
              photo.takenAt,
              NeonType.mono(44, color: plainTime, letterSpacing: 2),
            ),
            neonLayout(
              photo.takenAt,
              NeonType.mono(44, color: NeonColors.tintGreen, letterSpacing: 2),
            ),
          ),
      ];

  static const titleWidth = 760.0;
  static const plainTime = Color(0xFFECE8F6);

  final NeonTubeText title;

  /// Each item's time: (plain, lit).
  final List<(TextPainter, TextPainter)> times;

  @override
  void dispose() {
    title.dispose();
    for (final (plain, lit) in times) {
      plain.dispose();
      lit.dispose();
    }
  }
}

/// Peak: the chapter's title in pink with the chromatic split, and the
/// time range of its photos.
class NnPeakTexts implements NnMomentTexts {
  NnPeakTexts(NnPeak moment, NnChapter chapter)
    : title = NeonChromaticText(
        chapter.title.toUpperCase(),
        size: NeonType.fit(chapter.title, titleWidth, 260, 0.42),
        maxWidth: titleWidth,
        split: 4,
        color: NeonColors.pink,
      ),
      range = neonLayout(
        '${moment.photos.first.takenAt} → ${moment.photos.last.takenAt}',
        NeonType.mono(40, color: NeonColors.white, letterSpacing: 2),
      );

  static const titleWidth = 820.0;

  final NeonChromaticText title;
  final TextPainter range;

  @override
  void dispose() {
    title.dispose();
    range.dispose();
  }
}

/// The Note scene (§5.7): its tag, the lines as tubes and the signature.
class NnNoteTexts {
  factory NnNoteTexts(NeonNightStory story, AppLocalizations l10n) {
    final note = story.note!;
    final word = l10n
        .neonNight_noteTag(note.number.toString().padLeft(2, '0'))
        .toUpperCase();
    final lines = neonNoteLines(note.text);
    final size = NeonType.fit(lines.join('\n'), lineWidth, 210, 0.43);
    final name = story.firstName;
    return NnNoteTexts._(
      tag: NeonLabelBox(
        note.time == null ? word : '$word · ${note.time}',
        size: 40,
        border: const [NeonColors.cyan, NeonColors.pink],
      ),
      lines: [
        for (final (i, line) in lines.indexed)
          NeonTubeText(
            line,
            size: size,
            maxWidth: lineWidth,
            stroke: 4,
            weight: 600,
            color: colors[i],
          ),
      ],
      fontSize: size,
      signature: name == null
          ? null
          : neonLayout(
              '— $name',
              NeonType.mono(48, color: NeonColors.body, letterSpacing: 2),
            ),
    );
  }

  NnNoteTexts._({
    required this.tag,
    required this.lines,
    required this.fontSize,
    required this.signature,
  });

  static const lineWidth = 900.0;
  static const colors = [
    NeonColors.cyan,
    NeonColors.pink,
    NeonColors.cyan,
    NeonColors.green,
    NeonColors.pink,
  ];

  final NeonLabelBox tag;
  final List<NeonTubeText> lines;

  /// The lines' size: fit(900, 210, 0.43) on the longest.
  final double fontSize;

  /// `— Leo`; null without a first name.
  final TextPainter? signature;

  void dispose() {
    tag.dispose();
    for (final line in lines) {
      line.dispose();
    }
    signature?.dispose();
  }
}
