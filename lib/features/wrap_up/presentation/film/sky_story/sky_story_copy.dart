import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import 'sky_story.dart';

/// Sky Story's words in the film's language (#345): composed once per
/// language from `SkyStory`, then painted every frame.
class SkyStoryCopy extends Equatable {
  const SkyStoryCopy({required this.title, required this.pages});

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
      for (final (i, page) in story.pages.indexed)
        SkyPageCopy.resolve(
          page,
          SkyPageLayout.forChapter(i, story.pages.length),
          l10n,
          locale,
        ),
    ],
  );

  final SkyTitleCopy title;
  final List<SkyPageCopy> pages;

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
  List<Object?> get props => [title, pages];
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

class SkyPageCopy extends Equatable {
  const SkyPageCopy({
    required this.eyebrow,
    required this.headline,
    required this.heroCaption,
    this.note,
    this.signature,
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
    return SkyPageCopy(
      eyebrow: eyebrowFor(page, l10n, locale, withCount: !badge),
      headline: page.headline.trim(),
      heroCaption: captionFor(page.hero, page.date, l10n, locale),
      note: note,
      signature: (signature == null || signature.isEmpty || note == null)
          ? null
          : '– $signature',
      badgeCount: badge ? '${page.photoCount}' : null,
      badgeLabel: badge
          ? l10n.skyStory_photosLabel(page.photoCount).toUpperCase()
          : null,
    );
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

  final String eyebrow;
  final String headline;
  final String heroCaption;
  final String? note;

  /// `– Jonas`, only under a note.
  final String? signature;

  /// The taped page's round badge: `71` over `PHOTOS`.
  final String? badgeCount;
  final String? badgeLabel;

  @override
  List<Object?> get props => [
    eyebrow,
    headline,
    heroCaption,
    note,
    signature,
    badgeCount,
    badgeLabel,
  ];
}
