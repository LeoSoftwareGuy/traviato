import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../film_eases.dart';
import 'neon_beat.dart';
import 'neon_chapter_card_painter.dart';
import 'neon_eases.dart';
import 'neon_moments.dart';
import 'neon_night_scene_spec.dart';
import 'neon_night_story.dart';
import 'neon_night_texts.dart';
import 'neon_photo.dart';
import 'neon_text_fx.dart';
import 'neon_tokens.dart';

/// One of a chapter's moments (#363, NEON_NIGHT_SPEC.md §5.4–5.6) at film
/// time `t`: Split, Burst, Timeline or Peak. Everything is a pure
/// function of `t`.
class NnMomentPainter {
  NnMomentPainter({
    required this.spec,
    required this.moment,
    required this.texts,
    required this.photos,
    required this.beat,
    required this.reducedFlashing,
  }) : timeline = moment is NnTimeline
           ? NnTimelineLayout(moment.photos.length)
           : null;

  final NnMomentSpec spec;
  final NnMoment moment;
  final NnMomentTexts texts;
  final NeonPhotoSource photos;
  final NeonBeat beat;
  final bool reducedFlashing;
  final NnTimelineLayout? timeline;

  /// Every frame flare is softened when reduced (§6).
  double get _flareScale => reducedFlashing ? 0.4 : 1;

  double _at(double cue, double lb) => cue + beat.beatToSec(lb);

  ui.Image? _image(int i) {
    final id = moment.photos[i].id;
    return photos.large(id) ?? photos.thumb(id);
  }

  /// The image's Ken Burns zoom across the scene: `1 + kb → 1`.
  static double _kb(double kb, double t, double cue, double duration) =>
      1 + kb * (1 - ((t - cue) / duration).clamp(0.0, 1.0));

  /// A flare on each of [beats] (lb), τ [tau]: the strongest one so far.
  double _flares(double t, double cue, List<double> beats, double tau) {
    var f = 0.0;
    for (final b in beats) {
      f = math.max(f, NeonBeat.flare(t, _at(cue, b), tau));
    }
    return f * _flareScale;
  }

  void paint(Canvas canvas, double t, double cue, double duration) {
    final lb = beat.secToBeat(t - cue);
    // Each scene's content fades out over its last 0.18 s (§5).
    final alpha = 1 - ((t - (cue + duration - 0.18)) / 0.18).clamp(0.0, 1.0);
    if (alpha <= 0) return;
    double kbT(double kb) => _kb(kb, t, cue, duration);
    switch ((moment, texts)) {
      case (NnSplit(), NnLabelTexts(:final label)):
        _split(canvas, t, cue, lb, alpha, kbT(NnMomentLayout.kbSplit));
        _label(canvas, t, cue, label, alpha);
      case (NnBurst(), NnLabelTexts(:final label)):
        _burst(canvas, t, cue, lb, alpha, kbT(NnMomentLayout.kbBurst));
        _label(canvas, t, cue, label, alpha);
      case (NnTimeline(), final NnTimelineTexts texts):
        _timeline(
          canvas,
          t,
          cue,
          lb,
          alpha,
          texts,
          kbT(NnMomentLayout.kbTimeline),
        );
      case (NnPeak(), final NnPeakTexts texts):
        _peak(canvas, t, cue, lb, alpha, texts, kbT(NnMomentLayout.kbPeak));
      default:
        break;
    }
  }

  /// The label box fades in at lb 1 over 0.3 s.
  void _label(
    Canvas canvas,
    double t,
    double cue,
    NeonLabelBox label,
    double alpha,
  ) {
    final a = FilmEases.at(t, _at(cue, 1), 0.3, FilmEases.linear) * alpha;
    label.paint(canvas, NnMomentLayout.labelAt, alpha: a);
  }

  /// Paints photo [i] in a neon frame [rect] (rounded [radius], [border]
  /// px, [color]), scaled by [scale] about its centre and turned by
  /// [degrees].
  void _framed(
    Canvas canvas,
    int i,
    Rect rect, {
    required Color color,
    required double radius,
    required double border,
    required double kb,
    double scale = 1,
    double degrees = 0,
    double f = 0,
    double alpha = 1,
    double brightness = 1,
    Rect? clip,
  }) {
    if (alpha <= 0.002) return;
    final c = rect.center;
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(degrees * math.pi / 180)
      ..scale(scale)
      ..translate(-c.dx, -c.dy);
    if (clip != null) canvas.clipRect(clip.inflate(40));
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    neonPaintPhoto(
      canvas,
      _image(i),
      rrect,
      kenBurns: kb,
      alpha: alpha,
      brightness: brightness * (1 + 0.35 * f),
    );
    neonPaintFrame(canvas, rrect, color, border: border, f: f, alpha: alpha);
    canvas.restore();
  }

  // ---- Split (§5.4a) ------------------------------------------------

