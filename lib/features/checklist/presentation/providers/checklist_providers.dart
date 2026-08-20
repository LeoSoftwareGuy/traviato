import 'package:riverpod_annotation/riverpod_annotation.dart';

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
