import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/photo_remote_data_source.dart';
import '../../data/datasources/supabase_photo_remote_data_source.dart';
import '../../data/repositories/photo_repository_impl.dart';
import '../../data/services/photo_compressor.dart';
import '../../data/services/photo_exif_reader.dart';
import '../../domain/repositories/photo_repository.dart';

part 'photo_providers.g.dart';

@riverpod
PhotoRemoteDataSource photoRemoteDataSource(Ref ref) =>
    SupabasePhotoRemoteDataSource(client: ref.watch(supabaseClientProvider));

@riverpod
PhotoRepository photoRepository(Ref ref) =>
    PhotoRepositoryImpl(remote: ref.watch(photoRemoteDataSourceProvider));

@riverpod
PhotoCompressor photoCompressor(Ref ref) => const PhotoCompressor();

@riverpod
PhotoExifReader photoExifReader(Ref ref) => const PhotoExifReader();
