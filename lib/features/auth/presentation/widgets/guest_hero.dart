import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/photo_scrim.dart';
import 'guest_images.dart';

/// Guest landing hero: 286px photo with the scrim, plus two floating
/// polaroids overhanging the bottom edge. `docs/design/README.md` § 1.
class GuestHero extends StatelessWidget {
  const GuestHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 286,
          width: double.infinity,
          child: PhotoScrim(
            image: Image.asset(
              GuestImages.hero,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.44),
            ),
            borderRadius: AppRadius.mediaRadius,
          ),
        ),
        Positioned(
          left: 24,
          bottom: -36,
          child: Transform.rotate(
            angle: -8 * math.pi / 180,
            child: const _Polaroid(
              image: GuestImages.honeymoonEscape,
              width: 104,
              height: 124,
              delayMs: 0,
            ),
          ),
        ),
        Positioned(
          right: 24,
          bottom: -28,
          child: Transform.rotate(
            angle: 7 * math.pi / 180,
            child: const _Polaroid(
              image: GuestImages.soloGetaway,
              width: 96,
              height: 114,
              delayMs: 1400,
            ),
          ),
        ),
      ],
    );
  }
}

class _Polaroid extends StatefulWidget {
  const _Polaroid({
    required this.image,
    required this.width,
    required this.height,
    required this.delayMs,
  });

  final String image;
  final double width;
  final double height;
  final int delayMs;

  @override
  State<_Polaroid> createState() => _PolaroidState();
}

class _PolaroidState extends State<_Polaroid>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.floatYMinDuration,
  );
  late final _translateY = Tween<double>(
    begin: 0,
    end: -7,
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.floatYCurve));

  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _startTimer = Timer(
      Duration(milliseconds: widget.delayMs),
      () => _controller.repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _translateY.value),
        child: child,
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 20),
        decoration: const BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.all(Radius.circular(4)),
          boxShadow: [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 34,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(2)),
          child: Image.asset(widget.image, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
