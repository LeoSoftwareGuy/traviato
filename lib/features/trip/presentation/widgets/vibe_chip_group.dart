import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../wrap_up/domain/wrap_up_limits.dart';
import 'vibe_label.dart';

/// The fixed 10-vibe list (functionality.md §5). At most
/// [WrapUpLimits.maxVibes] can be picked (#432) — an app-side rule, not a
/// database check, so older memories with more keep them.
const kTripVibes = [
  'Romantic',
  'Adventure',
  'Cultural',
  'Chill',
  'Foodie',
  'Road trip',
  'Wellness',
  'Wildlife',
  'Nightlife',
  'Photography',
];

/// Multi-select vibe chips for the "The vibe" section of the "Add trip"
/// Figma frame. A tap past [maxSelected] doesn't select; the header shows
/// "Pick up to 3" for a moment instead (#432).
class VibeChipGroup extends StatefulWidget {
  const VibeChipGroup({
    required this.selected,
    required this.onToggle,
    this.maxSelected = WrapUpLimits.maxVibes,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final int maxSelected;

  /// How long the "Pick up to 3" hint stays.
  static const limitHintFor = Duration(seconds: 2);

  @override
  State<VibeChipGroup> createState() => _VibeChipGroupState();
}

class _VibeChipGroupState extends State<VibeChipGroup> {
  Timer? _hintTimer;
  bool _showsLimitHint = false;

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _onTap(String vibe) {
    final isAdding = !widget.selected.contains(vibe);
    if (isAdding && widget.selected.length >= widget.maxSelected) {
      _hintTimer?.cancel();
      setState(() => _showsLimitHint = true);
      _hintTimer = Timer(VibeChipGroup.limitHintFor, () {
        if (mounted) setState(() => _showsLimitHint = false);
      });
      return;
    }
    _hintTimer?.cancel();
    if (_showsLimitHint) setState(() => _showsLimitHint = false);
    widget.onToggle(vibe);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.trip_vibeLabel, style: AppTypography.fieldLabel),
            Text(
              _showsLimitHint
                  ? l10n.trip_vibesLimit(widget.maxSelected)
                  : l10n.trip_vibesChosen(widget.selected.length),
              key: const Key('vibe-count'),
              style: AppTypography.chipLabel.copyWith(
                color: _showsLimitHint
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final vibe in kTripVibes)
              _VibeChip(
                label: vibeLabel(l10n, vibe),
                selected: widget.selected.contains(vibe),
                onTap: () => _onTap(vibe),
              ),
          ],
        ),
      ],
    );
  }
}

class _VibeChip extends StatelessWidget {
  const _VibeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
          ),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Text(
          label,
          style: AppTypography.chipLabel.copyWith(
            color: selected ? AppColors.background : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
