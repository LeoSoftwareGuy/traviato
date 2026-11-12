import 'package:flutter/painting.dart';

import 'sky_handwriting.dart';
import 'sky_polaroid.dart';
import 'sky_story.dart';
import 'sky_story_copy.dart';
import 'sky_story_tokens.dart';

/// Every word of the film laid out once (#345), in canvas px: the frame
/// only moves and fades them. Rebuilt when the language changes; dispose
/// when replaced.
class SkyStoryTexts {
  SkyStoryTexts(SkyStoryCopy copy)
    : title = SkyTitleTexts(copy.title),
      outro = SkyOutroTexts(copy.outro),
      pages = [
        for (final page in copy.pages) SkyPageTexts(page, page.layout),
      ];

  final SkyTitleTexts title;
  final List<SkyPageTexts> pages;
  final SkyOutroTexts outro;

  void dispose() {
    title.dispose();
    outro.dispose();
    for (final page in pages) {
      page.dispose();
    }
  }
}

TextPainter _layout(
  String text,
  TextStyle style, {
  double maxWidth = double.infinity,
  TextAlign align = TextAlign.left,
  int? maxLines,
}) => TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
  textAlign: align,
  maxLines: maxLines,
  ellipsis: maxLines == null ? null : '…',
)..layout(maxWidth: maxWidth);

double _baseline(TextPainter p) =>
    p.computeDistanceToActualBaseline(TextBaseline.alphabetic);

/// The opening: `A MEMORY STORY` / the title / dates · names, centred
/// under the balloon (spec §5: y ≈ 1180–1600).
class SkyTitleTexts {
  factory SkyTitleTexts(SkyTitleCopy copy) {
    final title = _fitTitle(copy.title);
    final lines = title.computeLineMetrics();
    final lineHeight = lines.length > 1
        ? lines[1].baseline - lines[0].baseline
        : title.height;
    // Two lines sit as in the reference; other counts stay centred on it.
    final firstBaseline = 1345 - (lines.length - 2) * lineHeight / 2;
    final titleTop = firstBaseline - lines.first.baseline;
    final eyebrow = _layout(
      copy.eyebrow,
      SkyStoryText.label(trackingEm: 0.25),
    );
    final subtitle = _layout(
      copy.subtitle,
      SkyStoryText.hand(size: 62, color: SkyStoryColors.headlineCream),
      maxWidth: 1000,
      align: TextAlign.center,
      maxLines: 1,
    );
    return SkyTitleTexts._(
      eyebrow: eyebrow,
      eyebrowAt: Offset(
        540 - eyebrow.width / 2,
        firstBaseline - 161 - eyebrow.height / 2,
      ),
      title: title,
      titleAt: Offset(540 - title.width / 2, titleTop),
      subtitle: subtitle,
      subtitleAt: Offset(
        540 - subtitle.width / 2,
        titleTop + lines.last.baseline + 112 - _baseline(subtitle),
      ),
    );
  }

  SkyTitleTexts._({
    required this.eyebrow,
    required this.eyebrowAt,
    required this.title,
    required this.titleAt,
    required this.subtitle,
    required this.subtitleAt,
  });

  static const maxWidth = 900.0;

  final TextPainter eyebrow;
  final Offset eyebrowAt;
  final TextPainter title;
  final Offset titleAt;
  final TextPainter subtitle;
  final Offset subtitleAt;

  /// 148 px (the reference measures larger than the spec's ~130), smaller until it fits in three lines.
  static TextPainter _fitTitle(String text) {
    TextPainter? painter;
    for (var size = 148.0; size >= 80; size -= 6) {
      painter?.dispose();
      painter = _layout(
        text,
        SkyStoryText.display(text, size: size, height: 1.0),
        maxWidth: maxWidth,
        align: TextAlign.center,
      );
      if (painter.computeLineMetrics().length <= 3) return painter;
    }
    painter!.dispose();
    return _layout(
      text,
      SkyStoryText.display(text, size: 80, height: 1.0),
      maxWidth: maxWidth,
      align: TextAlign.center,
      maxLines: 3,
    );
  }

  void dispose() {
    eyebrow.dispose();
    title.dispose();
    subtitle.dispose();
  }
}

