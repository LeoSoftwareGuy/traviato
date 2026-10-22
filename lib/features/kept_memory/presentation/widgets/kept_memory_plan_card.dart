import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kept_memory_plan_item.dart';

const _expandDuration = Duration(milliseconds: 200);

/// The memory's plan, folded up at the end of the page (#279, spec § 3.4).
/// Collapsed by default and read-only — rows don't respond to taps. The
/// page leaves it out when there was no plan.
class KeptMemoryPlanCard extends StatefulWidget {
  const KeptMemoryPlanCard({required this.plan, super.key});

  final List<KeptMemoryPlanItem> plan;

  @override
  State<KeptMemoryPlanCard> createState() => _KeptMemoryPlanCardState();
}

class _KeptMemoryPlanCardState extends State<KeptMemoryPlanCard> {
  var _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final done = widget.plan.where((item) => item.isDone).length;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            key: const Key('kept-memory-plan-toggle'),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Row(
                children: [
                  Text(
                    l10n.keptMemory_plan,
                    style: AppTypography.serif(
                      fontSize: 17,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n
                          .keptMemory_planDone(done, widget.plan.length)
                          .toUpperCase(),
                      style: AppTypography.mono,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? .5 : 0,
                    duration: _expandDuration,
                    child: const Icon(
                      Icons.expand_more,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: _expandDuration,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 16, 14),
                    child: Column(
                      children: [
                        for (final item in widget.plan) _PlanRow(item: item),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.item});

  final KeptMemoryPlanItem item;

  @override
  Widget build(BuildContext context) {
    final isDone = item.isDone;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? AppColors.tint(AppColors.primary, .16) : null,
              border: Border.all(
                color: isDone
                    ? AppColors.tint(AppColors.primary, .5)
                    : AppColors.tint(AppColors.textSecondary, .3),
              ),
            ),
            child: isDone
                ? const Icon(Icons.check, size: 12, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 12),
          // User content — shown exactly as written.
          Expanded(
            child: Text(
              item.quest.title,
              style: AppTypography.chipLabel.copyWith(
                height: 1.35,
                color: isDone ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            context.l10n.keptMemory_planDay(item.dayIndex),
            style: AppTypography.mono.copyWith(letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}
