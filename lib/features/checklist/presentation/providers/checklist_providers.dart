import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/checklist_remote_data_source.dart';
import '../../data/datasources/supabase_checklist_remote_data_source.dart';
import '../../data/repositories/checklist_repository_impl.dart';
import '../../domain/repositories/checklist_repository.dart';

part 'checklist_providers.g.dart';

@riverpod
ChecklistRemoteDataSource checklistRemoteDataSource(Ref ref) =>
    SupabaseChecklistRemoteDataSource(
      client: ref.watch(supabaseClientProvider),
    );

@riverpod
ChecklistRepository checklistRepository(Ref ref) => ChecklistRepositoryImpl(
  remote: ref.watch(checklistRemoteDataSourceProvider),
);

/// Packed / total item counts for a trip — used by Home's dashed Checklist
/// row.
class ChecklistProgress {
  const ChecklistProgress({required this.packed, required this.total});

  final int packed;
  final int total;
}

@riverpod
Future<ChecklistProgress> checklistProgressForTrip(
  Ref ref,
  String tripId,
) async {
  final repo = ref.watch(checklistRepositoryProvider);
  final result = await repo.getItems(tripId);
  return result.fold(
    (failure) => throw PresentationFailureException(failure),
    (items) => ChecklistProgress(
      packed: items.where((i) => i.isChecked).length,
      total: items.length,
    ),
  );
}
