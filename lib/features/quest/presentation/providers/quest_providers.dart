import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/quest_remote_data_source.dart';
import '../../data/datasources/supabase_quest_remote_data_source.dart';
import '../../data/repositories/quest_repository_impl.dart';
import '../../domain/repositories/quest_repository.dart';

part 'quest_providers.g.dart';

@riverpod
QuestRemoteDataSource questRemoteDataSource(Ref ref) =>
    SupabaseQuestRemoteDataSource(client: ref.watch(supabaseClientProvider));

@riverpod
QuestRepository questRepository(Ref ref) =>
    QuestRepositoryImpl(remote: ref.watch(questRemoteDataSourceProvider));

/// Planned-quest count for a trip — used by Home's Coming-up planning-state
/// line. `trip_card_view` doesn't carry this, so it's derived here rather
/// than adding a column.
@riverpod
Future<int> questCountForTrip(Ref ref, String tripId) async {
  final repo = ref.watch(questRepositoryProvider);
  final result = await repo.getQuestsForTrip(tripId);
  return result.fold(
    (failure) => throw PresentationFailureException(failure),
    (quests) => quests.length,
  );
}
