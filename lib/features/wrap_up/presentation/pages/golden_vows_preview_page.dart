import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../film/golden_vows/golden_vows_canvas.dart';
import '../film/golden_vows/golden_vows_timeline.dart';

/// Debug builds only (#346): plays the Golden Vows film full screen, with
/// the reference wedding's timing. Phase 1 shows its ambient layer only.
/// Reached from the Plan inspector; never routed in release.
class GoldenVowsPreviewPage extends StatefulWidget {
  const GoldenVowsPreviewPage({super.key});

  @override
  State<GoldenVowsPreviewPage> createState() => _GoldenVowsPreviewPageState();
}

class _GoldenVowsPreviewPageState extends State<GoldenVowsPreviewPage> {
  final _timeline = GoldenVowsTimeline.reference();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: GoldenVowsCanvas(timeline: _timeline)),
          SafeArea(
            child: IconButton(
              key: const Key('golden-vows-close'),
              icon: const Icon(Icons.close, color: AppColors.textOnPhoto),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}
