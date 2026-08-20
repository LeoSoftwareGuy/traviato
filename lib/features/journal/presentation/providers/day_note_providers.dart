import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/day_note_remote_data_source.dart';
import '../../data/datasources/supabase_day_note_remote_data_source.dart';
import '../../data/repositories/day_note_repository_impl.dart';
import '../../domain/repositories/day_note_repository.dart';

part 'day_note_providers.g.dart';

@riverpod
DayNoteRemoteDataSource dayNoteRemoteDataSource(Ref ref) =>
    SupabaseDayNoteRemoteDataSource(client: ref.watch(supabaseClientProvider));

@riverpod
DayNoteRepository dayNoteRepository(Ref ref) =>
    DayNoteRepositoryImpl(remote: ref.watch(dayNoteRemoteDataSourceProvider));
