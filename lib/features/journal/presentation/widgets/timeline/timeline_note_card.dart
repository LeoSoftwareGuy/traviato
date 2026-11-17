import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/l10n/l10n_dates.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../photo/domain/entities/photo_entity.dart';
import '../../../../photo/presentation/widgets/storage_photo_image.dart';
import '../../../domain/entities/journal_note_entity.dart';
import '../../../domain/note_text.dart';

/// A note's collapsed body: 4 lines of 14.5 × 1.6 (spec §4 "Long note").
const noteCollapsedLines = 4;
const _collapsedHeight = 93.0;
const _longPressDuration = Duration(milliseconds: 450);
const _radius = BorderRadius.only(
  topLeft: Radius.circular(4),
  topRight: Radius.circular(16),
  bottomLeft: Radius.circular(16),
  bottomRight: Radius.circular(16),
);

/// A note on the day timeline (#401, docs/design/journal-notes/ §4). Its
/// time and mic live on the rail, not in the card. Chips on top (EARLIER
/// NOTE, JUST NOW, WRITTEN (date)), the italic body collapsed to 4 lines
/// with "more" / "less", the "On photo" chip, and a legacy note's
/// "LAST EDITED" footer. Long-press (450ms) asks for Edit / Delete.
class TimelineNoteCard extends StatefulWidget {
  const TimelineNoteCard({
    required this.note,
    required this.use24h,
    required this.onLongPress,
    this.photo,
    this.onPhotoTap,
    this.isFresh = false,
    this.isLater = false,
    super.key,
  });

  final JournalNoteEntity note;
  final bool use24h;
  final VoidCallback onLongPress;

  /// The photo the note was written on, when it's still there.
  final PhotoEntity? photo;
  final VoidCallback? onPhotoTap;

  /// Just saved: primary border and the JUST NOW chip.
  final bool isFresh;

  /// Written after its day was over: a WRITTEN (date) chip.
  final bool isLater;

  @override
  State<TimelineNoteCard> createState() => _TimelineNoteCardState();
}

class _TimelineNoteCardState extends State<TimelineNoteCard> {
  var _expanded = false;

  /// Set when a long press fires, so the release can't also tap "more" or
  /// the photo chip (spec §5).
  var _swallowTap = false;

  void _onLongPress() {
    HapticFeedback.lightImpact();
    _swallowTap = true;
    widget.onLongPress();
  }

  void _tap(VoidCallback? action) {
    if (_swallowTap) {
      _swallowTap = false;
      return;
    }
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final note = widget.note;
    final locale = l10n.localeName;
    final clock = L10nDates.clock(locale, use24h: widget.use24h);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final chips = <Widget>[
      if (note.legacy) _Chip.earlier(l10n.timeline_earlierNote),
      if (widget.isFresh) _Chip.fresh(l10n.timeline_justNow),
      if (widget.isLater && !note.legacy)
        _Chip.plain(
          l10n.timeline_writtenOn(
            L10nDates.weekdayDayMonth(locale).format(note.takenAt.toLocal()),
          ),
        ),
    ];

    return RawGestureDetector(
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: _longPressDuration),
              (r) => r.onLongPress = _onLongPress,
            ),
      },
      child: AnimatedContainer(
        key: Key('timeline-note-${note.id}'),
        duration: reducedMotion
            ? AppMotion.pageTurnReducedMotionFade
            : const Duration(milliseconds: 600),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: _radius,
          border: Border.all(
            color: widget.isFresh
                ? AppColors.tint(AppColors.primary, .75)
                : AppColors.hairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chips.isNotEmpty) ...[
              Wrap(spacing: 6, runSpacing: 6, children: chips),
              const SizedBox(height: 8),
            ],
            _Body(
              text: note.content,
              expanded: _expanded,
              onToggle: () =>
                  _tap(() => setState(() => _expanded = !_expanded)),
            ),
            if (widget.photo != null) ...[
              const SizedBox(height: 10),
              _OnPhotoChip(
                photo: widget.photo!,
                time: clock.format(
                  (widget.photo!.takenAt ?? widget.photo!.createdAt).toLocal(),
                ),
                onTap: () => _tap(widget.onPhotoTap),
              ),
            ],
            if (note.legacy) ...[
              const SizedBox(height: 10),
              Text(
                l10n
                    .timeline_lastEdited(
                      (widget.isLater
                              ? '${L10nDates.dayMonth(locale).format(note.editedAt.toLocal())} '
                              : '') +
                          clock.format(note.editedAt.toLocal()),
                      l10n.journal_wordCount(countNoteWords(note.content)),
                    )
                    .toUpperCase(),
                style: AppTypography.mono,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The italic body: in full when it fits 4 lines; otherwise clipped to 4
/// with a bottom fade and "more", or in full with "less" (spec §4, §7).
class _Body extends StatelessWidget {
  const _Body({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.timelineNote;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: noteCollapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        final body = Text(text, style: style);
        if (!overflows) return body;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 380),
              curve: AppMotion.progressCurve,
              alignment: Alignment.topLeft,
              child: expanded
                  ? body
                  : ShaderMask(
                      key: const Key('timeline-note-collapsed'),
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.transparent],
                        stops: [.6, 1],
                      ).createShader(rect),
                      child: SizedBox(
                        height:
                            _collapsedHeight *
                            MediaQuery.textScalerOf(context).scale(1),
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topLeft,
                            maxHeight: double.infinity,
                            child: body,
                          ),
                        ),
                      ),
                    ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Text(
                  expanded
                      ? context.l10n.timeline_less
                      : context.l10n.timeline_more,
                  key: const Key('timeline-note-more'),
                  style: AppTypography.timelineLink,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OnPhotoChip extends StatelessWidget {
  const _OnPhotoChip({
    required this.photo,
    required this.time,
    required this.onTap,
  });

  final PhotoEntity photo;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final caption = photo.caption?.trim();
    final label = [
      context.l10n.timeline_onPhoto(time),
      if (caption != null && caption.isNotEmpty) caption,
    ].join(' · ');
    return GestureDetector(
      key: const Key('timeline-note-on-photo'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
        decoration: BoxDecoration(
          color: AppColors.hairlineSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 34,
                height: 34,
                child: photo.imageUrl == null
                    ? const ColoredBox(color: AppColors.surface)
                    : StoragePhotoImage(
                        url: photo.imageUrl!,
                        storagePath: photo.storagePath,
                        decodeSize: const Size(34, 34),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.timelineMeta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip.earlier(this.label)
    : foreground = AppColors.accentPurpleLight,
      background = AppColors.accentPurpleChip;
  const _Chip.fresh(this.label)
    : foreground = AppColors.primary,
      background = AppColors.primaryTint;
  const _Chip.plain(this.label)
    : foreground = AppColors.textSecondary,
      background = AppColors.hairlineSoft;

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.mono.copyWith(color: foreground),
      ),
    );
  }
}
