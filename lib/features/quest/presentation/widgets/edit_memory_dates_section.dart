import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trip/domain/entities/trip_dates_change_entity.dart';
import '../../../trip/presentation/pages/validate_memory_dates.dart';
import '../../../trip/presentation/widgets/memory_date_range_field.dart';
import '../controllers/plan_controller.dart';
import '../mutations/manage_memory_mutations.dart';

/// The Manage sheet's Starts / Ends cards (#271): tapping either opens the
/// same date picker as Create memory. Once the picked range differs from
/// the saved one a Save button appears. Save asks the server what the new
/// range would delete; if nothing, it saves straight away, otherwise the
/// button arms into a coral "Delete and save" with the exact counts, and
/// only a second tap saves. Changing the dates again disarms it.
class EditMemoryDatesSection extends ConsumerStatefulWidget {
  const EditMemoryDatesSection({required this.tripId, super.key});

  final String tripId;

  @override
  ConsumerState<EditMemoryDatesSection> createState() =>
      _EditMemoryDatesSectionState();
}

class _EditMemoryDatesSectionState
    extends ConsumerState<EditMemoryDatesSection> {
  // Null = the saved date, until the user picks another.
  DateTime? _pickedStart;
  DateTime? _pickedEnd;

  /// Set once a preview found content outside the new range — the armed
  /// state. Cleared whenever the dates change again.
  TripDatesChangeEntity? _pendingImpact;

  void _pick({DateTime? start, DateTime? end}) {
    setState(() {
      if (start != null) _pickedStart = start;
      if (end != null) _pickedEnd = end;
      _pendingImpact = null;
    });
  }

  Future<void> _save(DateTime start, DateTime end) async {
    try {
      if (_pendingImpact == null) {
        final impact = await runPreviewMemoryDates(
          ref: ref,
          tripId: widget.tripId,
          startDate: start,
          endDate: end,
        );
        if (impact.removesAnything) {
          if (mounted) setState(() => _pendingImpact = impact);
          return;
        }
      }
      await runEditMemoryDates(
        ref: ref,
        tripId: widget.tripId,
        startDate: start,
        endDate: end,
      );
    } catch (_) {
      // Surfaced via the Manage sheet's mutation error listener.
      return;
    }
    if (!mounted) return;
    setState(() {
      _pickedStart = null;
      _pickedEnd = null;
      _pendingImpact = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trip = ref.watch(planControllerProvider(widget.tripId)).value?.trip;
    final start = _pickedStart ?? trip?.startDate;
    final end = _pickedEnd ?? trip?.endDate;
    final error = validateMemoryDates(l10n, start, end);
    final isDirty =
        !_sameDay(start, trip?.startDate) || !_sameDay(end, trip?.endDate);
    final isBusy =
        ref.watch(previewMemoryDatesMutation) is MutationPending ||
        ref.watch(editMemoryDatesMutation) is MutationPending;
    final impact = _pendingImpact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MemoryDateRangeField(
          startDate: start,
          endDate: end,
          onStartDateChanged: (date) => _pick(start: date),
          onEndDateChanged: (date) => _pick(end: date),
          errorText: error,
          showHint: false,
        ),
        if (isDirty && error == null) ...[
          const SizedBox(height: AppSpacing.sm),
          _SaveDatesButton(
            isArmed: impact != null,
            isBusy: isBusy,
            onPressed: () => _save(start!, end!),
          ),
          if (impact != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.manage_datesConsequence(
                _formatRange(l10n, start!, end!),
                _formatItems(l10n, impact),
              ),
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(letterSpacing: 0),
            ),
          ],
        ],
      ],
    );
  }
}

class _SaveDatesButton extends StatelessWidget {
  const _SaveDatesButton({
    required this.isArmed,
    required this.isBusy,
    required this.onPressed,
  });

  final bool isArmed;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ElevatedButton(
      onPressed: isBusy ? null : onPressed,
      // Armed mirrors Delete memory's armed state: solid coral.
      style: isArmed
          ? ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCoral,
              foregroundColor: AppColors.background,
              minimumSize: const Size.fromHeight(48),
            )
          : ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(isArmed ? l10n.manage_deleteAndSave : l10n.manage_saveDates),
    );
  }
}

bool _sameDay(DateTime? a, DateTime? b) => a == null || b == null
    ? a == b
    : a.year == b.year && a.month == b.month && a.day == b.day;

String _formatRange(AppLocalizations l10n, DateTime start, DateTime end) {
  final format = DateFormat('d MMM y', l10n.localeName);
  return '${format.format(start)} – ${format.format(end)}';
}

/// "6 notes, 23 photos, 4 quests" — only the types that are affected.
String _formatItems(AppLocalizations l10n, TripDatesChangeEntity impact) => [
  if (impact.notes > 0) l10n.manage_noteCount(impact.notes),
  if (impact.photos > 0) l10n.common_photoCount(impact.photos),
  if (impact.quests > 0) l10n.manage_questCount(impact.quests),
  if (impact.bonusTasks > 0) l10n.manage_bonusTaskCount(impact.bonusTasks),
].join(', ');
