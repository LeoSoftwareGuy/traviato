import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/wrap_up_keepsake.dart';
import '../wrap_up_film_motion.dart';
import '../wrap_up_film_scenes.dart';
import '../wrap_up_film_tokens.dart';

/// The closing card: trip title, AI closing line, app mark
/// (docs/design/wrap-film-spec.md § Keepsake). The reference prototype's
/// wordmark reads "Traviato" (its codename); the app-facing product name is
/// **Trevy** (CLAUDE.md's product-language rule), used here instead.
class WrapUpFilmKeepsake extends StatelessWidget {
  const WrapUpFilmKeepsake({
    required this.t,
    required this.keepsake,
    super.key,
  });

  final double t;
  final WrapUpKeepsake keepsake;

  @override
  Widget build(BuildContext context) {
    const a = WrapUpFilmScenes.keepsakeStart;
    final titleRise1 = rise(t, a + 0.6, 1.9, lift: 46);
    final titleRise2 = rise(t, a + 1.4, 1.9, lift: 46);
    final quoteRise = rise(t, a + 2.6, 2.0, lift: 34);
    final markRise = rise(t, a + 3.9, 1.7, lift: 26);
    final out = fade(t, a + 5.2, 1.3, 1, 0).clamp(0.0, 1.0);

    return Positioned(
      left: 110,
      right: 110,
      bottom: 268,
      child: Opacity(
        opacity: out,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, titleRise1.translateY),
              child: Opacity(
                opacity: titleRise1.opacity.clamp(0.0, 1.0),
                child: Text(
                  keepsake.titleLine1,
                  style: WrapUpFilmText.serif(
                    size: 138,
                    height: 0.98,
                    letterSpacing: -4,
                    color: WrapUpFilmColors.ink,
                  ),
                ),
              ),
            ),
            if (keepsake.titleLine2.isNotEmpty)
              Transform.translate(
                offset: Offset(0, titleRise2.translateY),
                child: Opacity(
                  opacity: titleRise2.opacity.clamp(0.0, 1.0),
                  child: Text(
                    keepsake.titleLine2,
                    style: WrapUpFilmText.serif(
                      size: 138,
                      height: 1.0,
                      letterSpacing: -4,
                      italic: true,
                      color: WrapUpFilmColors.amber,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 44),
            Transform.translate(
              offset: Offset(0, quoteRise.translateY),
              child: Opacity(
                opacity: quoteRise.opacity.clamp(0.0, 1.0),
                child: Text(
                  '"${keepsake.closingQuote}"',
                  style: WrapUpFilmText.serif(
                    size: 44,
                    height: 1.6,
                    italic: true,
                    color: WrapUpFilmColors.ink.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 64),
            Transform.translate(
              offset: Offset(0, markRise.translateY),
              child: Opacity(
                opacity: markRise.opacity.clamp(0.0, 1.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: WrapUpFilmColors.accent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        '✦',
                        style: WrapUpFilmText.serif(
                          size: 26,
                          height: 1.0,
                          weight: FontWeight.w400,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      'Trevy',
                      style: WrapUpFilmText.serif(
                        size: 40,
                        height: 1.0,
                        weight: FontWeight.w400,
                        color: WrapUpFilmColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
