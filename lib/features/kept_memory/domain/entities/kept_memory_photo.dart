import 'package:equatable/equatable.dart';

import '../../../bonus/domain/entities/bonus_task_template_entity.dart';
import '../../../photo/domain/entities/photo_entity.dart';

/// One photo on the Kept Memory page (#279), placed on its day. [bonusTask]
/// is the template of the bonus task this photo completed, if any — its
/// prompt and ✦ show in the strip and the viewer.
class KeptMemoryPhoto extends Equatable {
  const KeptMemoryPhoto({
    required this.photo,
    required this.dayIndex,
    this.bonusTask,
  });

  final PhotoEntity photo;

  /// 1-based day of the memory.
  final int dayIndex;
  final BonusTaskTemplateEntity? bonusTask;

  /// When the photo was taken — or, without EXIF, when it was added.
  DateTime get sortTime => photo.takenAt ?? photo.createdAt;

  @override
  List<Object?> get props => [photo, dayIndex, bonusTask];
}
