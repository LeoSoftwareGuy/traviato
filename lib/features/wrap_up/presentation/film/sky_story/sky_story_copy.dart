import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import 'sky_story.dart';

/// Sky Story's words in the film's language (#345): composed once per
/// language from `SkyStory`, then painted every frame.
class SkyStoryCopy extends Equatable {
  const SkyStoryCopy({
    required this.title,
    required this.pages,
    required this.outro,
  });

  factory SkyStoryCopy.resolve(
    SkyStory story,
    AppLocalizations l10n,
    String locale,
  ) => SkyStoryCopy(
    title: SkyTitleCopy(
      eyebrow: l10n.skyStory_eyebrowStory.toUpperCase(),
      title: story.title,
      subtitle: [
        dateRange(story.startDate, story.endDate, locale),
        if (story.names case final names? when names.trim().isNotEmpty)
          names.trim(),
      ].join(' · '),
    ),
    pages: [
      for (final (page, layout) in [
        for (final (i, page) in story.pages.indexed) (page, story.layouts[i]),
      ])
        SkyPageCopy.resolve(page, layout, l10n, locale),
    ],
    outro: SkyOutroCopy(
      moments: l10n.skyStory_moments(story.momentCount),
      tagline: l10n.skyStory_tagline,
    ),
  );

  final SkyTitleCopy title;
  final List<SkyPageCopy> pages;
  final SkyOutroCopy outro;

  /// `12 – 14 June 2026` · `30 May – 2 June 2026` · `30 December 2026 –
  /// 2 January 2027` (the reference's spaced dash and full month).
  static String dateRange(DateTime start, DateTime end, String locale) {
    final full = DateFormat('d MMMM y', locale);
    if (start.year == end.year && start.month == end.month) {
      if (start.day == end.day) return full.format(start);
      return '${start.day} – ${full.format(end)}';
    }
    if (start.year == end.year) {
      return '${DateFormat('d MMMM', locale).format(start)} – '
          '${full.format(end)}';
    }
    return '${full.format(start)} – ${full.format(end)}';
  }

  @override
  List<Object?> get props => [title, pages, outro];
}

