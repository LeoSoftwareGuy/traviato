import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../../core/constants/app_constants.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/film_text_rules.dart';
import 'neon_beat.dart';
import 'neon_chapter_card.dart';
import 'neon_moments.dart';
import 'neon_night_story.dart';
import 'neon_zoom_picks.dart';
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
      note = switch (story.noteLines) {
        final lines? => NnNoteTexts(story, l10n, lines),
        null => null,
      },
      finale = NnFinaleTexts(story, l10n),
      ending = NnEndingTexts(story, l10n);

  final NnIgnitionTexts ignition;

  /// Null when the memory has no plan (the scene is cut).
  final NnPlanTexts? plan;

  /// One per chapter, in order.
  final List<NnChapterTexts> chapters;

  /// Null when the memory has no note (the scene is cut).
  final NnNoteTexts? note;

  final NnFinaleTexts finale;
  final NnEndingTexts ending;

  void dispose() {
    ignition.dispose();
    plan?.dispose();
    for (final chapter in chapters) {
      chapter.dispose();
    }
    note?.dispose();
    finale.dispose();
    ending.dispose();
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
/// the accent), title, the typed line and each zoom's label (caption or
/// time, #387).
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
    final typedText = typedTextFor(chapter.note);
    final typed = typedText == null ? null : _typedPainter(typedText, accent);
    final sheet = NnContactSheet.forPhotos(chapter.cardPhotos.length);
    final tiles = sheet.tiles.length;
    final timing = NnCardTiming(
      chapterNumber: index + 1,
      beats: 16,
      zooms: NeonZoomPicks.cycles,
      tiles: tiles,
      zoomTiles: zoomTilesFor(chapter, index + 1),
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
          // The caption (up to 3 lines, never cut), else — a photo without
          // one — the time, under the zoom (#387, #399, #446).
          k: ?zoomLabelFor(chapter.cardPhotos[k]),
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

  /// The typed line's mono size; it may wrap to [typedMaxLines] lines.
  static const typedSize = 40.0;
  static const typedMaxLines = 3;

  /// What the card types for [note] (#399 T1): the whole note when it fits
  /// on [typedMaxLines] lines, else its first whole sentences that do, else
  /// nothing. Never cut with "…".
  static String? typedTextFor(String? note) {
    final text = note?.trim();
    if (text == null || text.isEmpty) return null;
    bool fits(String candidate) {
      final painter = TextPainter(
        text: TextSpan(
          text: '> ${candidate.toUpperCase()}',
          style: NeonType.mono(typedSize, height: 52 / 40),
        ),
        textDirection: TextDirection.ltr,
        maxLines: typedMaxLines,
      )..layout(maxWidth: typedWidth);
      final ok = !painter.didExceedMaxLines;
      painter.dispose();
      return ok;
    }

    if (fits(text)) return text;
    return FilmTextRules.leadingSentencesThatFit(text, fits);
  }

  static TextPainter _typedPainter(String text, Color accent) => TextPainter(
    text: TextSpan(
      text: '> ${text.toUpperCase()}',
      style: NeonType.mono(typedSize, color: accent, height: 52 / 40),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: typedWidth);

  /// A zoom's label: [photo]'s caption when it fits and can be read
  /// within a zoom (#444), else its time.
  static NeonLabelBox? zoomLabelFor(NnPhoto photo) {
    final caption = zoomCaptionOf(photo, const NeonBeat());
    final box = caption == null
        ? null
        : NeonLabelBox.caption(caption, maxWidth: NnCardTiming.zoomRect.width);
    // A caption too long to read here: no label, never the time (#450).
    if (box == null && (photo.caption?.trim().isNotEmpty ?? false)) {
      return null;
    }
    return box ?? NeonLabelBox(photo.takenAt);
  }

  /// The caption a card zoom shows under [photo]: one that fits the zoom
  /// and can be read in its 1½ beats plus [NeonZoomPicks.maxHoldBeats]
  /// (#444 — a zoom never holds 9 s for a long caption). Null = none.
  /// The card tiles [chapter] zooms, best first (#446,
  /// [NeonZoomPicks.best]): captions a zoom can show, then hero score.
  static List<int> zoomTilesFor(NnChapter chapter, int chapterNumber) {
    final tiles = NnContactSheet.forPhotos(
      chapter.cardPhotos.length,
    ).tiles.length;
    final best = NeonZoomPicks.best(
      chapterNumber: chapterNumber,
      photos: [
        for (final p in chapter.cardPhotos.take(tiles))
          (caption: p.caption, heroScore: p.heroScore),
      ],
      fitsZoom: (caption) =>
          zoomCaptionOf(
            NnPhoto(id: '', takenAt: '', caption: caption),
            const NeonBeat(),
          ) !=
          null,
      quickest: chapter.quickZooms,
    );
    return best.take(chapter.zooms).toList();
  }

  static String? zoomCaptionOf(NnPhoto photo, NeonBeat beat) {
    final caption = photo.caption?.trim();
    if (caption == null || caption.isEmpty) return null;
    final read = beat.secToBeat(FilmTextRules.readingTime(caption));
    if (read > 1.5 + NeonZoomPicks.maxHoldBeats) return null;
    final box = NeonLabelBox.caption(
      caption,
      maxWidth: NnCardTiming.zoomRect.width,
    );
    if (box == null) return null;
    box.dispose();
    return caption;
  }

  final Color accent;
  final TextPainter header;
  final TextPainter range;
  final NeonTubeText numeralPink;
  final NeonTubeText numeral;
  final NeonChromaticText title;

  /// `> NOTE`, at most 3 lines; null when the chapter has no note (or none
  /// of it fits).
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
      photos,
    ),
    NnBurst(:final photos) => NnLabelTexts(
      '${l10n.neonNight_burst.toUpperCase()} · ${photos.first.takenAt}',
      photos,
    ),
    NnTimeline() => NnTimelineTexts(moment, chapter),
    NnPeak() => NnPeakTexts(moment, chapter),
  };

  void dispose();
}

