import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';

/// Image with a vertical scrim gradient for legible overlaid text, plus an
/// optional [child] stacked on top (captions, chips, actions). Used for
/// hero covers, photo tiles, and the wrap-up photo beats.
class PhotoScrim extends StatelessWidget {
  const PhotoScrim({
    required this.image,
    this.child,
    this.warm = false,
    this.borderRadius,
    super.key,
  });

  final Widget image;
  final Widget? child;

  /// Adds the warm lift used on the Home hero cover.
  final bool warm;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      fit: StackFit.expand,
      children: [
        image,
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.photoScrim(warm: warm),
          ),
        ),
        ?child,
      ],
    );

    if (borderRadius == null) return content;
    return ClipRRect(borderRadius: borderRadius!, child: content);
  }
}
