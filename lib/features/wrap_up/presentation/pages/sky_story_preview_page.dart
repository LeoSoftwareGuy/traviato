import 'package:flutter/material.dart';

import '../film/sky_story/sky_story_canvas.dart';
import '../film/sky_story/sky_story_timeline.dart';

/// Debug builds only (#345): plays the Sky Story film full screen on a
/// 3-chapter, Lisbon-shaped timeline (the reference film's shape), so its
/// look can be checked on a device while the template is being built.
/// Reached from the Plan inspector; never routed in release.
class SkyStoryPreviewPage extends StatelessWidget {
  const SkyStoryPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: SkyStoryCanvas(timeline: SkyStoryTimeline.forChapters(3)),
          ),
          const SafeArea(child: BackButton(color: Colors.white)),
        ],
      ),
    );
  }
}