/// One page's words (spec §4): the eyebrow and headline at the left
/// margin, the hero's caption, the note and its signature, and the
/// taped page's badge.
class SkyPageTexts {
  factory SkyPageTexts(SkyPageCopy copy, SkyPageLayout layout) {
    final headline = _fitHeadline(copy.headline);
    final twoLines = headline.computeLineMetrics().length > 1;
    // A two-line headline pushes the header up rather than into the hero.
    final lift = twoLines
        ? headline.computeLineMetrics()[1].baseline -
              headline.computeLineMetrics()[0].baseline
        : 0.0;
    final eyebrow = _layout(copy.eyebrow, SkyStoryText.label());
    final onSky = layout == SkyPageLayout.flyOut;
    final note = copy.note;
    return SkyPageTexts._(
      eyebrow: eyebrow,
      eyebrowAt: Offset(margin, 212 - lift - eyebrow.height / 2),
      headline: headline,
      headlineAt: Offset(
        margin,
        320 - lift - headline.computeLineMetrics().first.baseline,
      ),
      caption: _layout(
        copy.heroCaption,
        SkyStoryText.hand(size: 44),
        maxWidth: SkyPolaroidFrame.hero.photo.width,
        maxLines: 1,
      ),
      noteLines: note == null || onSky
          ? const []
          : [
              for (final line in wrapWords(note, noteWidth, _measureNote))
                _layout(line, _noteStyle),
            ],
      quote: switch ((note, copy.skyText)) {
        (final note?, _) when onSky => SkyQuoteTexts(note),
        (null, final line?) => SkyQuoteTexts(line),
        _ => null,
      },
      signature: copy.signature == null
          ? null
          : _layout(
              copy.signature!,
              onSky
                  ? SkyStoryText.hand(
                      size: 64,
                      color: SkyStoryColors.eyebrowGold,
                      bold: true,
                    )
                  : SkyStoryText.hand(
                      size: 56,
                      color: SkyStoryColors.signatureRed,
                      bold: true,
                    ),
            ),
      badgeCount: copy.badgeCount == null
          ? null
          : _layout(
              copy.badgeCount!,
              SkyStoryText.display(
                copy.badgeCount!,
                size: 84,
                color: SkyStoryColors.eyebrowGold,
              ),
            ),
      badgeLabel: copy.badgeLabel == null
          ? null
          : _layout(
              copy.badgeLabel!,
              SkyStoryText.label(size: 22, trackingEm: 0.2),
            ),
    );
  }

  SkyPageTexts._({
    required this.eyebrow,
    required this.eyebrowAt,
    required this.headline,
    required this.headlineAt,
    required this.caption,
    required this.noteLines,
    required this.quote,
    required this.signature,
    required this.badgeCount,
    required this.badgeLabel,
  });

  static const margin = 76.0;
  static const headlineMaxWidth = 760.0;

  /// The note's lines on its card; three at most, the signature on the
  /// fourth rule.
  static const noteWidth = 635.0;

  static final _noteStyle = SkyStoryText.hand(size: 56);

  static double _measureNote(String text) {
    final painter = _layout(text, _noteStyle);
    final width = painter.width;
    painter.dispose();
    return width;
  }

  final TextPainter eyebrow;
  final Offset eyebrowAt;
  final TextPainter headline;
  final Offset headlineAt;
  final TextPainter caption;

  /// The note on a card (fan, taped).
  final List<TextPainter> noteLines;

  /// Words on the night sky: the fly-out page's note, or a page's line
  /// when it has no note (`SkyPageCopy.skyText`).
  final SkyQuoteTexts? quote;
  final TextPainter? signature;
  final TextPainter? badgeCount;
  final TextPainter? badgeLabel;

  /// 92 px on one line, down to 64; past that, two lines at 64.
  static TextPainter _fitHeadline(String text) {
    for (var size = 92.0; size >= 64; size -= 4) {
      final painter = _layout(
        text,
        SkyStoryText.display(text, size: size),
        maxWidth: headlineMaxWidth,
      );
      if (painter.computeLineMetrics().length == 1) return painter;
      painter.dispose();
    }
    return _layout(
      text,
      SkyStoryText.display(text, size: 64, height: 1.05),
      maxWidth: headlineMaxWidth,
      maxLines: 2,
    );
  }

  void dispose() {
    eyebrow.dispose();
    headline.dispose();
    caption.dispose();
    for (final line in noteLines) {
      line.dispose();
    }
    quote?.dispose();
    signature?.dispose();
    badgeCount?.dispose();
    badgeLabel?.dispose();
  }
}