/// The label boxes' width at (48, 1760): the frame less both margins.
const double nnLabelWidth = 1080 - 2 * 48;

/// [photo]'s caption in a label box [maxWidth] wide, or null when it has
/// none or it doesn't fit (#399 T1: left out, never cut). With
/// [withLine], the note line it plays comes first (#426), the caption
/// when the line doesn't fit.
NeonLabelBox? nnCaptionBox(
  NnPhoto photo, {
  double maxWidth = nnLabelWidth,
  bool withLine = false,
}) {
  for (final text in [if (withLine) photo.line, photo.caption]) {
    final words = text?.trim();
    if (words == null || words.isEmpty) continue;
    final box = NeonLabelBox.caption(words, maxWidth: maxWidth);
    if (box != null) return box;
  }
  return null;
}

/// Split's and Burst's label box at (48, 1760): mono 38, no wrap. When the
/// moment's photos have captions, the box shows those instead, one after
/// another in photo order, each for its reading time (#399 T1).
class NnLabelTexts implements NnMomentTexts {
  NnLabelTexts(String text, List<NnPhoto> photos)
    : label = NeonLabelBox(text),
      captions = [
        for (final photo in photos) ?nnCaptionBox(photo, withLine: true),
      ];

  final NeonLabelBox label;

  /// The captions that fit, in photo order.
  final List<NeonLabelBox> captions;

  /// How long each caption stays up, s.
  List<double> get readings => [
    for (final c in captions) FilmTextRules.readingTime(c.text),
  ];

  @override
  void dispose() {
    label.dispose();
    for (final caption in captions) {
      caption.dispose();
    }
  }
}

/// Timeline: the chapter's title as a pink tube, and each item's time,
/// plain and lit. A lit item with words — its note line, else its caption
/// — zooms in with them under it (#426).
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
          (_time(photo, plainTime), _time(photo, NeonColors.tintGreen)),
      ],
      captions = [
        for (final photo in moment.photos)
          nnCaptionBox(
            photo,
            maxWidth: NnTimelineLayout.zoomWidth,
            withLine: true,
          ),
      ];

  static TextPainter _time(NnPhoto photo, Color color) => neonLayout(
    photo.takenAt,
    NeonType.mono(44, color: color, letterSpacing: 2),
  );

  /// How many beats each item holds the highlight on [beat]'s clock: one,
  /// or — zoomed in with its words under it (#426) — the zoom in, its
  /// reading time and the zoom out.
  static List<int> holdsFor(List<NeonLabelBox?> captions, NeonBeat beat) => [
    for (final caption in captions)
      caption == null
          ? 1
          : math.max(
              2,
              (beat.secToBeat(
                        NnTimelineLayout.zoomIn +
                            FilmTextRules.readingTime(caption.text) +
                            NnTimelineLayout.zoomOut,
                      ) -
                      1e-9)
                  .ceil(),
            ),
  ];

  static const titleWidth = 760.0;
  static const plainTime = Color(0xFFECE8F6);

  final NeonTubeText title;

  /// Each item's time: (plain, lit).
  final List<(TextPainter, TextPainter)> times;

  /// Each item's caption box, null without one.
  final List<NeonLabelBox?> captions;

  @override
  void dispose() {
    title.dispose();
    for (final (plain, lit) in times) {
      plain.dispose();
      lit.dispose();
    }
    for (final caption in captions) {
      caption?.dispose();
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
  factory NnNoteTexts(
    NeonNightStory story,
    AppLocalizations l10n,
    List<String> lines,
  ) {
    final note = story.note!;
    final word = l10n
        .neonNight_noteTag(note.number.toString().padLeft(2, '0'))
        .toUpperCase();
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
            color: colors[i % colors.length],
          ),
      ],
      text: lines.join(' '),
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
    required this.text,
    required this.fontSize,
    required this.signature,
  });

  /// The beats between two lines lighting up: 2, or 1 for a note on more
  /// than 5 lines so it is all lit in time to be read.
  static int staggerFor(int lines) => lines > 5 ? 1 : 2;

  /// How many beats the scene needs on [beat]'s clock for [lines] to be
  /// read (#399 T1): lit from lb 1, then on screen for the note's reading
  /// time, before its 0.25 s exit. The spec's 12 at least; whole bars.
  static int beatsFor(List<String> lines, NeonBeat beat) {
    final lit = 1.0 + staggerFor(lines.length) * (lines.length - 1) + 1;
    final read = 1 + beat.secToBeat(FilmTextRules.readingTime(lines.join(' ')));
    final need = math.max(lit, read) + beat.secToBeat(0.25);
    return math.max(12, ((need - 1e-9) / 4).ceil() * 4);
  }

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

  /// The words shown, as one line.
  final String text;

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

