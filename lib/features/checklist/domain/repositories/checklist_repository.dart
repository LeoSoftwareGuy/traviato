import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/checklist_category.dart';
import '../entities/checklist_item_entity.dart';
import '../entities/checklist_suggestion_entity.dart';

abstract interface class ChecklistRepository {
  Future<Either<Failure, List<ChecklistItemEntity>>> getItems(String tripId);

  Future<Either<Failure, List<ChecklistSuggestionEntity>>> getSuggestions();

  Future<Either<Failure, ChecklistItemEntity>> addCustomItem({
    required String tripId,
    required ChecklistCategory category,
    required String title,
    required int position,
  });

  Future<Either<Failure, ChecklistItemEntity>> toggleChecked({
    required String id,
    required bool checked,
  });

  /// Copies the global suggestions catalog into `checklist_items` for
  /// [tripId] (client-side batch insert), one sequential `position` per
  /// category. Called once, on first open of an empty checklist.
  Future<Either<Failure, List<ChecklistItemEntity>>> populateFromSuggestions(
    String tripId,
  );
}