/// The fly-out page's note on the sky (Caveat ~64 as measured, centred, 80 px
/// lines), word by word, so each word can settle on its own.
class SkyQuoteTexts {
  factory SkyQuoteTexts(String note) {
    final style = SkyStoryText.hand(
      size: 64,
      color: SkyStoryColors.headlineCream,
    );
    double measure(String text) {
      final painter = _layout(text, style);
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final space = measure('a a') - measure('aa');
    final words = <(TextPainter, Offset)>[];
    final lines = wrapWords(note, maxWidth, measure, maxLines: 4);
    for (final (row, line) in lines.indexed) {
      final painters = [for (final w in line.split(' ')) _layout(w, style)];
      final width =
          painters.fold(0.0, (sum, p) => sum + p.width) +
          space * (painters.length - 1);
      var x = 540 - width / 2;
      for (final painter in painters) {
        final y = firstBaseline + row * lineHeight - _baseline(painter);
        words.add((painter, Offset(x, y)));
        x += painter.width + space;
      }
    }
    return SkyQuoteTexts._(words, lines.length);
  }

  SkyQuoteTexts._(this.words, this.lineCount);

  static const maxWidth = 616.0;
  static const firstBaseline = 1440.0;
  static const lineHeight = 80.0;

  /// Each word and where its top-left settles.
  final List<(TextPainter, Offset)> words;
  final int lineCount;

  /// The signature's baseline: the line after the quote.
  double get signatureBaseline => firstBaseline + lineCount * lineHeight;

  void dispose() {
    for (final (painter, _) in words) {
      painter.dispose();
    }
  }
}

/// The ending under the mosaic, centred (spec §5 / the reference at 50 s):
/// the count's baseline at y ≈ 1438, the tagline's at ≈ 1535, then the
/// app icon beside the brand line, centred on y ≈ 1655.
class SkyOutroTexts {
  factory SkyOutroTexts(SkyOutroCopy copy) {
    final moments = _layout(
      copy.moments,
      SkyStoryText.display(copy.moments, size: momentsSize),
      maxWidth: maxWidth,
      align: TextAlign.center,
      maxLines: 1,
    );
    final tagline = _layout(
      copy.tagline,
      SkyStoryText.hand(size: taglineSize, color: SkyStoryColors.eyebrowGold),
      maxWidth: maxWidth,
      align: TextAlign.center,
      maxLines: 1,
    );
    final brand = _layout(
      SkyOutroCopy.brand,
      SkyStoryText.label(
        size: brandSize,
        color: SkyStoryColors.headlineCream,
        trackingEm: 0.3,
        weight: FontWeight.w600,
      ),
    );
    // Tracking trails the last letter; centre on the letters.
    final brandWidth = brand.width - brandSize * 0.3;
    final rowLeft = 540 - (iconSize + iconGap + brandWidth) / 2;
    return SkyOutroTexts._(
      moments: moments,
      momentsAt: Offset(
        540 - moments.width / 2,
        momentsBaseline - _baseline(moments),
      ),
      tagline: tagline,
      taglineAt: Offset(
        540 - tagline.width / 2,
        taglineBaseline - _baseline(tagline),
      ),
      brand: brand,
      brandAt: Offset(
        rowLeft + iconSize + iconGap,
        brandCenterY - brand.height / 2,
      ),
      icon: Rect.fromLTWH(
        rowLeft,
        brandCenterY - iconSize / 2,
        iconSize,
        iconSize,
      ),
    );
  }

  SkyOutroTexts._({
    required this.moments,
    required this.momentsAt,
    required this.tagline,
    required this.taglineAt,
    required this.brand,
    required this.brandAt,
    required this.icon,
  });

  static const maxWidth = 960.0;
  static const momentsSize = 104.0;
  static const momentsBaseline = 1438.0;
  static const taglineSize = 62.0;
  static const taglineBaseline = 1535.0;
  static const brandSize = 34.0;
  static const brandCenterY = 1655.0;
  static const iconSize = 110.0;
  static const iconGap = 30.0;

  final TextPainter moments;
  final Offset momentsAt;
  final TextPainter tagline;
  final Offset taglineAt;
  final TextPainter brand;
  final Offset brandAt;

  /// Where the app icon sits, left of the brand line.
  final Rect icon;

  void dispose() {
    moments.dispose();
    tagline.dispose();
    brand.dispose();
  }
}
