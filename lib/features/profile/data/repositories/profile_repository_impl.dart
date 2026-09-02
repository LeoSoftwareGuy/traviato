import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/profile_stats_entity.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required ProfileRemoteDataSource remote})
    : _remote = remote;

  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    try {
      return Right(await _remote.getProfile());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      return Right(
        await _remote.updateProfile(
          username: username,
          bio: bio,
          avatarUrl: avatarUrl,
        ),
      );
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<AchievementEntity>>> getAchievements(
    ProfileStatsEntity stats,
  ) async {
    try {
      final templates = await _remote.getAchievementTemplates();
      final earned = await _remote.getEarnedAchievements();
      return Right([
        for (final template in templates)
          AchievementEntity(
            id: template.id,
            code: template.code,
            title: template.title,
            description: template.description,
            metric: template.metric,
            target: template.target,
            position: template.position,
            currentValue: _currentValue(template.metric, stats),
            earnedAt: earned[template.id],
          ),
      ]);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  int _currentValue(AchievementMetric metric, ProfileStatsEntity stats) =>
      switch (metric) {
        AchievementMetric.trips => stats.memories,
        AchievementMetric.countries => stats.countries,
        AchievementMetric.daysLogged => stats.days,
        AchievementMetric.stars => stats.stars,
        AchievementMetric.photos => stats.photos,
        AchievementMetric.notes => stats.notes,
      };

  @override
  Future<Either<Failure, String>> uploadAvatar(Uint8List bytes) async {
    try {
      return Right(await _remote.uploadAvatar(bytes));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, String>> getAvatarUrl(String storagePath) async {
    try {
      return Right(await _remote.getAvatarUrl(storagePath));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
