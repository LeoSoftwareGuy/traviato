import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../photo/domain/entities/photo_entity.dart';
import '../../domain/note_text.dart';
import '../providers/dictation_providers.dart';
import '../widgets/note_page/note_dictation_controller.dart';
import '../widgets/note_page/note_draft_controller.dart';
import '../widgets/note_page/note_page_chrome.dart';
import '../widgets/note_page/note_title_page.dart';
import '../widgets/note_page/note_writing_page.dart';
import '../widgets/note_page/page_turn_timeline.dart';

/// Pushes the full-screen note page. The book turn is animated inside the
/// page, not by the route transition (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md
/// §1). Pops with the trimmed draft on Done — an empty string when nothing
/// was added — and `null` on Cancel.
class NotePageRoute extends PageRouteBuilder<String> {
  NotePageRoute({
    required String stamp,
    required String title,
    required String existingText,
    required int photoCount,
    PhotoEntity? photo,
  }) : super(
         opaque: false,
         transitionDuration: Duration.zero,
         reverseTransitionDuration: Duration.zero,
         pageBuilder: (context, animation, secondaryAnimation) => NotePage(
           stamp: stamp,
           title: title,
           existingText: existingText,
           photoCount: photoCount,
           photo: photo,
         ),
       );
}

/// Reference frame the spec's geometry is measured on.
const _refWidth = 402.0;
const _refHeight = 874.0;

enum _Phase { opening, open, closing }

class NotePage extends ConsumerStatefulWidget {
  const NotePage({
    required this.stamp,
    required this.title,
    required this.existingText,
    required this.photoCount,
    this.photo,
    super.key,
  });

  /// "Day 2 · 13 Aug" — uppercased by the pages.
  final String stamp;
  final String title;
  final String existingText;
  final int photoCount;

  /// The day's first photo, shown in the title page's polaroid.
  final PhotoEntity? photo;

  @override
  ConsumerState<NotePage> createState() => _NotePageState();
}

