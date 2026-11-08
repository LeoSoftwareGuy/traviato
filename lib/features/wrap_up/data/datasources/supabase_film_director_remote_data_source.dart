import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/film_photo_analysis.dart';
import '../../domain/entities/film_plan_inspection.dart';
import '../models/film_director_report_model.dart';
import 'film_director_remote_data_source.dart';
import 'supabase_wrap_up_remote_data_source.dart';

class SupabaseFilmDirectorRemoteDataSource
    implements FilmDirectorRemoteDataSource {
  SupabaseFilmDirectorRemoteDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  void _guardAuthenticated() {
    if (_client.auth.currentUser == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
  }

  @override
  Future<FilmPlanInspection> getInspection(String tripId) async {
    _guardAuthenticated();
    try {
      final wrapUp = await _client
          .from(Tables.wrapUps)
          .select('director')
          .eq('trip_id', tripId)
          .maybeSingle();
      final rows = await _client
          .from(Tables.photoAnalysis)
          .select(
            'photo_id, summary, setting, people, energy, quality, '
            'hero_score, dup_group',
          )
          .eq('trip_id', tripId);
      return FilmPlanInspection(
        report: FilmDirectorReportModel.fromJson(wrapUp?['director']),
        analyses: {
          for (final analysis
              in rows
                  .map(filmPhotoAnalysisFromRow)
                  .whereType<FilmPhotoAnalysis>())
            analysis.photoId: analysis,
        },
      );
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    }
  }

  @override
  Future<void> rerun(String tripId, {required String language}) async {
    _guardAuthenticated();
    try {
      await _client.functions.invoke(
        EdgeFunctions.generateWrapUp,
        body: {...generateWrapUpBody(tripId, language), 'director': 'rerun'},
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map && details['error'] is String
          ? details['error'] as String
          : e.reasonPhrase ?? 'Director run failed.';
      if (e.status == 403) throw PermissionException(message: message);
      if (e.status == 0) throw const NetworkException();
      throw ServerException(message: message);
    } on SocketException {
      throw const NetworkException();
    }
  }
}