class SkyTitleCopy extends Equatable {
  const SkyTitleCopy({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  List<Object?> get props => [eyebrow, title, subtitle];
}

/// The ending under the mosaic: `187 moments`, the tagline and the brand.
class SkyOutroCopy extends Equatable {
  const SkyOutroCopy({required this.moments, required this.tagline});

  final String moments;
  final String tagline;

  /// The brand line beside the app icon: the product name, never
  /// translated (#345: the icon and Storyni replace the reference's
  /// "YOUR MEMORY COMPANION").
  static const brand = 'STORYNI';

  @override
  List<Object?> get props => [moments, tagline];
}

class SkyPageCopy extends Equatable {
  const SkyPageCopy({
    required this.layout,
    required this.eyebrow,
    required this.headline,
    required this.heroCaption,
    this.note,
    this.signature,
    this.skyText,
    this.badgeCount,
    this.badgeLabel,
  });

  factory SkyPageCopy.resolve(
    SkyPage page,
    SkyPageLayout layout,
    AppLocalizations l10n,
    String locale,
  ) {
    final badge = layout == SkyPageLayout.taped && page.photoCount > 0;
    final trimmed = page.note?.trim();
    final note = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    final signature = page.signature?.trim();
    final caption = captionFor(page.hero, page.date, l10n, locale);
    final skyLine = page.skyLine?.trim();
    // No note: the director's line on the sky, else the caption moves up
    // onto the sky, bigger, and leaves the polaroid's strip blank (#345:
    // a page without a note still looks finished).
    final skyText = note != null
        ? null
        : (skyLine != null && skyLine.isNotEmpty ? skyLine : caption);
    final captionOnSky = note == null && skyText == caption;
    return SkyPageCopy(
      layout: layout,
      eyebrow: eyebrowFor(page, l10n, locale, withCount: !badge),
      headline: headlineFor(page, l10n),
      heroCaption: captionOnSky ? '' : caption,
      note: note,
      skyText: skyText == null || skyText.isEmpty ? null : skyText,
      signature: (signature == null || signature.isEmpty || note == null)
          ? null
          : '– $signature',
      badgeCount: badge ? '${page.photoCount}' : null,
      badgeLabel: badge
          ? l10n.skyStory_photosLabel(page.photoCount).toUpperCase()
          : null,
    );
  }

  /// The director's headline; without one, the place most of the page's
  /// photos share (`Alfama`), else `Day 2` / `Days 4–7`.
  static String headlineFor(SkyPage page, AppLocalizations l10n) {
    final headline = page.headline?.trim();
    if (headline != null && headline.isNotEmpty) return headline;
    final counts = <String, int>{};
    for (final photo in [page.hero, ...page.extras]) {
      final place = photo.place?.trim();
      if (place != null && place.isNotEmpty) {
        counts[place] = (counts[place] ?? 0) + 1;
      }
    }
    if (counts.isNotEmpty) {
      // The most shared; on a tie, the hero's (it comes first).
      return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    }
    final last = page.lastDay;
    return last != null && last != page.firstDay
        ? l10n.skyStory_days(page.firstDay, last)
        : l10n.skyStory_day(page.firstDay);
  }

  /// `DAY 1 · FRI 12 JUNE · 64 PHOTOS`. A taped page shows its count in
  /// the badge instead; a page with no photos counted leaves it out.
  static String eyebrowFor(
    SkyPage page,
    AppLocalizations l10n,
    String locale, {
    bool withCount = true,
  }) {
    final last = page.lastDay;
    final end = page.endDate;
    final String day;
    final String date;
    if (last != null && last != page.firstDay) {
      day = l10n.skyStory_days(page.firstDay, last);
      date = end == null
          ? DateFormat('d MMMM', locale).format(page.date)
          : _dayRange(page.date, end, locale);
    } else {
      day = l10n.skyStory_day(page.firstDay);
      date = DateFormat('EEE d MMMM', locale).format(page.date);
    }
    return [
      day,
      date,
      if (withCount && page.photoCount > 0)
        l10n.skyStory_photoCount(page.photoCount),
    ].join(' · ').toUpperCase();
  }

  /// `12–14 June` · `30 May – 2 June`.
  static String _dayRange(DateTime start, DateTime end, String locale) {
    final dayMonth = DateFormat('d MMMM', locale);
    if (start.month == end.month && start.year == end.year) {
      return '${start.day}–${dayMonth.format(end)}';
    }
    return '${dayMonth.format(start)} – ${dayMonth.format(end)}';
  }

  /// `Alfama · Fri morning`: the place, then when. Without a time taken,
  /// just the page's weekday (`Cascais · Sun`).
  static String captionFor(
    SkyPhoto photo,
    DateTime pageDate,
    AppLocalizations l10n,
    String locale,
  ) {
    final taken = photo.takenAt;
    final weekday = DateFormat('EEE', locale).format(taken ?? pageDate);
    final when = taken == null
        ? weekday
        : switch (taken.hour) {
            < 5 => l10n.skyStory_night(weekday),
            < 12 => l10n.skyStory_morning(weekday),
            < 17 => l10n.skyStory_afternoon(weekday),
            < 21 => l10n.skyStory_evening(weekday),
            _ => l10n.skyStory_night(weekday),
          };
    final place = photo.place?.trim();
    return [if (place != null && place.isNotEmpty) place, when].join(' · ');
  }

  final SkyPageLayout layout;
  final String eyebrow;
  final String headline;

  /// On the hero's strip; empty when it's on the sky instead ([skyText]).
  final String heroCaption;
  final String? note;

  /// Written on the sky when the page has no note: the director's line,
  /// else the hero's caption.
  final String? skyText;

  /// `– Jonas`, only under a note.
  final String? signature;

  /// The taped page's round badge: `71` over `PHOTOS`.
  final String? badgeCount;
  final String? badgeLabel;

  @override
  List<Object?> get props => [
    layout,
    eyebrow,
    headline,
    heroCaption,
    note,
    skyText,
    signature,
    badgeCount,
    badgeLabel,
  ];
}