class _NotePageState extends ConsumerState<NotePage>
    with TickerProviderStateMixin {
  late final _backdrop = AnimationController(
    vsync: this,
    duration: AppMotion.noteBackdropFadeDuration,
  )..forward();
  late final _backdropOpacity = CurvedAnimation(
    parent: _backdrop,
    curve: Curves.easeOut,
  );
  late final _turn = AnimationController(vsync: this);
  final _text = NoteDraftController();
  final _focus = FocusNode();
  late final _dictation = NoteDictationController(
    service: ref.read(dictationServiceProvider),
    draft: _text,
  );

  var _phase = _Phase.opening;
  var _reducedMotion = false;
  var _started = false;
  var _draftWords = 0;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      _turn.duration = AppMotion.pageTurnReducedMotionFade;
      _turn.forward().whenComplete(_onOpened);
    } else {
      _turn.duration = AppMotion.pageTurnOpenDuration;
      // Lets the closed page paint its first frame before it starts to lift.
      _startTimer = Timer(AppMotion.pageTurnStartDelay, () {
        if (mounted) _turn.forward().whenComplete(_onOpened);
      });
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _backdropOpacity.dispose();
    _backdrop.dispose();
    _turn.dispose();
    _dictation.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final words = countNoteWords(_text.text);
    if (words != _draftWords) setState(() => _draftWords = words);
  }

  void _onOpened() {
    if (!mounted || _phase != _Phase.opening) return;
    setState(() => _phase = _Phase.open);
  }

  Future<void> _close(String? result) async {
    if (_phase != _Phase.open) return;
    _focus.unfocus();
    setState(() => _phase = _Phase.closing);
    _turn.duration = _reducedMotion
        ? AppMotion.pageTurnReducedMotionFade
        : AppMotion.pageTurnCloseDuration;
    await _turn.forward(from: 0).orCancel.catchError((_) {});
    if (mounted) Navigator.of(context).pop(result);
  }

  /// Closing the book stops the recording first (§3), so whatever was
  /// heard is in the draft before it's read.
  Future<void> _done() async {
    if (_phase != _Phase.open) return;
    await _dictation.stop();
    await _close(_text.text.trim());
  }

  Future<void> _cancel() async {
    if (_phase != _Phase.open) return;
    await _dictation.stop();
    if (!mounted) return;
    if (_text.text.trim().isNotEmpty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard what you added?'),
          actions: [
            TextButton(
              key: const Key('note-page-keep-writing'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep writing'),
            ),
            TextButton(
              key: const Key('note-page-discard'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    // Don't hold the book open on the platform recogniser.
    unawaited(_dictation.cancel());
    await _close(null);
  }

  /// **Aa**: stop listening if needed, then type at the end of the draft.
  void _focusAtEnd() {
    unawaited(_dictation.stop());
    _focus.requestFocus();
    _text.selection = TextSelection.collapsed(offset: _text.text.length);
  }

  /// Mic: from typing, dismiss the keyboard first; otherwise toggle.
  void _onMicTap() {
    if (!_dictation.isListening) _focus.unfocus();
    unawaited(_dictation.toggle());
  }

  void _onFieldTap() {
    if (_dictation.isListening) unawaited(_dictation.stop());
  }

  PageTurnFrame get _frame {
    final t = _turn.value;
    return switch (_phase) {
      _Phase.opening => PageTurnTimeline.open(t),
      _Phase.open => PageTurnTimeline.open(1),
      _Phase.closing => PageTurnTimeline.close(t),
    };
  }

  /// Reduced motion: the writing page crossfades in and the whole page
  /// fades out — no rotation.
  double get _reducedOpacity => switch (_phase) {
    _Phase.opening => _turn.value,
    _Phase.open => 1,
    _Phase.closing => 1 - _turn.value,
  };

  String get _meta {
    final words = countNoteWords(widget.existingText);
    final photos = widget.photoCount;
    return '$words ${words == 1 ? 'word' : 'words'} · '
        '$photos ${photos == 1 ? 'photo' : 'photos'}';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;

    final writingPage = IgnorePointer(
      ignoring: _phase != _Phase.open,
      child: NoteWritingPage(
        stamp: widget.stamp,
        title: widget.title,
        existingText: widget.existingText,
        controller: _text,
        focusNode: _focus,
        draftWordCount: _draftWords,
        // Clear the home indicator when the keyboard is down; ride right
        // on top of the keyboard when it's up.
        dockBottomPadding: keyboard > 0
            ? 18
            : math.max(18, media.viewPadding.bottom),
        onCancel: _cancel,
        onDone: _done,
        onAaTap: _focusAtEnd,
        dictation: _dictation,
        onMicTap: _onMicTap,
        onFieldTap: _onFieldTap,
      ),
    );

    // Built once per page build, not per animation frame.
    final titlePage = RepaintBoundary(
      child: NoteTitlePage(
        stamp: widget.stamp,
        title: widget.title,
        meta: _meta,
        photo: widget.photo,
      ),
    );

    return PopScope(
      canPop: false,
      // Android back / swipe-back behave as Cancel.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sx = constraints.maxWidth / _refWidth;
            final sy = constraints.maxHeight / _refHeight;
            final top = math.max(54 * sy, media.viewPadding.top);
            final bottom = 14 * sy + keyboard;
            final right = 12 * sx;

            Widget page(Widget child) => Positioned(
              top: top,
              bottom: bottom,
              left: 0,
              right: right,
              child: child,
            );

            return AnimatedBuilder(
              animation: _turn,
              builder: (context, _) {
                final frame = _reducedMotion ? null : _frame;
                final stack = Stack(
                  children: [
                    Positioned.fill(
                      child: FadeTransition(
                        opacity: _backdropOpacity,
                        child: const ColoredBox(
                          color: AppColors.filmBackground,
                        ),
                      ),
                    ),
                    _PageEdge(
                      top: top + 6 * sy,
                      bottom: bottom + 6 * sy,
                      right: 4 * sx,
                      color: AppColors.paperEdgeBack,
                    ),
                    _PageEdge(
                      top: top + 3 * sy,
                      bottom: bottom + 3 * sy,
                      right: 8 * sx,
                      color: AppColors.paperEdge,
                    ),
                    page(
                      Stack(
                        fit: StackFit.expand,
                        children: [
                          writingPage,
                          if (frame != null)
                            NotePageShade.writing(opacity: frame.writingShade),
                        ],
                      ),
                    ),
                    if (frame != null && _phase != _Phase.open)
                      page(_TurningPage(frame: frame, titlePage: titlePage)),
                  ],
                );
                final opacity = frame?.opacity ?? _reducedOpacity;
                return opacity >= 1
                    ? stack
                    : Opacity(opacity: opacity, child: stack);
              },
            );
          },
        ),
      ),
    );
  }
}

class _PageEdge extends StatelessWidget {
  const _PageEdge({
    required this.top,
    required this.bottom,
    required this.right,
    required this.color,
  });

  final double top;
  final double bottom;
  final double right;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: 0,
      right: right,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: notePageRadius),
      ),
    );
  }
}

/// The two-sided card hinged on the spine: the title page until 90°, then
/// the plain back, flipped so it isn't mirrored.
class _TurningPage extends StatelessWidget {
  const _TurningPage({required this.frame, required this.titlePage});

  final PageTurnFrame frame;
  final Widget titlePage;

  @override
  Widget build(BuildContext context) {
    final front = frame.showsFront;
    return Transform(
      key: const Key('note-page-turning'),
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 1 / 1600)
        ..rotateY(frame.angle),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: front
              ? notePageRadius
              : const BorderRadius.horizontal(left: Radius.circular(16)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.paperDropShadow,
              offset: Offset(6, 0),
              blurRadius: 18,
            ),
          ],
        ),
        child: front
            ? Stack(
                fit: StackFit.expand,
                children: [
                  titlePage,
                  NotePageShade.front(opacity: frame.frontShade),
                ],
              )
            : Transform.flip(flipX: true, child: const NotePageBack()),
      ),
    );
  }
}
