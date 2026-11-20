import '../../../domain/film_text_rules.dart';
import 'sky_story.dart';
import 'sky_story_texts.dart';

/// Long notes continue across a day's pages (#383, folded into #399).
///
/// When the server chose lines for the pages (#419, #422,
/// `SkyPage.noteLines`), each page shows its own lines that fit it — the
/// server already put each line on the page nearest it in time — and
/// nothing flows over; a page without lines shows its note's sentences, or
/// its fallback.
///
/// A page shows only what fits it whole: three lines on a note card, four
/// on the fly-out's sky. A day's note is split at sentence ends, in order:
/// its first page gets the first sentences that fit, the day's next page
/// (a continuation page, #378) the following ones, and so on. Nothing is
/// reworded and no page ends in "…"; a sentence too long for any page is
/// left out, and what doesn't fit the day's last page isn't shown. A page
/// left without words shows its hero's caption on the sky
/// (`SkyPageCopy.resolve`). Only the page with the note's last words is
/// signed.
///
/// [fits] says whether a text fits a page laid out as given; it measures
/// with the film's fonts by default.
SkyStory flowSkyNotes(
  SkyStory story, {
  bool Function(String text, SkyPageLayout layout) fits = SkyPageTexts.noteFits,
}) {
  final layouts = story.layouts;
  final pages = [...story.pages];
  var i = 0;
  while (i < pages.length) {
    var end = i + 1;
    while (end < pages.length && _sameDays(pages[end], pages[i])) {
      end++;
    }
    final run = [for (var j = i; j < end; j++) j];
    final note = [
      for (final j in run) pages[j].note?.trim(),
    ].nonNulls.where((n) => n.isNotEmpty).firstOrNull;
    final signature = [for (final j in run) pages[j].signature].nonNulls;
    // The server gave each page its own lines, by time (#422): each page
    // shows the ones that fit it, nothing flows over.
    if (run.any((j) => pages[j].noteLines.isNotEmpty)) {
      final chunks = <int, String>{};
      for (final j in run) {
        final own = pages[j].noteLines.isNotEmpty
            ? pages[j].noteLines
            : FilmTextRules.sentences(pages[j].note?.trim() ?? '');
        final shown = <String>[];
        for (final line in own) {
          if (fits([...shown, line].join(' '), layouts[j])) shown.add(line);
        }
        if (shown.isNotEmpty) chunks[j] = shown.join(' ');
      }
      final lastWords = chunks.keys.lastOrNull;
      final name = signature.firstOrNull ?? story.names;
      for (final j in run) {
        pages[j] = _withNote(
          pages[j],
          note: chunks[j],
          signature: j == lastWords ? name : null,
        );
      }
      i = end;
      continue;
    }
    if (note != null) {
      var rest = FilmTextRules.sentences(note);
      final chunks = <int, String>{};
      for (final j in run) {
        // Skip sentences too long for this page on their own.
        while (rest.isNotEmpty && !fits(rest.first, layouts[j])) {
          rest = rest.sublist(1);
        }
        if (rest.isEmpty) break;
        var n = 1;
        while (n < rest.length &&
            fits(rest.take(n + 1).join(' '), layouts[j])) {
          n++;
        }
        chunks[j] = rest.take(n).join(' ');
        rest = rest.sublist(n);
      }
      final lastWords = chunks.keys.lastOrNull;
      for (final j in run) {
        final chunk = chunks[j];
        pages[j] = _withNote(
          pages[j],
          note: chunk,
          signature: j == lastWords ? signature.firstOrNull : null,
        );
      }
    }
    i = end;
  }
  return SkyStory(
    title: story.title,
    startDate: story.startDate,
    endDate: story.endDate,
    names: story.names,
    pages: pages,
    momentCount: story.momentCount,
    mosaicPhotoIds: story.mosaicPhotoIds,
    targetSeconds: story.targetSeconds,
  );
}

bool _sameDays(SkyPage a, SkyPage b) =>
    a.firstDay == b.firstDay && a.lastDay == b.lastDay;

SkyPage _withNote(SkyPage page, {String? note, String? signature}) => SkyPage(
  firstDay: page.firstDay,
  lastDay: page.lastDay,
  date: page.date,
  endDate: page.endDate,
  photoCount: page.photoCount,
  hero: page.hero,
  headline: page.headline,
  extras: page.extras,
  note: note,
  signature: note == null ? null : signature,
  // A page that keeps no words of the note can carry the director's line.
  skyLine: note == null ? page.skyLine : null,
);
