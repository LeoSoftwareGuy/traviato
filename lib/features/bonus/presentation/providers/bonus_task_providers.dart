import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/bonus_task_remote_data_source.dart';
import '../../data/datasources/supabase_bonus_task_remote_data_source.dart';
import '../../data/repositories/bonus_task_repository_impl.dart';
import '../../domain/repositories/bonus_task_repository.dart';
import '../../domain/usecases/ensure_daily_tray_usecase.dart';

part 'bonus_task_providers.g.dart';

@riverpod
BonusTaskRemoteDataSource bonusTaskRemoteDataSource(Ref ref) =>
    SupabaseBonusTaskRemoteDataSource(
      client: ref.watch(supabaseClientProvider),
    );

@riverpod
BonusTaskRepository bonusTaskRepository(Ref ref) => BonusTaskRepositoryImpl(
  remote: ref.watch(bonusTaskRemoteDataSourceProvider),
);

@riverpod
EnsureDailyTrayUseCase ensureDailyTrayUseCase(Ref ref) =>
    EnsureDailyTrayUseCase(repository: ref.watch(bonusTaskRepositoryProvider));
