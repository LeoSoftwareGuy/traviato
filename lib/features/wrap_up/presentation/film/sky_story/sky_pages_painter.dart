import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../wrap_up_film_motion.dart';
import 'sky_balloon.dart';
import 'sky_balloon_path.dart';
import 'sky_handwriting.dart';
import 'sky_page_beats.dart';
import 'sky_photo_images.dart';
import 'sky_polaroid.dart';
import 'sky_scene_spec.dart';
import 'sky_story.dart';
import 'sky_story_texts.dart';
import 'sky_story_tokens.dart';
import 'sky_world.dart';

/// Paints Sky Story's pages over the world (#345, phase 2): the title,
/// each chapter's page while it's on screen, and the big balloon on top
/// of them. A fly-out page's photos circle the balloon, so the ones on
/// the near side are painted over it.
class SkyPagesPainter extends CustomPainter {
  SkyPagesPainter({
    required this.world,
    required this.story,
    required this.texts,
    required this.images,
    required this.time,
  }) : _beats = SkyPageBeats.all(world.timeline),
       _openingEnd = world.timeline.first<SkyOpeningSpec>()!.end,
       super(repaint: Listenable.merge([time, images]));

  final SkyWorld world;
  final SkyStory story;
  final SkyStoryTexts texts;
  final SkyPhotoImages images;

  /// The film clock, in seconds.
  final ValueListenable<double> time;

  final List<SkyPageBeats> _beats;
  final double _openingEnd;

  /// What a tilting page turns about: the middle of its photos and note.
  static const _pageCenter = Offset(540, 1100);

  // Layout (spec §4), canvas px.
  static const heroCenter = Offset(540, 857);
  static const tapedHeroCenter = Offset(548, 850);
  static const noteCenter = Offset(541, 1560);
  static const noteSize = Size(940, 376);
  static const orbitCenter = Offset(540, 720);
  static const orbitRadius = Offset(330, 260);

  /// One turn of the fly-out's circling photos, s.
  static const orbitPeriod = 3.0;

  /// Behind the fan's hero: offset from it and tilt (degrees).
  static const _fanSlots = [
    (Offset(-32, 12), -5.5),
    (Offset(20, 22), 4.5),
    (Offset(-20, 28), -2.0),
    (Offset(6, -6), 2.5),
  ];

