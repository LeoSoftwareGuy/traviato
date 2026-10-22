import 'package:equatable/equatable.dart';

import '../../../journal/domain/entities/day_note_entity.dart';
import 'kept_memory_photo.dart';

/// One chapter of the Kept Memory page (#279): a day's photos in time
/// order and its notes. Only days with at least one of either exist.
class KeptMemoryDay extends Equatable {
  const KeptMemoryDay({
    required this.dayIndex,
    required this.date,
    required this.photos,
    required this.notes,
    required this.firstPhotoIndex,
  });

  /// 1-based day of the memory.
  final int dayIndex;
  final DateTime date;
  final List<KeptMemoryPhoto> photos;
  final List<DayNoteEntity> notes;

  /// Index of this day's first photo in [KeptMemory.photos] — where the
  /// viewer opens from the day's "N photos ›" link.
  final int firstPhotoIndex;

  @override
  List<Object?> get props => [dayIndex, date, photos, notes, firstPhotoIndex];
}
