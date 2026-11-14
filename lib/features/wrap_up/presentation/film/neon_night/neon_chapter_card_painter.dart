import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../film_eases.dart';
import 'neon_ambient.dart';
import 'neon_balloon.dart';
import 'neon_beat.dart';
import 'neon_chapter_card.dart';
import 'neon_eases.dart';
import 'neon_night_scene_spec.dart';
import 'neon_night_story.dart';
import 'neon_night_timeline.dart';
import 'neon_night_texts.dart';
import 'neon_photo.dart';
import 'neon_text_fx.dart';
import 'neon_tokens.dart';
import 'neon_zoom_picks.dart';

/// Where the film's photos come from, decoded: small for the contact
/// sheets, large for the laser zooms. Null → not loaded (an empty mat).
abstract interface class NeonPhotoSource {
  ui.Image? thumb(String id);
  ui.Image? large(String id);

  /// Tiny, for the Finale's 40 px heart tiles.
  ui.Image? tile(String id);
}

/// A chapter card (#363, NEON_NIGHT_SPEC.md §5.3), at film time `t` in
/// the card starting at `cue`: header, ghost numeral, title, contact sheet
/// with its highlight, the laser zooms, the typed line and the progress
/// bar. Everything is a pure function of `t`.
class NnChapterCardPainter {
  NnChapterCardPainter({
    required this.spec,
    required this.chapter,
    required this.texts,
    required this.photos,
    required this.beat,
    required this.reducedFlashing,
  }) : sheet = NnContactSheet.forPhotos(chapter.photos.length),
       timing = NnCardTiming(
         chapterNumber: spec.chapter + 1,
         beats: spec.beats,
         zooms: spec.zooms,
         tiles: NnContactSheet.forPhotos(chapter.photos.length).tiles.length,
         beat: beat,
       );

  final NnChapterCardSpec spec;
  final NnChapter chapter;
  final NnChapterTexts texts;
  final NeonPhotoSource photos;
  final NeonBeat beat;
  final bool reducedFlashing;
  final NnContactSheet sheet;
  final NnCardTiming timing;

  Color get accent => texts.accent;

  /// Every frame flare is softened when reduced (§6).
  double get _flareScale => reducedFlashing ? 0.4 : 1;

  /// Where the progress bar sits: under the typed line, at least at y
  /// 1690; without a note, 70 px under the sheet.
  double get barTop => texts.typed == null
      ? sheet.bottom + 70
      : [
          1690.0,
          sheet.bottom + 50 + 52 * texts.typedLines + 30,
        ].reduce((a, b) => a > b ? a : b);

  static const barWidth = 636.0;
  static const barGap = 8.0;
  static const barHeight = 20.0;

  void paint(Canvas canvas, double t, double cue, double duration) {
    final lb = beat.secToBeat(t - cue);
    // Each scene's content fades out over its last 0.18 s (§5).
    final alpha = 1 - ((t - (cue + duration - 0.18)) / 0.18).clamp(0.0, 1.0);
    if (alpha <= 0) return;

    final zoom = timing.zoomAt(lb);
    final z = zoom == null ? 0.0 : NnCardTiming.zoomAmount(lb, zoom);

    _header(canvas, t, cue, alpha);
    _numeral(canvas, t, cue, lb, alpha);
    _title(canvas, t, cue, alpha);
    _sheet(
      canvas,
      t,
      cue,
      lb,
      alpha,
      hidden: z > 0 ? timing.zoomTiles[zoom!] : null,
    );
    if (z > 0) {
      canvas.drawRect(
        Offset.zero & const Size(NeonAmbient.width, NeonAmbient.height),
        Paint()..color = NeonColors.black.withValues(alpha: 0.72 * z * alpha),
      );
    }
    _typed(canvas, t, cue, lb, alpha);
    _bar(canvas, t, cue, lb, alpha);
    if (zoom != null) _zoom(canvas, t, lb, cue, zoom, z, alpha);
  }

  double _at(double cue, double lb) => cue + beat.beatToSec(lb);

