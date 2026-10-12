import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/photo_scrim.dart';
import 'guest_images.dart';

/// Guest landing hero: 286px photo with the scrim, plus two drifting
/// polaroids overhanging the bottom edge. `docs/design/README.md` § 1, #195.
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
              alignment: const Alignment(0, -0.5),
            ),
            borderRadius: AppRadius.mediaRadius,
          ),
        ),
        const Positioned(
          left: 24,
          bottom: -36,
          child: _Polaroid(
            key: Key('guest-polaroid-wedding'),
            image: GuestImages.wedding,
            width: 104,
            height: 124,
            tiltDegrees: -6,
            duration: AppMotion.polaroidDriftDuration,
            phase: 0,
          ),
        ),
        // Starts half a cycle in (a negative delay), so it rises while the
        // wedding photo dips; the different duration keeps them de-synced.
        const Positioned(
          right: 24,
          bottom: -28,
          child: _Polaroid(
            key: Key('guest-polaroid-birthday'),
            image: GuestImages.birthday,
            width: 96,
            height: 114,
            tiltDegrees: 6,
            duration: AppMotion.polaroidDriftSlowDuration,
            phase: .5,
          ),
        ),
      ],
    );
  }
}

/// A polaroid that floats and sways around its resting [tiltDegrees], or
/// rests still at that tilt when the OS asks for reduced motion.
class _Polaroid extends StatefulWidget {
  const _Polaroid({
    super.key,
    required this.image,
    required this.width,
    required this.height,
    required this.tiltDegrees,
    required this.duration,
    required this.phase,
  });

  final String image;
  final double width;
  final double height;
  final double tiltDegrees;
  final Duration duration;

  /// Where in the loop (0–1) the drift starts.
  final double phase;

  @override
  State<_Polaroid> createState() => _PolaroidState();
}

class _PolaroidState extends State<_Polaroid>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.phase,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      if (_controller.value == 0) _controller.value = widget.phase;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // One sine cycle per loop: smooth ease-in-out, no seam at the wrap.
        final cycle = _controller.value * 2 * math.pi;
        final dy = -AppMotion.polaroidDriftFloat * (1 - math.cos(cycle)) / 2;
        final degrees =
            widget.tiltDegrees +
            AppMotion.polaroidDriftSwayDegrees * math.sin(cycle);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, dy, 0)
            ..rotateZ(degrees * math.pi / 180),
          child: child,
        );
      },
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