  /// The taped page's grid, peeking out round the hero.
  static const _gridSlots = [
    (Offset(290, 650), -5.0),
    (Offset(794, 600), 6.0),
    (Offset(320, 1010), 3.0),
    (Offset(780, 1035), -4.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    canvas
      ..save()
      ..scale(size.width / SkyWorld.width, size.height / SkyWorld.height);
    _paintTitle(canvas, t);
    final visible = [
      for (final beats in _beats)
        if (beats.index < story.pages.length && beats.isVisibleAt(t)) beats,
    ];
    for (final beats in visible) {
      _paintPage(canvas, t, beats);
    }
    final balloon = world.balloon.at(t);
    if (balloon != null) {
      paintSkyBalloon(canvas, center: balloon.center, width: balloon.width);
    }
    for (final beats in visible) {
      if (beats.layout != SkyPageLayout.flyOut) continue;
      canvas
        ..save()
        ..translate(0, beats.fallAt(t));
      _paintOrbit(canvas, t, beats, front: true);
      canvas.restore();
    }
    canvas.restore();
  }

  // ---- Title ------------------------------------------------------------

  void _paintTitle(Canvas canvas, double t) {
    final fall = SkyTitleBeats.fallAt(t, _openingEnd);
    if (t < SkyTitleBeats.eyebrowAt || fall > SkyWorld.height) return;
    final title = texts.title;
    canvas
      ..save()
      ..translate(0, fall);
    _fadeRise(
      canvas,
      t,
      SkyTitleBeats.eyebrowAt,
      title.eyebrow,
      title.eyebrowAt,
    );
    _fadeRise(canvas, t, SkyTitleBeats.titleAt, title.title, title.titleAt);
    _fadeRise(
      canvas,
      t,
      SkyTitleBeats.subtitleAt,
      title.subtitle,
      title.subtitleAt,
    );
    canvas.restore();
  }

  // ---- Pages ------------------------------------------------------------

  void _paintPage(Canvas canvas, double t, SkyPageBeats beats) {
    final text = texts.pages[beats.index];
    canvas
      ..save()
      ..translate(0, beats.fallAt(t));
    final tilt = beats.tiltAt(t);
    if (tilt != 0) {
      canvas
        ..translate(_pageCenter.dx, _pageCenter.dy)
        ..rotate(tilt)
        ..translate(-_pageCenter.dx, -_pageCenter.dy);
    }
    _fadeRise(canvas, t, beats.headerIn, text.eyebrow, text.eyebrowAt);
    _fadeRise(canvas, t, beats.headerIn + 0.1, text.headline, text.headlineAt);
    final page = story.pages[beats.index];
    switch (beats.layout) {
      case SkyPageLayout.fan:
        _paintFan(canvas, t, beats, page, text);
        _paintNoteCard(canvas, t, beats, text, tilt: -1.1);
      case SkyPageLayout.taped:
        _paintTaped(canvas, t, beats, page, text);
        _paintNoteCard(canvas, t, beats, text, tilt: 1.0);
      case SkyPageLayout.flyOut:
        _paintOrbit(canvas, t, beats, front: false);
        _paintFlyOutHero(canvas, t, beats, page, text);
        _paintQuote(canvas, t, beats, text);
    }
    canvas.restore();
  }

  /// Day 1: photos dealt one by one into a stack, then the hero dropped on
  /// top from above.
  void _paintFan(
    Canvas canvas,
    double t,
    SkyPageBeats beats,
    SkyPage page,
    SkyPageTexts text,
  ) {
    for (final (i, photo) in page.extras.take(_fanSlots.length).indexed) {
      final u = _progress(t, beats.dealAt(i), 0.35);
      if (u <= 0) continue;
      final (offset, tilt) = _fanSlots[i];
      _withTransform(
        canvas,
        center: heroCenter + offset,
        degrees: tilt + 6 * (1 - Curves.easeOutCubic.transform(u)),
        scale: 1 + 0.12 * (1 - Curves.easeOutBack.transform(u)),
        alpha: (u * 2.5).clamp(0.0, 1.0),
        bounds: SkyPolaroidFrame.stack.paper.inflate(40),
        paint: () => paintSkyPolaroid(
          canvas,
          SkyPolaroidFrame.stack,
          image: images[photo.id],
        ),
      );
    }
    final u = _progress(t, beats.heroAt, 0.65);
    if (u <= 0) return;
    final drop = Curves.easeOutQuad.transform(u);
    _withTransform(
      canvas,
      center: heroCenter.translate(0, -1000 * (1 - drop)),
      degrees: -2.5 + 4 * (1 - drop),
      bounds: SkyPolaroidFrame.hero.paper.inflate(40),
      paint: () => paintSkyPolaroid(
        canvas,
        SkyPolaroidFrame.hero,
        image: images[page.hero.id],
        caption: text.caption,
        zoom: _kenBurns(t, beats),
      ),
    );
  }

  /// Day 2: photos dealt into a grid, the hero taped down over them, the
  /// photo count's badge popping onto its corner.
  void _paintTaped(
    Canvas canvas,
    double t,
    SkyPageBeats beats,
    SkyPage page,
    SkyPageTexts text,
  ) {
    for (final (i, photo) in page.extras.take(_gridSlots.length).indexed) {
      final u = _progress(t, beats.dealAt(i), 0.3);
      if (u <= 0) continue;
      final (center, tilt) = _gridSlots[i];
      final e = Curves.easeOutCubic.transform(u);
      _withTransform(
        canvas,
        center: center,
        degrees: tilt,
        scale: 1.1 - 0.1 * e,
        alpha: e,
        bounds: SkyPolaroidFrame.small.paper.inflate(40),
        paint: () => paintSkyPolaroid(
          canvas,
          SkyPolaroidFrame.small,
          image: images[photo.id],
        ),
      );
    }
    final u = _progress(t, beats.heroAt, 0.35);
    if (u > 0) {
      _withTransform(
        canvas,
        center: tapedHeroCenter,
        degrees: 1.5,
        scale: 1.12 - 0.12 * Curves.easeOutBack.transform(u),
        alpha: (u * 2).clamp(0.0, 1.0),
        bounds: SkyPolaroidFrame.hero.paper.inflate(80),
        paint: () {
          paintSkyPolaroid(
            canvas,
            SkyPolaroidFrame.hero,
            image: images[page.hero.id],
            caption: text.caption,
            zoom: _kenBurns(t, beats),
          );
          _paintTape(canvas);
        },
      );
    }
    _paintBadge(canvas, t, beats, text);
  }

  /// Two strips over the hero's top corners (hero-local coordinates).
  void _paintTape(Canvas canvas) {
    final paint = Paint()..color = SkyStoryColors.tape;
    for (final (center, degrees) in const [
      (Offset(-330, -400), -38.0),
      (Offset(330, -400), 38.0),
    ]) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(degrees * math.pi / 180)
        ..drawRect(
          Rect.fromCenter(center: Offset.zero, width: 200, height: 64),
          paint,
        )
        ..restore();
    }
  }