  void _header(Canvas canvas, double t, double cue, double alpha) {
    final a = FilmEases.at(t, _at(cue, 0.5), 0.3, FilmEases.linear) * alpha;
    if (a <= 0) return;
    const at = Offset(72, 60);
    final header = texts.header;
    final bounds = at & header.size;
    neonLayer(canvas, bounds, a, () => header.paint(canvas, at), sigma: 7);
    neonLayer(canvas, bounds, a, () => header.paint(canvas, at));
    final rangeAt = Offset(72, 60 + header.height + 4);
    neonLayer(
      canvas,
      rangeAt & texts.range.size,
      a,
      () => texts.range.paint(canvas, rangeAt),
    );
  }

  /// The ghost numeral slams in from 1.8× pink, then turns the accent.
  void _numeral(Canvas canvas, double t, double cue, double lb, double alpha) {
    final dt = t - cue;
    if (dt < 0) return;
    final on = (dt / 0.05).clamp(0.0, 1.0) * alpha;
    final slam = NeonEases.slam((dt / 0.22).clamp(0.0, 1.0));
    final scale = 1.8 + (1 - 1.8) * slam;
    final size = texts.numeral.size;
    const at = Offset(56, 230);
    final origin = at + Offset(size.width * 0.2, size.height * 0.6);
    final g = 1 + NeonBeat.flare(t, cue, 0.3) * _flareScale;
    final toAccent = ((lb - 1) / 1).clamp(0.0, 1.0);
    canvas
      ..save()
      ..translate(origin.dx, origin.dy)
      ..scale(scale)
      ..translate(-origin.dx, -origin.dy);
    if (toAccent < 1) {
      texts.numeralPink.paint(canvas, at, alpha: on * (1 - toAccent), g: g);
    }
    if (toAccent > 0) {
      texts.numeral.paint(canvas, at, alpha: on * toAccent, g: g);
    }
    canvas.restore();
  }

  void _title(Canvas canvas, double t, double cue, double alpha) {
    final title = texts.title;
    const at = Offset(72, 610);
    neonGlitchIn(
      canvas,
      t: t,
      at: _at(cue, 1),
      seed: (spec.chapter + 1) * 7,
      bounds: at & title.size,
      reducedFlashing: reducedFlashing,
      alpha: alpha,
      paintAt: (dx, a) => title.paint(canvas, at + Offset(dx, 0), alpha: a),
    );
  }

