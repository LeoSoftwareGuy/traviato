import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../wrap_up_film_tokens.dart';

/// The small polaroid-style print used by both flurries — a plain white
/// border around a photo, sized per-card by the caller.
class WrapUpFilmSmallPrint extends StatelessWidget {
  const WrapUpFilmSmallPrint({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.shadowBlur,
    required this.shadowOffsetY,
    this.shadowOpacity = 0.55,
    super.key,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final double shadowBlur;
  final double shadowOffsetY;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    final bottomPad = (width * 0.15).roundToDouble();
    return Container(
      width: width,
      padding: EdgeInsets.fromLTRB(9, 9, 9, bottomPad),
      decoration: BoxDecoration(
        color: WrapUpFilmColors.ink,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            offset: Offset(0, shadowOffsetY),
            blurRadius: shadowBlur,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: width - 18,
          height: height,
          child: imageUrl == null
              ? const ColoredBox(color: Color(0xFFD9D3C4))
              : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const ColoredBox(color: Color(0xFFD9D3C4)),
                  errorWidget: (context, url, error) =>
                      const ColoredBox(color: Color(0xFFD9D3C4)),
                ),
        ),
      ),
    );
  }
}
