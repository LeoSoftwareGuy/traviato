import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_gradients.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/dashed_rrect_border.dart';
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
    required this.languageCode,
    required this.isLanguageAvailable,
    required this.onLanguageTap,
    super.key,
  });

  final NoteDictationController dictation;
  final int draftWordCount;
  final double bottomPadding;
  final VoidCallback onAaTap;
  final VoidCallback onMicTap;

  /// The dictation language, e.g. `ru` (#218, design 2a).
  final String languageCode;

  /// False when this device can't recognise [languageCode] (design 2d):
  /// the mic is disabled (not hidden) and typing becomes the main action.
  final bool isLanguageAvailable;

  /// Opens the "Speak in…" sheet (design 2b).
  final VoidCallback onLanguageTap;

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
          final unavailable = !isLanguageAvailable && !listening;
          final notice = unavailable
              ? null
              : _noticeText(context.l10n, dictation.notice);
          final code = languageCode.toUpperCase();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (listening) ...[
                _ListeningRow(dictation: dictation, code: code),
                const SizedBox(height: 10),
              ],
              if (unavailable) ...[
                _UnavailableWarning(
                  languageCode: languageCode,
                  onChooseAnother: onLanguageTap,
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  _AaButton(onTap: onAaTap, accented: unavailable),
                  Expanded(
                    child: unavailable
                        ? const _UnavailableMic()
                        : _MicButton(listening: listening, onTap: onMicTap),
                  ),
                  _LanguageSlot(
                    code: code,
                    wordCount: draftWordCount,
                    isLocked: listening,
                    hasWarning: unavailable,
                    onTap: onLanguageTap,
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

  static String? _noticeText(AppLocalizations l10n, DictationNotice notice) =>
      switch (notice) {
        DictationNotice.none => null,
        DictationNotice.micOff => l10n.note_micOff,
        DictationNotice.unavailable => l10n.note_voiceUnavailable,
      };
}

class _AaButton extends StatelessWidget {
  const _AaButton({required this.onTap, this.accented = false});

  final VoidCallback onTap;

  /// Typing is the main action (dictation unavailable, design 2d).
  final bool accented;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.note_typeSemantics,
      excludeSemantics: true,
      child: Material(
        color: accented
            ? AppColors.tint(AppColors.primary, .14)
            : Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(
            color: accented
                ? AppColors.primary
                : AppColors.tint(AppColors.paperInk, .2),
            width: accented ? 1.5 : 1,
          ),
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
      label: listening
          ? context.l10n.note_stopDictationSemantics
          : context.l10n.note_dictateSemantics,
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
              listening
                  ? context.l10n.dictation_tapToStop
                  : context.l10n.dictation_tapToTalk,
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
  const _ListeningRow({required this.dictation, required this.code});

  final NoteDictationController dictation;

  /// Dictation language shown in the status line (design 2c).
  final String code;

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
          context.l10n
              .note_listeningIn(code, '${elapsed.inMinutes}:$seconds')
              .toUpperCase(),
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

/// Right slot of the dock (design 2a): the dictation-language chip with
/// the word count under it. Locked while listening (2c): dimmed, no caret,
/// not tappable — stop first to switch. An orange dot flags an
/// unavailable language (2d).
class _LanguageSlot extends StatelessWidget {
  const _LanguageSlot({
    required this.code,
    required this.wordCount,
    required this.isLocked,
    required this.hasWarning,
    required this.onTap,
  });

  final String code;
  final int wordCount;
  final bool isLocked;
  final bool hasWarning;
  final VoidCallback onTap;

  static const width = 56.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chip = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: const Key('note-page-language-chip'),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.tint(AppColors.paperInk, .2)),
            borderRadius: AppRadius.pillRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: AppColors.paperInk,
                ),
              ),
              if (!isLocked) ...[
                const SizedBox(width: 3),
                Text(
                  '▾',
                  style: AppTypography.caption.copyWith(
                    fontSize: 8,
                    color: AppColors.paperInkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasWarning)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              key: const Key('note-page-language-warning-dot'),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.paperDock, width: 1.5),
              ),
            ),
          ),
      ],
    );
    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        enabled: !isLocked,
        label: l10n.dictation_languageSemantics(code),
        excludeSemantics: true,
        child: GestureDetector(
          key: const Key('note-page-language-slot'),
          behavior: HitTestBehavior.opaque,
          onTap: isLocked ? null : onTap,
          // ≥48pt tall hit area, like Aa.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(opacity: isLocked ? .45 : 1, child: chip),
                const SizedBox(height: 4),
                Text(
                  l10n.note_wordCountShort(wordCount),
                  key: const Key('note-page-word-counter'),
                  style: AppTypography.noteDockCounter,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The mic when the dictation language can't be recognised here (design
/// 2d): dashed outline + slashed mic, disabled rather than hidden.
class _UnavailableMic extends StatelessWidget {
  const _UnavailableMic();

  static const _size = 68.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: false,
      label: context.l10n.dictation_notAvailable,
      excludeSemantics: true,
      child: Column(
        key: const Key('note-page-mic-unavailable'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _size,
            height: _size,
            child: DashedRRectBorder(
              color: AppColors.tint(AppColors.paperInkMuted, .6),
              borderRadius: const BorderRadius.all(Radius.circular(_size / 2)),
              strokeWidth: 1.5,
              child: const Center(
                child: Icon(
                  Icons.mic_off_rounded,
                  color: AppColors.paperInkMuted,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.dictation_notAvailable,
            style: AppTypography.noteDockLabel.copyWith(
              color: AppColors.paperInkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline warning above the dock (design 2d), with a link that opens the
/// "Speak in…" sheet.
class _UnavailableWarning extends StatelessWidget {
  const _UnavailableWarning({
    required this.languageCode,
    required this.onChooseAnother,
  });

  final String languageCode;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      key: const Key('note-page-language-warning'),
      onTap: onChooseAnother,
      child: Text.rich(
        TextSpan(
          style: AppTypography.noteNotice,
          children: [
            TextSpan(
              text: l10n.dictation_unavailableWarning(
                languageCode,
                dictationPlatformName(),
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: l10n.dictation_chooseAnother,
              style: AppTypography.noteNotice.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// `ios` / `android` / `other` — picks "iPhone" vs "phone" wording.
String dictationPlatformName() => switch (defaultTargetPlatform) {
  TargetPlatform.iOS => 'ios',
  TargetPlatform.android => 'android',
  _ => 'other',
};
