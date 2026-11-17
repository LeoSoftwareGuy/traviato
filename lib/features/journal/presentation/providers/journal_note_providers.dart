import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/journal_note_remote_data_source.dart';
import '../../data/datasources/supabase_journal_note_remote_data_source.dart';
import '../../data/repositories/journal_note_repository_impl.dart';
import '../../domain/repositories/journal_note_repository.dart';

part 'journal_note_providers.g.dart';

@riverpod
JournalNoteRemoteDataSource journalNoteRemoteDataSource(Ref ref) =>
    SupabaseJournalNoteRemoteDataSource(
      client: ref.watch(supabaseClientProvider),
    );

@riverpod
JournalNoteRepository journalNoteRepository(Ref ref) =>
    JournalNoteRepositoryImpl(
      remote: ref.watch(journalNoteRemoteDataSourceProvider),
    );
