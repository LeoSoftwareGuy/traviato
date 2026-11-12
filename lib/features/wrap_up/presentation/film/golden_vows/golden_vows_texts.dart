import 'package:flutter/painting.dart';

import '../../../../../l10n/app_localizations.dart';
import 'golden_vows_story.dart';
import 'golden_vows_tokens.dart';

/// Every word of the Golden Vows film laid out once (#346), in canvas px:
/// the frame only moves and fades them. Rebuilt when the story or the
/// language changes; dispose when replaced.
class GoldenVowsTexts {
  GoldenVowsTexts(GoldenVowsStory story, AppLocalizations l10n)
    : invitation = GvInvitationTexts(story),
      packing = story.hasPackingCard ? GvPackingTexts(story, l10n) : null;

  final GvInvitationTexts invitation;
  final GvPackingTexts? packing;

  void dispose() {
    invitation.dispose();
    packing?.dispose();
  }
}

TextPainter _layout(String text, TextStyle style) => TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
  maxLines: 1,
  ellipsis: '…',
)..layout();

/// [text] on one line in [style], shrunk until it fits [maxWidth] (never
/// below [minScale] of its size, then cut with an ellipsis).
TextPainter _fit(
  String text,
  TextStyle style,
  double maxWidth, {
  double minScale = 0.55,
}) {
  var painter = _layout(text, style);
  if (painter.width <= maxWidth) return painter;
  final size = style.fontSize!;
  final scale = (maxWidth / painter.width).clamp(minScale, 1.0);
  painter.dispose();
  painter = TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(fontSize: size * scale),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  return painter;
}

/// The invitation (spec §5.1): occasion, names, date, place. Lines the
/// memory doesn't have are null and left out.
class GvInvitationTexts {
  GvInvitationTexts(GoldenVowsStory story)
    : occasion = story.occasionLine == null
          ? null
          : _fit(
              story.occasionLine!,
              GoldenVowsType.script(104, color: GoldenVowsColors.gold),
              maxWidth,
            ),
      _names = story.names,
      _namesSize = _namesFit(story.names).$1,
      _namesTwoLines = _namesFit(story.names).$2,
      date = _layout(
        _formatDate(story.date),
        GoldenVowsType.serif(
          40,
          weight: 600,
          letterSpacing: 10,
          color: GoldenVowsColors.inkSoft,
        ),
      ),
      place = story.place == null
          ? null
          : _fit(
              story.place!,
              GoldenVowsType.serif(44, color: GoldenVowsColors.inkSoft),
              maxWidth,
            );

  /// Inside the gold frame, with room either side.
  static const maxWidth = 900.0;

  /// The names' letter-spacing as they settle, and at rest.
  static const namesSpacingFrom = 24.0;
  static const namesSpacingTo = 2.0;

  final TextPainter? occasion;
  final TextPainter date;
  final TextPainter? place;
  final String _names;
  final double _namesSize;
  final bool _namesTwoLines;

  /// The names laid out per letter-spacing step (a quarter px): they
  /// tighten over 2 s, and each step is laid out once.
  final _namesBySpacing = <int, TextPainter>{};

  /// The names at rest are 128 px; long ones shrink to fit one line, down
  /// to [minOneLineSize]. Longer still, they wrap onto two centred lines of
  /// at most [twoLineSize], which still clear the rule below.
  static const minOneLineSize = 72.0;
  static const twoLineSize = 64.0;

  static (double, bool) _namesFit(String names) {
    final probe = _namesLayout(names, 128, namesSpacingTo, twoLines: false);
    final width = probe.width;
    probe.dispose();
    if (width <= maxWidth) return (128, false);
    final size = 128 * maxWidth / width;
    if (size >= minOneLineSize) return (size, false);
    return (twoLineSize, true);
  }

  static TextPainter _namesLayout(
    String names,
    double size,
    double spacing, {
    required bool twoLines,
  }) => TextPainter(
    text: TextSpan(
      text: names,
      style: GoldenVowsType.serif(
        size,
        color: GoldenVowsColors.ink,
        letterSpacing: spacing,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: twoLines ? 2 : null,
    ellipsis: twoLines ? '…' : null,
  )..layout(maxWidth: twoLines ? maxWidth : double.infinity);

  /// The names at [spacing] px between letters.
  TextPainter names(double spacing) {
    final step = (spacing * 4).round();
    return _namesBySpacing[step] ??= _namesLayout(
      _names,
      _namesSize,
      step / 4,
      twoLines: _namesTwoLines,
    );
  }

  /// "14 · 06 · 2026": the same in every language.
  static String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)} · ${two(date.month)} · ${date.year}';
  }

  void dispose() {
    occasion?.dispose();
    date.dispose();
    place?.dispose();
    for (final painter in _namesBySpacing.values) {
      painter.dispose();
    }
    _namesBySpacing.clear();
  }
}

/// The packing card (spec §5.2): heading, "WHAT WE PACKED · X OF Y" and up
/// to 5 items in the user's own words.
class GvPackingTexts {
  GvPackingTexts(GoldenVowsStory story, AppLocalizations l10n)
    : heading = _fit(
        l10n.goldenVows_packedHeading,
        GoldenVowsType.script(96, color: GoldenVowsColors.gold),
        cardWidth - 120,
      ),
      subhead = _fit(
        l10n
            .goldenVows_packedCount(
              story.packedShown.length,
              story.packedTotal ?? story.packed.length,
            )
            .toUpperCase(),
        GoldenVowsType.serif(
          30,
          weight: 600,
          letterSpacing: 9,
          color: GoldenVowsColors.inkSoft,
        ),
        cardWidth - 120,
      ),
      items = [
        for (final item in story.packedShown)
          _fit(
            item,
            GoldenVowsType.serif(54, color: GoldenVowsColors.ink),
            itemMaxWidth,
            minScale: 0.7,
          ),
      ];

  static const cardWidth = 860.0;

  /// From the item's x (176) to inside the card's gold border.
  static const itemMaxWidth = cardWidth - 176 - 48;

  final TextPainter heading;
  final TextPainter subhead;
  final List<TextPainter> items;

  void dispose() {
    heading.dispose();
    subhead.dispose();
    for (final item in items) {
      item.dispose();
    }
  }
}