/// The Finale's headline (§5.8): white chromatic, d 5, fit(960, 150,
/// 0.45).
class NnFinaleTexts {
  NnFinaleTexts(NeonNightStory story, AppLocalizations l10n)
    : headline = _chromatic(headlineFor(story, l10n));

  static NeonChromaticText _chromatic(String text) => NeonChromaticText(
    text,
    size: NeonType.fit(text, width, 150, 0.45),
    maxWidth: width,
    split: 5,
  );

  static const width = 960.0;

  final NeonChromaticText headline;

  /// The memory's own headline, else its note when it fits on one line,
  /// else "What a night"; in capitals.
  static String headlineFor(NeonNightStory story, AppLocalizations l10n) {
    final own = story.headline?.trim();
    if (own != null && own.isNotEmpty) return own.toUpperCase();
    final note = story.note;
    if (note != null) {
      // Only a note short enough to be the headline whole (#399: never cut).
      final lines = neonWrapNote(note.text);
      if (lines.length == 1) return lines.first;
    }
    return l10n.neonNight_headline.toUpperCase();
  }

  void dispose() => headline.dispose();
}

/// The end card (§5.9): `{n} moments`, the totals, `{TITLE} · {DATE}`
/// and the "Storyni" sign.
class NnEndingTexts {
  NnEndingTexts(NeonNightStory story, AppLocalizations l10n)
    : moments = NeonChromaticText(
        l10n.neonNight_moments(story.endTotals.moments).toLowerCase(),
        size: 150,
        maxWidth: 960,
        split: 4,
        weight: 800,
      ),
      totals = neonLayout(
        totalsFor(story, l10n),
        NeonType.mono(36, color: NeonColors.body, letterSpacing: 3),
      ),
      titleDate = neonLayout(
        '${story.title.toUpperCase()} · '
        '${NnIgnitionTexts.formatDate(story.date, l10n.localeName)}',
        NeonType.mono(36, color: NeonColors.pink, letterSpacing: 3),
      ),
      // The spec says a cyan core, stroke 3; the reference render shows a
      // pale pink core and a heavier tube, and the render wins.
      logo = NeonTubeText(
        AppConstants.appName,
        size: 120,
        maxWidth: 960,
        stroke: 4,
        color: NeonColors.pink,
        core: NeonColors.tintPink,
      );

  /// `142 PHOTOS · 9 NOTES · 3 TICKS`, leaving out a zero (#399 T4).
  static String totalsFor(NeonNightStory story, AppLocalizations l10n) {
    final totals = story.endTotals;
    return [
      if (totals.photos > 0) l10n.neonNight_photos(totals.photos),
      if (totals.notes > 0) l10n.neonNight_notes(totals.notes),
      if (totals.ticks > 0) l10n.neonNight_ticks(totals.ticks),
    ].join(' · ').toUpperCase();
  }

  final NeonChromaticText moments;
  final TextPainter totals;
  final TextPainter titleDate;
  final NeonTubeText logo;

  void dispose() {
    moments.dispose();
    totals.dispose();
    titleDate.dispose();
    logo.dispose();
  }
}