  void _split(
    Canvas canvas,
    double t,
    double cue,
    double lb,
    double alpha,
    double kb,
  ) {
    final n = moment.photos.length;
    for (var i = 0; i < n; i++) {
      final e = NnSplitLayout.wipe(lb, i, beat);
      if (e <= 0) continue;
      final rect = NnSplitLayout.strip(i, n);
      final f = _flares(t, cue, NnSplitLayout.pulses(i), 0.3);
      canvas.save();
      // Wipe down: everything below the wiped edge is hidden, glow too.
      // Once wiped the strip is whole, so its pulse can grow past it.
      if (e < 1) {
        canvas.clipRect(
          Rect.fromLTRB(-100, 0, 1180, rect.top + rect.height * e),
        );
      }
      _framed(
        canvas,
        i,
        rect,
        color: NnSplitLayout.colors[i],
        radius: NnSplitLayout.radius,
        border: NnSplitLayout.border,
        kb: kb,
        scale: 1 + 0.035 * f,
        f: f,
        alpha: alpha,
      );
      canvas.restore();
    }
  }

  // ---- Burst (§5.4b) ------------------------------------------------

  void _burst(
    Canvas canvas,
    double t,
    double cue,
    double lb,
    double alpha,
    double kb,
  ) {
    final n = moment.photos.length;
    for (final i in NnBurstLayout.order(lb, n)) {
      final (popScale, popAlpha) = NnBurstLayout.pop(lb, i, beat);
      if (popAlpha <= 0) continue;
      final jump = NnBurstLayout.jump(lb, i) ?? 1;
      final f =
          math.max(
            NeonBeat.flare(t, _at(cue, 1.0 + i), 0.3),
            NeonBeat.flare(t, _at(cue, 5.0 + i), 0.35),
          ) *
          _flareScale;
      final frame = NnBurstLayout.frames[i];
      _framed(
        canvas,
        i,
        frame.rect,
        color: frame.color,
        radius: NnBurstLayout.radius,
        border: NnBurstLayout.border,
        kb: kb,
        scale: popScale * jump,
        degrees: frame.degrees,
        f: f,
        alpha: popAlpha * alpha,
      );
    }
  }

  // ---- Timeline (§5.5b) ---------------------------------------------

  void _timeline(
    Canvas canvas,
    double t,
    double cue,
    double lb,
    double alpha,
    NnTimelineTexts texts,
    double kb,
  ) {
    final layout = timeline!;
    final scroll = layout.scrollAt(lb, beat);
    final lit = layout.highlightAt(lb);
    final [clearTop, solidTop, solidBottom, clearBottom] =
        NnTimelineLayout.maskStops;
    const bounds = Rect.fromLTWH(0, 0, 1080, 1920);
    canvas.saveLayer(bounds, Paint());
    for (var i = 0; i < layout.length; i++) {
      final since = t - cue - layout.enterAt(i, beat);
      if (since < 0) continue;
      final e = NeonEases.enter((since / 0.4).clamp(0.0, 1.0));
      final a = e * alpha;
      final rect = layout.items[i].shift(Offset(0, 40 * (1 - e) - scroll));
      if (rect.bottom < clearTop - 60 || rect.top > clearBottom + 60) continue;
      // How lit item i is: 1 while it holds the highlight (fading in over
      // 0.15 s when reduced).
      var on = 0.0;
      if (lit == i) {
        on = 1;
        if (reducedFlashing) {
          final from = _at(cue, 2.0 + i);
          on = ((t - from) / 0.15).clamp(0.0, 1.0);
        }
      }
      final f =
          on * (0.4 + NeonBeat.flare(t, _at(cue, 2.0 + i), 0.3) * _flareScale);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
      neonPaintPhoto(
        canvas,
        _image(i),
        rrect,
        kenBurns: kb,
        alpha: a,
        brightness: 0.7 + 0.3 * on,
      );
      neonPaintFrame(
        canvas,
        rrect,
        Color.lerp(NeonColors.violet, NeonColors.green, on)!,
        border: 3 + 5 * on,
        f: f,
        alpha: a,
      );
      final (plain, litTime) = texts.times[i];
      final at = Offset(
        rect.center.dx - plain.width / 2,
        rect.bottom + NnTimelineLayout.timeGap,
      );
      if (on < 1) {
        neonLayer(canvas, at & plain.size, a * (1 - on), () {
          plain.paint(canvas, at);
        });
      }
      if (on > 0) {
        neonLayer(canvas, at & litTime.size, a * on, () {
          litTime.paint(canvas, at);
        }, sigma: 6);
        neonLayer(canvas, at & litTime.size, a * on, () {
          litTime.paint(canvas, at);
        });
      }
    }
    // The mask keeps the title and the safe zone clear.
    canvas
      ..drawRect(
        bounds,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            const Offset(0, 1920),
            const [
              Color(0x00000000),
              Color(0x00000000),
              Color(0xFF000000),
              Color(0xFF000000),
              Color(0x00000000),
              Color(0x00000000),
            ],
            [
              0,
              clearTop / 1920,
              solidTop / 1920,
              solidBottom / 1920,
              clearBottom / 1920,
              1,
            ],
          ),
      )
      ..restore();

