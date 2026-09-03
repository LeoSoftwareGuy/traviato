import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/home/domain/entities/profile_stats_entity.dart';
import 'package:traviato/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:traviato/features/profile/data/models/achievement_template_model.dart';
import 'package:traviato/features/profile/data/models/profile_model.dart';
import 'package:traviato/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:traviato/features/profile/domain/entities/achievement_entity.dart';

class _FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  Exception? exception;
  List<AchievementTemplateModel> templates = const [];
  Map<int, DateTime> earned = const {};
  Map<String, dynamic>? lastUpdateArgs;

  @override
  Future<ProfileModel> getProfile() async {
    if (exception != null) throw exception!;
    return ProfileModel(
      id: 'u1',
      username: 'ada',
      bio: 'Wanders a lot',
      createdAt: DateTime(2024, 3, 1),
    );
  }

  @override
  Future<ProfileModel> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    if (exception != null) throw exception!;
    lastUpdateArgs = {
      'username': username,
      'bio': bio,
      'avatarUrl': avatarUrl,
    };
    return ProfileModel(
      id: 'u1',
      username: username ?? 'ada',
      bio: bio,
      avatarUrl: avatarUrl,
      createdAt: DateTime(2024, 3, 1),
    );
  }

  @override
  Future<List<AchievementTemplateModel>> getAchievementTemplates() async {
    if (exception != null) throw exception!;
    return templates;
  }

  @override
  Future<Map<int, DateTime>> getEarnedAchievements() async {
    if (exception != null) throw exception!;
    return earned;
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes) async {
    if (exception != null) throw exception!;
    return 'u1/avatar.jpg';
  }

  @override
  Future<String> getAvatarUrl(String storagePath) async {
    if (exception != null) throw exception!;
    return 'https://example.com/$storagePath';
  }
}

const _stats = ProfileStatsEntity(
  memories: 4,
  places: 6,
  countries: 3,
  days: 12,
  stars: 40,
  photos: 8,
  notes: 5,
);

void main() {
  group('getProfile', () {
    test('returns Right(profile) on success', () async {
      final repo = ProfileRepositoryImpl(
        remote: _FakeProfileRemoteDataSource(),
      );
      final result = await repo.getProfile();
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (profile) => expect(profile.username, 'ada'),
      );
    });

    test('maps AuthenticationException', () async {
      final repo = ProfileRepositoryImpl(
        remote: _FakeProfileRemoteDataSource()
          ..exception = const AuthenticationException(message: 'no session'),
      );
      final result = await repo.getProfile();
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('updateProfile', () {
    test('passes only the fields given through to the data source', () async {
      final remote = _FakeProfileRemoteDataSource();
      final repo = ProfileRepositoryImpl(remote: remote);

      await repo.updateProfile(bio: 'New bio');

      expect(remote.lastUpdateArgs, {
        'username': null,
        'bio': 'New bio',
        'avatarUrl': null,
      });
    });
  });

  group('getAchievements', () {
    test(
      'combines templates, earned state, and current value by metric',
      () async {
        final remote = _FakeProfileRemoteDataSource()
          ..templates = [
            const AchievementTemplateModel(
              id: 1,
              code: 'first_adventure',
              title: 'First Adventure',
              description: 'Log your first memory.',
              metric: AchievementMetric.trips,
              target: 1,
              position: 1,
            ),
            const AchievementTemplateModel(
              id: 5,
              code: 'shutterbug',
              title: 'Shutterbug',
              description: 'Add 50 photos.',
              metric: AchievementMetric.photos,
              target: 50,
              position: 5,
            ),
            const AchievementTemplateModel(
              id: 6,
              code: 'storyteller',
              title: 'Storyteller',
              description: 'Write 20 notes.',
              metric: AchievementMetric.notes,
              target: 20,
              position: 6,
            ),
          ]
          ..earned = {1: DateTime(2026, 1, 1)};
        final repo = ProfileRepositoryImpl(remote: remote);

        final result = await repo.getAchievements(_stats);

        result.fold((failure) => fail('expected Right, got Left($failure)'), (
          achievements,
        ) {
          expect(achievements, hasLength(3));

          final firstAdventure = achievements.firstWhere(
            (a) => a.code == 'first_adventure',
          );
          expect(firstAdventure.isEarned, isTrue);
          expect(firstAdventure.currentValue, 4); // stats.memories

          final shutterbug = achievements.firstWhere(
            (a) => a.code == 'shutterbug',
          );
          expect(shutterbug.isEarned, isFalse);
          expect(shutterbug.currentValue, 8); // stats.photos

          final storyteller = achievements.firstWhere(
            (a) => a.code == 'storyteller',
          );
          expect(storyteller.isEarned, isFalse);
          expect(storyteller.currentValue, 5); // stats.notes
        });
      },
    );

    test('maps a data-source failure', () async {
      final repo = ProfileRepositoryImpl(
        remote: _FakeProfileRemoteDataSource()
          ..exception = const NetworkException(),
      );
      final result = await repo.getAchievements(_stats);
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });
  });
}
