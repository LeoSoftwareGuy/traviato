import 'package:riverpod_annotation/riverpod_annotation.dart';

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
