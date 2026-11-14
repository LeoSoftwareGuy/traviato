import 'package:flutter/material.dart';

import '../film/neon_night/neon_night_canvas.dart';
import '../film/neon_night/neon_night_timeline.dart';

/// Debug builds only (#363): plays the Neon Night film full screen on the
/// spec's 3-chapter reference timeline. Built up phase by phase: phase 2
/// is the ambient layers and the neon balloon sign. "Reduced" switches to
/// the reduced-flashing version (§6). Reached from the Plan inspector;
/// never routed in release.
class NeonNightPreviewPage extends StatefulWidget {
  const NeonNightPreviewPage({super.key});

  @override
  State<NeonNightPreviewPage> createState() => _NeonNightPreviewPageState();
}

class _NeonNightPreviewPageState extends State<NeonNightPreviewPage> {
  static final _timeline = NeonNightTimeline.reference();
  bool _reduced = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: NeonNightCanvas(
              timeline: _timeline,
              reducedFlashing: _reduced,
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                const BackButton(color: Colors.white),
                const Spacer(),
                TextButton(
                  key: const Key('neon-night-reduced'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => setState(() => _reduced = !_reduced),
                  child: Text(_reduced ? 'Reduced' : 'Full'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
