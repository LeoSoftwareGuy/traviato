import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_gradients.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/pluralize.dart';
import 'note_dictation_controller.dart';

/// The note page's bottom dock (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md
/// §4): **Aa** · mic · `+N words`, with the waveform + timer above the
/// buttons while listening and an inline notice below them when voice
/// can't be used.
class NoteDock extends StatelessWidget {
  const NoteDock({
    required this.dictation,
    required this.draftWordCount,
    required this.bottomPadding,
    required this.onAaTap,
    required this.onMicTap,
    super.key,
  });

  final NoteDictationController dictation;
  final int draftWordCount;
  final double bottomPadding;
  final VoidCallback onAaTap;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('note-page-dock'),
      padding: EdgeInsets.fromLTRB(30, 12, 22, bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.paperDock,
        border: Border(top: BorderSide(color: AppColors.paperRule)),
      ),
      child: ListenableBuilder(
        listenable: dictation,
        builder: (context, _) {
          final listening = dictation.isListening;
          final notice = _noticeText(dictation.notice);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (listening) ...[
                _ListeningRow(dictation: dictation),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  _AaButton(onTap: onAaTap),
                  Expanded(
                    child: _MicButton(listening: listening, onTap: onMicTap),
                  ),
                  SizedBox(
                    width: 72,
                    child: draftWordCount == 0
                        ? null
                        : Text(
                            '+$draftWordCount '
                            '${pluralize(draftWordCount, 'word', 'words')}',
                            key: const Key('note-page-word-counter'),
                            textAlign: TextAlign.right,
                            style: AppTypography.noteDockCounter,
                          ),
                  ),
                ],
              ),
              if (notice != null) ...[
                const SizedBox(height: 8),
                Text(
                  notice,
                  key: const Key('note-page-voice-notice'),
                  textAlign: TextAlign.center,
                  style: AppTypography.noteNotice,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static String? _noticeText(DictationNotice notice) => switch (notice) {
    DictationNotice.none => null,
    DictationNotice.micOff =>
      'Microphone is off. Turn it on in Settings, or just type.',
    DictationNotice.unavailable =>
      "Voice isn't available right now — typing works.",
  };
}

class _AaButton extends StatelessWidget {
  const _AaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Type',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        shape: CircleBorder(
          side: BorderSide(color: AppColors.tint(AppColors.paperInk, .2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('note-page-aa'),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(child: Text('Aa', style: AppTypography.noteDockAa)),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.listening, required this.onTap});

  final bool listening;
  final VoidCallback onTap;

  static const _size = 68.0;

  @override
  Widget build(BuildContext context) {
    final face = listening
        ? Container(
            width: _size,
            height: _size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentCoral,
            ),
            child: Container(
              key: const Key('note-page-mic-stop'),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          )
        : Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primaryCta,
              boxShadow: [
                BoxShadow(
                  color: AppColors.tint(AppColors.primary, .35),
                  offset: const Offset(0, 10),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: AppColors.background,
              size: 28,
            ),
          );

    return Semantics(
      button: true,
      label: listening ? 'Stop dictation' : 'Dictate',
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key('note-page-mic'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (listening) _PulsingRing(child: face) else face,
            const SizedBox(height: 6),
            Text(
              listening ? 'Tap to stop' : 'Tap to talk',
              style: AppTypography.noteDockLabel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Coral ring growing out of the recording mic, on a 1.4s loop. Static
/// under reduced motion.
class _PulsingRing extends StatefulWidget {
  const _PulsingRing({required this.child});

  final Widget child;

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.micPulseDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = .5;
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      child: widget.child,
      builder: (context, child) {
        final t = _pulse.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.tint(AppColors.accentCoral, .45 * (1 - t)),
                spreadRadius: AppMotion.micPulseSpread * t,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _ListeningRow extends StatelessWidget {
  const _ListeningRow({required this.dictation});

  final NoteDictationController dictation;

  @override
  Widget build(BuildContext context) {
    final elapsed = dictation.elapsed;
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      key: const Key('note-page-listening'),
      children: [
        _Waveform(
          levels: dictation.hasLiveLevels ? dictation.levels : null,
        ),
        const SizedBox(height: 6),
        Text(
          'LISTENING · ${elapsed.inMinutes}:$seconds',
          style: AppTypography.noteListening,
        ),
      ],
    );
  }
}

/// 24 bars, 3px wide with 3px gaps, 30px tall. Heights come from live
/// mic [levels]; with none, a staggered loop stands in.
class _Waveform extends StatefulWidget {
  const _Waveform({required this.levels});

  final List<double>? levels;

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final _loop = AnimationController(
    vsync: this,
    duration: AppMotion.waveformLoopDuration * 2,
  );

  static const _bars = NoteDictationController.barCount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  @override
  void didUpdateWidget(_Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLoop();
  }

  void _syncLoop() {
    final wantsLoop =
        widget.levels == null && !MediaQuery.disableAnimationsOf(context);
    if (wantsLoop && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!wantsLoop && _loop.isAnimating) {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  /// .3 ↔ 1, easeInOut, each bar offset in phase.
  double _fallback(int i) {
    final phase = (_loop.value + i / _bars) % 1;
    final wave = Curves.easeInOut.transform(1 - (2 * phase - 1).abs());
    return .3 + .7 * wave;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('note-page-waveform'),
      height: 30,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) {
          final levels = widget.levels;
          final reduced = MediaQuery.disableAnimationsOf(context);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _bars; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Container(
                  width: 3,
                  height:
                      30 *
                      math.max(
                        .3,
                        levels?[i] ?? (reduced ? .5 : _fallback(i)),
                      ),
                  decoration: BoxDecoration(
                    color: AppColors.paperWave,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
