import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../film_eases.dart';
import '../marks/balloon_mark.dart';
import 'golden_vows_ambient.dart';
import 'golden_vows_texts.dart';
import 'golden_vows_timeline.dart';
import 'golden_vows_tokens.dart';

typedef _E = FilmEases;

/// The invitation and the packing card (#346, spec §5.1–5.2), between the
/// light leaks and the album in the spec's layer order.
class GoldenVowsIntroPainter extends CustomPainter {
  GoldenVowsIntroPainter({
    required this.timeline,
    required this.texts,
    required this.time,
  }) : super(repaint: time);

  final GoldenVowsTimeline timeline;
  final GoldenVowsTexts texts;
  final ValueListenable<double> time;

  static const balloon = BalloonMark(style: GoldenVowsColors.balloon);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    if (t < GvInvitationMotion.end) _paintInvitation(canvas, t);
    final packing = texts.packing;
    final card = timeline.packingCardStart;
    if (packing != null && card != null) {
      final local = t - card;
      if (local >= 0 && local <= GvCardMotion.gone) {
        _paintCard(canvas, local, packing);
      }
    }
  }

  // ---- Invitation ------------------------------------------------------

  void _paintInvitation(Canvas canvas, double t) {
    final inv = texts.invitation;
    balloon.paint(
      canvas,
      topLeft: Offset(
        GvInvitationMotion.balloonX,
        GvInvitationMotion.balloonY(t),
      ),
      rotationDeg: GvInvitationMotion.balloonRock(t),
    );

    // Each line: (painter, top, opacity, extra blur), then the exit.
    var order = 0;
    void line(
      TextPainter painter,
      double top,
      double opacity, {
      double blur = 0,
    }) {
      final exit = GvInvitationMotion.exit(t, order++);
      final alpha = opacity * (1 - exit);
      if (alpha <= 0.002) return;
      final offset = Offset(
        (GoldenVowsAmbient.width - painter.width) / 2,
        top - 60 * exit,
      );
      _paintText(canvas, painter, offset, alpha, blur: blur);
    }

    final occasion = inv.occasion;
    if (occasion != null) {
      final p = _E.at(t, 1.5, 1.6, _E.power3Out);
      line(occasion, 740 - 40 * p, p);
    }

    final names = _E.at(t, 1.9, 2.0, _E.power3Out);
    line(
      inv.names(
        GvInvitationTexts.namesSpacingFrom +
            (GvInvitationTexts.namesSpacingTo -
                    GvInvitationTexts.namesSpacingFrom) *
                names,
      ),
      840,
      names,
      blur: 10 * (1 - names),
    );

    // The rule grows from its centre.
    final rule = _E.at(t, 2.5, 1.4);
    final ruleExit = GvInvitationMotion.exit(t, order++);
    if (rule > 0 && ruleExit < 1) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(540, 1021 - 60 * ruleExit),
          width: 300 * rule,
          height: 2,
        ),
        Paint()..color = GoldenVowsColors.gold.withValues(alpha: 1 - ruleExit),
      );
    }

    final date = _E.at(t, 2.8, 1.2);
    line(inv.date, 1080 - 20 * date, date);

    final place = inv.place;
    if (place != null) {
      final p = _E.at(t, 3.05, 1.2);
      line(place, 1140 - 20 * p, p);
    }
  }

  // ---- Packing card ----------------------------------------------------

  void _paintCard(Canvas canvas, double t, GvPackingTexts packing) {
    final count = packing.items.length;
    final height = GvCardMotion.height(count);
    final top = GvCardMotion.top(t);
    final angle = GvCardMotion.rotation(t);
    const width = GvPackingTexts.cardWidth;
    final rect = Rect.fromLTWH(0, 0, width, height);

    canvas
      ..save()
      ..translate(GvCardMotion.left + width / 2, top + height / 2)
      ..rotate(angle * math.pi / 180)
      ..translate(-width / 2, -height / 2);

    final card = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas
      ..drawRRect(card.shift(const Offset(0, 18)), _cardShadow)
      ..drawRRect(card, Paint()..color = GoldenVowsColors.paper)
      ..drawRect(
        rect.deflate(24),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = GoldenVowsColors.gold.withAlpha(170),
      );

    _paintText(
      canvas,
      packing.heading,
      Offset((width - packing.heading.width) / 2, 70),
      1,
    );
    _paintText(
      canvas,
      packing.subhead,
      Offset((width - packing.subhead.width) / 2, 222),
      1,
    );

    for (var i = 0; i < count; i++) {
      final slide = _E.at(t, GvCardMotion.itemAt(i), 0.8);
      if (slide <= 0) continue;
      canvas
        ..save()
        ..translate(40 * (1 - slide), GvCardMotion.itemTop(i));
      final alpha = slide;
      canvas.drawCircle(
        const Offset(118, 44),
        27,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = GoldenVowsColors.gold.withValues(alpha: alpha),
      );
      final tick = _E.at(t, GvCardMotion.tickAt(i), 0.45);
      if (tick > 0) {
        canvas.drawPath(
          _tickMetric.extractPath(0, _tickMetric.length * tick),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = GoldenVowsColors.goldDeep.withValues(alpha: alpha),
        );
      }
      _paintText(canvas, packing.items[i], const Offset(176, 10), alpha);
      canvas.restore();
    }
    canvas.restore();
  }

  static final _cardShadow = Paint()
    ..color = const Color(0x2E423222)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

  static final ui.PathMetric _tickMetric =
      (Path()
            ..moveTo(104, 44)
            ..lineTo(115, 57)
            ..lineTo(135, 30))
          .computeMetrics()
          .first;

  /// Paints [painter] at [offset], faded to [alpha] and blurred by [blur]
  /// (a Gaussian's standard deviation, as in CSS) through one small layer.
  static void _paintText(
    Canvas canvas,
    TextPainter painter,
    Offset offset,
    double alpha, {
    double blur = 0,
  }) {
    if (alpha >= 0.999 && blur <= 0.01) {
      painter.paint(canvas, offset);
      return;
    }
    final bounds = (offset & painter.size).inflate(blur * 3 + 2);
    final layer = Paint()..color = Color.fromRGBO(0, 0, 0, alpha);
    if (blur > 0.01) {
      layer.imageFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur);
    }
    canvas.saveLayer(bounds, layer);
    painter.paint(canvas, offset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(GoldenVowsIntroPainter oldDelegate) =>
      oldDelegate.texts != texts ||
      oldDelegate.timeline != timeline ||
      oldDelegate.time != time;
}

