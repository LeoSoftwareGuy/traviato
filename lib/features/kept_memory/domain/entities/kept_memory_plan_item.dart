import 'package:equatable/equatable.dart';

import '../../../quest/domain/entities/quest_entity.dart';

/// A quest from the memory's plan, read-only on the Kept Memory page (#279).
class KeptMemoryPlanItem extends Equatable {
  const KeptMemoryPlanItem({required this.quest, required this.dayIndex});

  final QuestEntity quest;

  /// 1-based day of the memory.
  final int dayIndex;

  bool get isDone => quest.isCompleted;

  @override
  List<Object?> get props => [quest, dayIndex];
}
