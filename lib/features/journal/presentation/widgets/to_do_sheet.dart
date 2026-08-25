import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quest/domain/entities/quest_entity.dart';
import '../../../quest/presentation/mutations/quest_mutations.dart';
import '../../../quest/presentation/providers/quest_providers.dart';
import '../../../quest/presentation/widgets/quest_timeline.dart';

/// Bottom sheet with the day's quests, reusing `QuestTimeline`/`QuestTile`.
/// Check-off toggles `completed_at` via the existing quest mutation; adding
/// or editing a quest stays on the Plan screen (out of this issue's scope).
class ToDoSheet extends ConsumerStatefulWidget {
  const ToDoSheet({required this.tripId, required this.dayDate, super.key});

  final String tripId;
  final DateTime dayDate;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required DateTime dayDate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ToDoSheet(tripId: tripId, dayDate: dayDate),
    );
  }

  @override
  ConsumerState<ToDoSheet> createState() => _ToDoSheetState();
}

class _ToDoSheetState extends ConsumerState<ToDoSheet> {
  List<QuestEntity>? _quests;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(questRepositoryProvider);
    final result = await repo.getQuestsForTrip(widget.tripId);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() => _error = failure),
      (quests) => setState(
        () => _quests =
            quests.where((q) => _isSameDate(q.dayDate, widget.dayDate)).toList()
              ..sort((a, b) => a.position.compareTo(b.position)),
      ),
    );
  }

  Future<void> _toggle(QuestEntity quest) async {
    try {
      final updated = await runToggleQuest(
        ref: ref,
        tripId: widget.tripId,
        quest: quest,
      );
      if (!mounted) return;
      setState(() {
        _quests = [
          for (final q in _quests!)
            if (q.id == updated.id) updated else q,
        ];
      });
    } catch (_) {
      // Surfaced via the mutation error listener below.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MutationState<dynamic>>(toggleQuestMutation, (previous, next) {
      if (next is MutationError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(presentationFailureMessage(next.error))),
        );
      }
    });

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.base,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text("Today's to do", style: AppTypography.headlineSerif),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null)
              Text(
                presentationFailureMessage(_error!),
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.accentCoral,
                ),
              )
            else if (_quests == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              QuestTimeline(
                tripId: widget.tripId,
                quests: _quests!,
                onToggle: _toggle,
                onEditQuest: (_) {},
              ),
          ],
        ),
      ),
    );
  }
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