    // The title stays put above the list.
    final title = texts.title;
    const at = Offset(72, 110);
    neonGlitchIn(
      canvas,
      t: t,
      at: cue,
      seed: 41,
      bounds: at & title.size,
      reducedFlashing: reducedFlashing,
      alpha: alpha,
      paintAt: (dx, a) => title.paint(canvas, at + Offset(dx, 0), alpha: a),
    );
  }

  // ---- Peak (§5.6b) -------------------------------------------------

  void _peak(
    Canvas canvas,
    double t,
    double cue,
    double lb,
    double alpha,
    NnPeakTexts texts,
    double kb,
  ) {
    _fan(canvas, t, cue, lb, alpha);
    final n = moment.photos.length;
    const pivot = NnPeakLayout.pivot;
    for (final i in NnPeakLayout.order(lb, n)) {
      final f = _flares(t, cue, NnPeakLayout.pulses(i), 0.3);
      final color = NnPeakLayout.color(i, n);
      canvas
        ..save()
        ..translate(pivot.dx, pivot.dy)
        ..rotate(NnPeakLayout.degreesAt(lb, i, n, beat) * math.pi / 180)
        ..scale(1 + 0.03 * f)
        ..translate(-pivot.dx, -pivot.dy);
      final shape = NnPeakLayout.shape;
      canvas
        ..save()
        ..clipPath(shape);
      neonPaintPhoto(
        canvas,
        _image(i),
        RRect.fromRectAndRadius(NnPeakLayout.box, Radius.zero),
        kenBurns: kb,
        alpha: alpha,
        brightness: 1 + 0.35 * f,
      );
      canvas.restore();
      Paint stroke(Color c, double width, double opacity, [double sigma = 0]) =>
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeJoin = StrokeJoin.miter
            ..color = c.withValues(alpha: (opacity * alpha).clamp(0, 1))
            ..maskFilter = sigma > 0
                ? MaskFilter.blur(BlurStyle.normal, sigma)
                : null;
      canvas
        ..drawPath(shape, stroke(color, 6, 0.6, 9 + 10 * f))
        ..drawPath(shape, stroke(color, 6, 1, 3 + 4 * f))
        ..drawPath(shape, stroke(color, 6, 1))
        ..drawPath(shape, stroke(NeonColors.white, 2, 0.9))
        ..restore();
    }

    final title = texts.title;
    final at = Offset((1080 - title.size.width) / 2, 290);
    neonGlitchIn(
      canvas,
      t: t,
      at: cue,
      seed: 61,
      bounds: at & title.size,
      reducedFlashing: reducedFlashing,
      alpha: alpha,
      paintAt: (dx, a) => title.paint(canvas, at + Offset(dx, 0), alpha: a),
    );
    final range = texts.range;
    final a = FilmEases.at(t, _at(cue, 1), 0.4, FilmEases.linear) * alpha;
    if (a > 0.002) {
      final rangeAt = Offset(
        (1080 - range.width) / 2,
        290 + 0.9 * title.fontSize + 30,
      );
      neonLayer(canvas, rangeAt & range.size, a, () {
        range.paint(canvas, rangeAt);
      });
    }
  }

  /// The laser fan behind the strips: 9 beams from the pivot, each fading
  /// out along its length. They grow in over 0.6 s, then breathe with the
  /// beat (0.5 + 0.4 × beatEnv; the punch × 0.4 when reduced).
  void _fan(Canvas canvas, double t, double cue, double lb, double alpha) {
    final grow = FilmEases.at(t, cue, 0.6, NeonEases.enter);
    if (grow <= 0) return;
    final punch = reducedFlashing ? 0.16 : 0.4;
    final opacity = (0.5 + punch * beat.beatEnv(t)) * grow * alpha;
    const pivot = NnPeakLayout.pivot;
    final length = NnPeakLayout.beamLength * grow;
    for (var k = 0; k < NnPeakLayout.beams; k++) {
      final color = NnPeakLayout.beamColor(k);
      final rect = Rect.fromLTWH(
        -NnPeakLayout.beamWidth / 2,
        -length,
        NnPeakLayout.beamWidth,
        length,
      );
      Paint beam(double o, double sigma) => Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, -length), [
          color.withValues(alpha: o),
          color.withValues(alpha: 0),
        ])
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
      canvas
        ..save()
        ..translate(pivot.dx, pivot.dy)
        ..rotate(NnPeakLayout.beamDegrees(k) * math.pi / 180)
        ..drawRect(rect, beam(0.6 * opacity, 15))
        ..drawRect(rect, beam(opacity, 1.5))
        ..restore();
    }
  }
}