  void _paintBadge(
    Canvas canvas,
    double t,
    SkyPageBeats beats,
    SkyPageTexts text,
  ) {
    final count = text.badgeCount;
    final label = text.badgeLabel;
    if (count == null || label == null) return;
    final u = _progress(t, beats.badgeAt, 0.5);
    if (u <= 0) return;
    canvas
      ..save()
      ..translate(885, 1245)
      ..rotate(-10 * math.pi / 180)
      ..scale(Curves.easeOutBack.transform(u))
      ..drawCircle(Offset.zero, 95, Paint()..color = SkyStoryColors.badgeFill)
      ..drawCircle(
        Offset.zero,
        93,
        Paint()
          ..color = SkyStoryColors.eyebrowGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    count.paint(canvas, Offset(-count.width / 2, -count.height / 2 - 14));
    label.paint(canvas, Offset(-label.width / 2, 34));
    canvas.restore();
  }

  /// The note on its ruled card: on a fan page the text comes with the
  /// card; on a taped page the card arrives empty and the note is written
  /// on line by line. The signature goes on the next rule.
  void _paintNoteCard(
    Canvas canvas,
    double t,
    SkyPageBeats beats,
    SkyPageTexts text, {
    required double tilt,
  }) {
    if (text.noteLines.isEmpty) return;
    final u = _progress(t, beats.cardAt, 0.35);
    if (u <= 0) return;
    final e = Curves.easeOutCubic.transform(u);
    final card = Rect.fromCenter(
      center: Offset.zero,
      width: noteSize.width,
      height: noteSize.height,
    );
    final writes = beats.layout == SkyPageLayout.taped;
    final schedule = writes
        ? writeOnSchedule([
            for (final line in text.noteLines) line.width,
          ], beats.writeAt)
        : null;
    _withTransform(
      canvas,
      center: noteCenter.translate(0, 40 * (1 - e)),
      degrees: tilt,
      alpha: e,
      bounds: card.inflate(40),
      paint: () {
        final rrect = RRect.fromRectAndRadius(card, const Radius.circular(18));
        canvas
          ..drawRRect(
            rrect.shift(const Offset(0, 10)),
            Paint()
              ..color = SkyStoryColors.pageShadow
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
          )
          ..drawRRect(rrect, Paint()..color = SkyStoryColors.noteCard);
        final rule = Paint()
          ..color = SkyStoryColors.noteRule
          ..strokeWidth = 1.5;
        for (var k = 0; k < 4; k++) {
          final y = _ruleY(k);
          canvas.drawLine(Offset(-440, y), Offset(440, y), rule);
        }
        for (final (k, line) in text.noteLines.indexed) {
          final at = Offset(-411, _ruleY(k) - 10 - _baseline(line));
          final tilt = _lineTilt(beats.index, k);
          if (schedule == null) {
            _paintTilted(canvas, line, at, tilt);
            continue;
          }
          final slot = schedule[k];
          final p = ((t - slot.start) / (slot.end - slot.start)).clamp(
            0.0,
            1.0,
          );
          if (p <= 0) continue;
          canvas
            ..save()
            ..clipRect(
              Rect.fromLTRB(
                at.dx - 20,
                at.dy - 30,
                at.dx + line.width * p,
                at.dy + line.height + 30,
              ),
            );
          _paintTilted(canvas, line, at, tilt);
          canvas.restore();
        }
        final signature = text.signature;
        if (signature == null) return;
        final signAt = schedule == null
            ? beats.fanSignatureAt
            : schedule.last.end + 0.15;
        final alpha = _progress(t, signAt, 0.25);
        if (alpha <= 0) return;
        final row = text.noteLines.length;
        _paintText(
          canvas,
          signature,
          Offset(-411, _ruleY(row) - 10 - _baseline(signature)),
          alpha,
        );
      },
    );
  }

  /// Card-local y of rule [k]: 4 rules 64 px apart from 106 px down.
  static double _ruleY(int k) => -noteSize.height / 2 + 106 + 64 * k;

  /// Each handwritten line sits a little off level, as a hand would.
  static double _lineTilt(int page, int line) =>
      (rnd(page * 7 + line, 13) - 0.5) * 1.2;

  // ---- Fly-out ----------------------------------------------------------

  /// Day 3's photos circling the balloon like a carousel: the near side
  /// bigger and in front of it, the far side small and behind it. They
  /// come out of the balloon, and fly off as the hero arrives.
  void _paintOrbit(
    Canvas canvas,
    double t,
    SkyPageBeats beats, {
    required bool front,
  }) {
    final page = story.pages[beats.index];
    final photos = page.extras.take(3).toList();
    final release = Curves.easeInCubic.transform(
      _progress(t, beats.heroAt, 0.5),
    );
    if (release >= 1) return;
    for (final (i, photo) in photos.indexed) {
      final since = t - beats.dealAt(i);
      if (since <= 0) continue;
      final theta =
          2 * math.pi * (t - beats.start) / orbitPeriod +
          2 * math.pi * i / photos.length;
      final depth = math.cos(theta);
      if ((depth >= 0) != front) continue;
      final emerge = Curves.easeOutBack.transform(
        (since / 0.6).clamp(0.0, 1.0),
      );
      var center = Offset.lerp(
        SkyBalloonPath.hub.center,
        orbitCenter.translate(
          -orbitRadius.dx * math.sin(theta),
          orbitRadius.dy * depth,
        ),
        emerge,
      )!;
      center = orbitCenter + (center - orbitCenter) * (1 + 2.5 * release);
      final scale = mix(0.31, 0.85, (depth + 1) / 2) * emerge.clamp(0.0, 1.0);
      final alpha = (since / 0.25).clamp(0.0, 1.0) * (1 - release);
      if (scale <= 0.01 || alpha <= 0.01) continue;
      _withTransform(
        canvas,
        center: center,
        degrees: 6 * math.sin(theta + i),
        scale: scale,
        alpha: alpha,
        bounds: SkyPolaroidFrame.small.paper.inflate(40),
        paint: () => paintSkyPolaroid(
          canvas,
          SkyPolaroidFrame.small,
          image: images[photo.id],
        ),
      );
    }
  }

  /// The hero spins in out of the balloon, overshoots and settles, with a
  /// warm halo that fades once it's down.
  void _paintFlyOutHero(
    Canvas canvas,
    double t,
    SkyPageBeats beats,
    SkyPage page,
    SkyPageTexts text,
  ) {
    final since = t - beats.heroAt;
    if (since <= 0) return;
    final haloAlpha =
        0.55 *
        (since / 0.3).clamp(0.0, 1.0) *
        (1 - ((since - 1.15) / 0.6).clamp(0.0, 1.0));
    if (haloAlpha > 0.01) {
      canvas.drawCircle(
        heroCenter,
        640,
        Paint()
          ..shader = ui.Gradient.radial(
            heroCenter,
            640,
            [
              SkyStoryColors.halo.withValues(alpha: haloAlpha),
              SkyStoryColors.halo.withValues(alpha: haloAlpha * 0.35),
              SkyStoryColors.halo.withValues(alpha: 0),
            ],
            const [0.45, 0.7, 1],
          ),
      );
    }
    final land = (since / 0.6).clamp(0.0, 1.0);
    final spin = const ElasticOutCurve(0.4).transform(
      (since / 1.0).clamp(0.0, 1.0),
    );
    _withTransform(
      canvas,
      center: Offset.lerp(
        SkyBalloonPath.hub.center.translate(0, 40),
        heroCenter,
        Curves.easeOutCubic.transform(land),
      )!,
      degrees: -95 + 92 * spin,
      scale: 0.3 + 0.7 * Curves.easeOutBack.transform(land),
      alpha: (since / 0.15).clamp(0.0, 1.0),
      bounds: SkyPolaroidFrame.hero.paper.inflate(40),
      paint: () => paintSkyPolaroid(
        canvas,
        SkyPolaroidFrame.hero,
        image: images[page.hero.id],
        caption: text.caption,
        zoom: _kenBurns(t, beats),
      ),
    );
  }

  /// The note on the night sky: each word drifts up into place and fades
  /// in, one after another; then the gold signature.
  void _paintQuote(
    Canvas canvas,
    double t,
    SkyPageBeats beats,
    SkyPageTexts text,
  ) {
    final quote = text.quote;
    if (quote == null) return;
    for (final (k, (word, at)) in quote.words.indexed) {
      final u = _progress(t, beats.cardAt + 0.08 * k, 0.7);
      if (u <= 0) continue;
      final rest = 1 - Curves.easeOutCubic.transform(u);
      final from = Offset((rnd(k, 3) - 0.5) * 160, 150 + rnd(k, 5) * 200);
      final center = at + Offset(word.width / 2, word.height / 2) + from * rest;
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate((rnd(k, 7) - 0.5) * 0.4 * rest);
      _paintText(
        canvas,
        word,
        Offset(-word.width / 2, -word.height / 2),
        u.clamp(0.0, 1.0),
      );
      canvas.restore();
    }
    final signature = text.signature;
    if (signature == null) return;
    final signAt = beats.cardAt + 0.08 * quote.words.length + 0.9;
    final alpha = _progress(t, signAt, 0.3);
    if (alpha <= 0) return;
    _paintText(
      canvas,
      signature,
      Offset(
        540 - signature.width / 2,
        quote.signatureBaseline - _baseline(signature),
      ),
      alpha,
    );
  }

  // ---- Helpers ----------------------------------------------------------

  /// The hero photo's slow push-in over its page.
  static double _kenBurns(double t, SkyPageBeats beats) =>
      1 +
      0.04 *
          ((t - beats.heroAt) / (beats.exitStart - beats.heroAt)).clamp(
            0.0,
            1.0,
          );

  static double _progress(double t, double start, double dur) =>
      ((t - start) / dur).clamp(0.0, 1.0);

  static double _baseline(TextPainter p) =>
      p.computeDistanceToActualBaseline(TextBaseline.alphabetic);

  /// Fades [painter] up into place: 0.6 s, rising 40 px, power3 out.
  static void _fadeRise(
    Canvas canvas,
    double t,
    double start,
    TextPainter painter,
    Offset at,
  ) {
    final u = _progress(t, start, 0.6);
    if (u <= 0) return;
    final e = Curves.easeOutCubic.transform(u);
    _paintText(canvas, painter, at.translate(0, 40 * (1 - e)), e);
  }

  static void _paintText(
    Canvas canvas,
    TextPainter painter,
    Offset at,
    double alpha,
  ) {
    if (alpha >= 0.999) {
      painter.paint(canvas, at);
      return;
    }
    canvas.saveLayer(
      (at & painter.size).inflate(24),
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
    );
    painter.paint(canvas, at);
    canvas.restore();
  }

  static void _paintTilted(
    Canvas canvas,
    TextPainter painter,
    Offset at,
    double degrees,
  ) {
    canvas
      ..save()
      ..translate(at.dx, at.dy + painter.height)
      ..rotate(degrees * math.pi / 180);
    painter.paint(canvas, Offset(0, -painter.height));
    canvas.restore();
  }

  static void _withTransform(
    Canvas canvas, {
    required Offset center,
    required double degrees,
    required Rect bounds,
    required VoidCallback paint,
    double scale = 1,
    double alpha = 1,
  }) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(degrees * math.pi / 180)
      ..scale(scale);
    if (alpha < 0.999) {
      canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    }
    paint();
    if (alpha < 0.999) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(SkyPagesPainter oldDelegate) =>
      oldDelegate.world != world ||
      oldDelegate.story != story ||
      oldDelegate.texts != texts ||
      oldDelegate.images != images ||
      oldDelegate.time != time;
}