/// The invitation's movement (spec §5.1), as functions of film time.
abstract final class GvInvitationMotion {
  /// The balloon's drawing sits at this x (centred on the frame).
  static const balloonX = 440.0;

  /// Nothing of the invitation is left after this.
  static const end = 6.4;

  static double balloonY(double t) {
    if (t < 4.6) return 1980 + (330 - 1980) * _E.at(t, 0, 3.6, _E.power2Out);
    return 330 + (-420 - 330) * _E.at(t, 4.6, 1.6, _E.power2In);
  }

  /// Rocks −6° ↔ 4°, 1.8 s per leg, 3 legs, then holds.
  static double balloonRock(double t) {
    const leg = 1.8;
    final legs = (t / leg).clamp(0.0, 3.0);
    final k = legs.floor().clamp(0, 2);
    final p = _E.sineInOut(legs - k);
    return k.isEven ? -6 + 10 * p : 4 - 10 * p;
  }

  /// How far the [index]th line has left (0–1): they rise and fade from
  /// 5.0 s, 0.06 s apart. The spec names no ease; the reference holds
  /// them until ~5.5 s and has them gone by 6.0 s, which is power2.in.
  static double exit(double t, int index) =>
      _E.at(t, 5.0 + 0.06 * index, 0.9, _E.power2In);
}

/// The packing card's movement (spec §5.2), in seconds from its start
/// (5.4 s in the reference).
abstract final class GvCardMotion {
  static const left = 110.0;

  /// It flies off from here, and is gone 1 s later.
  static const leave = 6.5;
  static const gone = leave + 1.0;

  static double height(int items) => 330 + items * 138 + 70;

  static double top(double t) {
    if (t < leave) return 2000 + (360 - 2000) * _E.at(t, 0, 1.4, _E.power3Out);
    return 360 + (-1500 - 360) * _E.at(t, leave, 1.0, _E.power2In);
  }

  static double rotation(double t) {
    if (t >= leave) return 1 + (-10 - 1) * _E.at(t, leave, 1.0, _E.power2In);
    if (t >= 1.4) return -2 + 3 * _E.at(t, 1.4, 4.5);
    return 6 - 8 * _E.at(t, 0, 1.4, _E.power3Out);
  }

  static double itemTop(int i) => 330.0 + i * 138;

  /// When item [i] slides in, and when its tick draws.
  static double itemAt(int i) => 0.9 + i * 0.14;
  static double tickAt(int i) => 2.0 + i * 0.8;
}