  void _sheet(
    Canvas canvas,
    double t,
    double cue,
    double lb,
    double alpha, {
    int? hidden,
  }) {
    final lit = timing.highlightAt(lb, reducedFlashing: reducedFlashing);
    final order = [
      for (var k = 0; k < sheet.tiles.length; k++)
        if (!lit.containsKey(k)) k,
      ...(lit.keys.toList()..sort((a, b) => lit[a]!.compareTo(lit[b]!))),
    ];
    for (final k in order) {
      if (k == hidden) continue;
      final p = ((t - cue - timing.popAt(k)) / 0.3).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final pop = 0.7 + 0.3 * NeonEases.pop(p);
      final s = lit[k] ?? 0;
      final rect = sheet.tiles[k];
      final scale = pop * (1 + 0.06 * s);
      final a = (p * 4).clamp(0.0, 1.0) * alpha;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: rect.width * scale,
          height: rect.height * scale,
        ),
        const Radius.circular(NnContactSheet.radius),
      );
      if (s > 0) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = accent.withValues(alpha: s * a)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
        );
      }
      neonPaintPhoto(
        canvas,
        photos.thumb(chapter.photos[k].id),
        rrect,
        brightness: 1 + 0.5 * s,
        alpha: a,
      );
      if (s > 0) {
        canvas
          ..save()
          ..clipRRect(rrect)
          ..drawRect(
            rrect.outerRect,
            Paint()
              ..blendMode = BlendMode.screen
              ..color = accent.withValues(alpha: 0.38 * s * a),
          )
          ..restore();
      }
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = NnContactSheet.border
        ..color = accent.withValues(alpha: a);
      canvas
        ..drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = NnContactSheet.border
            ..color = accent.withValues(alpha: a)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        )
        ..drawRRect(rrect, border);
    }
  }

  /// `> NOTE`, one character per frame from lb 4, and a cursor blinking
  /// on half beats.
  void _typed(Canvas canvas, double t, double cue, double lb, double alpha) {
    final typed = texts.typed;
    if (typed == null || lb < NnCardTiming.typeFrom) return;
    final from = _at(cue, NnCardTiming.typeFrom);
    final chars = ((t - from) * NeonBeat.fps + 1e-9).floor() + 1;
    final shown = chars.clamp(0, texts.typedLength);
    final at = Offset(72, sheet.bottom + 50);
    final boxes = typed.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: shown),
    );
    final clip = Path();
    for (final box in boxes) {
      clip.addRect(box.toRect().shift(at).inflate(1));
    }
    final bounds = at & typed.size;
    canvas
      ..save()
      ..clipPath(clip);
    neonLayer(canvas, bounds, alpha, () => typed.paint(canvas, at), sigma: 6);
    neonLayer(canvas, bounds, alpha, () => typed.paint(canvas, at));
    canvas.restore();

    if ((lb * 2).floor().isOdd) return;
    final caret = typed.getOffsetForCaret(
      TextPosition(offset: shown),
      Rect.zero,
    );
    final cursor = Rect.fromLTWH(
      at.dx + caret.dx + 2,
      at.dy + caret.dy + 6,
      14,
      40,
    );
    neonLayer(canvas, cursor, alpha, () {
      canvas.drawRect(cursor, Paint()..color = accent);
    }, sigma: 6);
    canvas.drawRect(cursor, Paint()..color = accent.withValues(alpha: alpha));
  }

  /// N segments: earlier chapters full, this one filling over lb 3–5.
  void _bar(Canvas canvas, double t, double cue, double lb, double alpha) {
    if (lb < NnCardTiming.barFrom) return;
    final n = spec.chapters;
    final segment = (barWidth - barGap * (n - 1)) / n;
    final fill = FilmEases.at(
      t,
      _at(cue, NnCardTiming.barFrom),
      beat.beatToSec(2),
      NeonEases.enter,
    );
    final top = barTop;
    for (var i = 0; i < n; i++) {
      final rect = Rect.fromLTWH(
        72 + i * (segment + barGap),
        top,
        segment,
        barHeight,
      );
      final done = i < spec.chapter ? 1.0 : (i == spec.chapter ? fill : 0.0);
      if (done > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(rect.left, rect.top, rect.width * done, rect.height),
            const Radius.circular(4),
          ),
          Paint()..color = accent.withValues(alpha: 0.8 * alpha),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: 0.53 * alpha),
      );
    }
  }

  /// One laser zoom: the laser from the sign's basket to the tile, the
  /// photo flying out to 900 × 900 and back, its time label.
  void _zoom(
    Canvas canvas,
    double t,
    double lb,
    double cue,
    int cycle,
    double z,
    double alpha,
  ) {
    final k = timing.zoomTiles[cycle];
    final tile = sheet.tiles[k];
    final rect = Rect.lerp(tile, NnCardTiming.zoomRect, z)!;
    final (hit, land) = timing.zoomHits(cycle);
    if (z > 0) {
      final f = NeonBeat.flare(t, cue + land, 0.3) * _flareScale;
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(10 + 12 * z),
      );
      final c = NeonZoomPicks.cycleStarts[cycle].toDouble();
      final kb = 1.08 - 0.08 * ((lb - c - 0.5) / 2.5).clamp(0.0, 1.0);
      final id = chapter.photos[k].id;
      neonPaintPhoto(
        canvas,
        photos.large(id) ?? photos.thumb(id),
        rrect,
        brightness: 1 + 0.35 * f,
        kenBurns: kb,
        alpha: alpha,
      );
      neonPaintFrame(
        canvas,
        rrect,
        accent,
        border: 3 + 3 * z,
        f: f,
        alpha: alpha,
      );
      texts.tileLabels[k]?.paint(
        canvas,
        NnCardTiming.zoomLabel,
        alpha: z * alpha,
      );
    }

    final (length, laserAlpha) = NnCardTiming.laserAt(lb, cycle);
    if (length <= 0 || laserAlpha <= 0) return;
    const from = NeonBalloon.emitter;
    final tip = Offset.lerp(from, rect.center, length)!;
    final a = laserAlpha * alpha;
    for (final sigma in const [22.0, 11.0, 4.0]) {
      canvas.drawLine(
        from,
        tip,
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
    }
    canvas.drawLine(
      from,
      tip,
      Paint()
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = NeonColors.white.withValues(alpha: a),
    );
    // The hit flare (τ 0.25) on a spot that stays lit while the laser is
    // on, as in the reference MP4.
    final spot = t < cue + hit
        ? 0.0
        : a * (0.55 + 0.45 * NeonBeat.flare(t, cue + hit, 0.25) * _flareScale);
    if (spot > 0.002) {
      canvas.drawCircle(
        tip,
        40,
        Paint()
          ..shader = ui.Gradient.radial(
            tip,
            40,
            [
              NeonColors.white.withValues(alpha: spot),
              accent.withValues(alpha: spot),
              accent.withValues(alpha: 0),
            ],
            const [0, 0.3, 1],
          ),
      );
    }
  }
}

/// Layer 7 (§4): the pink slam flash on every chapter card's cue, above
/// the lasers and the sign. Opacity 0.4, τ 0.16 s; reduced 0.12, τ 0.4 s.
/// The only full-frame flash a card makes; zoom hits stay local.
class NeonFlashPainter extends CustomPainter {
  NeonFlashPainter({
    required this.timeline,
    required this.time,
    this.reducedFlashing = false,
  }) : super(repaint: time);

  final NeonNightTimeline timeline;
  final ValueListenable<double> time;
  final bool reducedFlashing;

  /// The chapter slam's opacity at [t] (pink).
  double flashAt(double t) {
    final (:scene, lb: _) = timeline.sceneAt(t);
    if (scene.spec is! NnChapterCardSpec) return 0;
    return reducedFlashing
        ? 0.12 * NeonBeat.flare(t, scene.start, 0.4)
        : 0.4 * NeonBeat.flare(t, scene.start, 0.16);
  }

  /// The Finale's white → violet flash at [t] (§5.8): the drop (0.5, τ
  /// 0.12; reduced 0.12, τ 0.4) plus the glow-up at lb 8 (0.22, τ 0.5;
  /// reduced 0.08).
  double dropAt(double t) {
    final (:scene, lb: _) = timeline.sceneAt(t);
    if (scene.spec is! NnFinaleSpec) return 0;
    final cue = scene.start;
    final glowUp = cue + timeline.beat.beatToSec(8);
    return reducedFlashing
        ? 0.12 * NeonBeat.flare(t, cue, 0.4) +
              0.08 * NeonBeat.flare(t, glowUp, 0.5)
        : 0.5 * NeonBeat.flare(t, cue, 0.12) +
              0.22 * NeonBeat.flare(t, glowUp, 0.5);
  }

  /// Radial from (30 %, 25 %), pink fading out 70 % of the way to the
  /// farthest corner.
  static const _centre = Offset(
    0.3 * NeonAmbient.width,
    0.25 * NeonAmbient.height,
  );
  static final double _reach =
      (const Offset(NeonAmbient.width, NeonAmbient.height) - _centre).distance;

  @override
  void paint(Canvas canvas, Size size) {
    final drop = dropAt(time.value).clamp(0.0, 1.0);
    if (drop > 0.002) {
      // Radial `#FFF 0% → violet@70% 55% → 0`, from the frame's centre to
      // its farthest corner.
      final centre = size.center(Offset.zero);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(
            centre,
            centre.distance,
            [
              NeonColors.white.withValues(alpha: drop),
              NeonColors.violet.withValues(alpha: 0.7 * drop),
              NeonColors.violet.withValues(alpha: 0),
            ],
            const [0, 0.55, 1],
          ),
      );
    }
    final a = flashAt(time.value);
    if (a <= 0.002) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          _centre,
          _reach,
          [
            NeonColors.pink.withValues(alpha: a),
            NeonColors.pink.withValues(alpha: 0),
          ],
          const [0, 0.7],
        ),
    );
  }

  @override
  bool shouldRepaint(NeonFlashPainter oldDelegate) =>
      oldDelegate.timeline != timeline ||
      oldDelegate.reducedFlashing != reducedFlashing;
}
