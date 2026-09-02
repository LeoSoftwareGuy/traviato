import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/profile/domain/entities/achievement_entity.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  group('isEarned', () {
    test('true when earnedAt is set', () {
      final achievement = buildAchievement(earnedAt: DateTime(2026, 1, 1));
      expect(achievement.isEarned, isTrue);
    });

    test('false when earnedAt is null', () {
      final achievement = buildAchievement();
      expect(achievement.isEarned, isFalse);
    });
  });

  group('progress', () {
    test('is currentValue / target', () {
      final achievement = buildAchievement(currentValue: 9, target: 14);
      expect(achievement.progress, closeTo(9 / 14, 0.0001));
    });

    test('clamps at 1 when currentValue exceeds target', () {
      final achievement = buildAchievement(currentValue: 20, target: 10);
      expect(achievement.progress, 1.0);
    });

    test('is 0 when currentValue is 0', () {
      final achievement = buildAchievement(currentValue: 0, target: 10);
      expect(achievement.progress, 0.0);
    });
  });

  group('progressLabel', () {
    test('formats as "N OF TARGET UNIT"', () {
      final achievement = buildAchievement(
        currentValue: 9,
        target: 14,
        metric: AchievementMetric.daysLogged,
      );
      expect(achievement.progressLabel, '9 OF 14 DAYS');
    });

    test('caps the shown current value at target', () {
      final achievement = buildAchievement(
        currentValue: 300,
        target: 250,
        metric: AchievementMetric.stars,
      );
      expect(achievement.progressLabel, '250 OF 250 STARS');
    });

    test('uses each metric\'s own unit label', () {
      expect(
        buildAchievement(
          metric: AchievementMetric.trips,
          currentValue: 2,
          target: 5,
        ).progressLabel,
        '2 OF 5 MEMORIES',
      );
      expect(
        buildAchievement(
          metric: AchievementMetric.countries,
          currentValue: 6,
          target: 10,
        ).progressLabel,
        '6 OF 10 COUNTRIES',
      );
      expect(
        buildAchievement(
          metric: AchievementMetric.photos,
          currentValue: 3,
          target: 50,
        ).progressLabel,
        '3 OF 50 PHOTOS',
      );
      expect(
        buildAchievement(
          metric: AchievementMetric.notes,
          currentValue: 1,
          target: 20,
        ).progressLabel,
        '1 OF 20 NOTES',
      );
    });
  });

  group('AchievementMetric.fromDb', () {
    test('maps every db metric string', () {
      expect(AchievementMetric.fromDb('trips'), AchievementMetric.trips);
      expect(
        AchievementMetric.fromDb('countries'),
        AchievementMetric.countries,
      );
      expect(
        AchievementMetric.fromDb('days_logged'),
        AchievementMetric.daysLogged,
      );
      expect(AchievementMetric.fromDb('stars'), AchievementMetric.stars);
      expect(AchievementMetric.fromDb('photos'), AchievementMetric.photos);
      expect(AchievementMetric.fromDb('notes'), AchievementMetric.notes);
    });

    test('throws on an unknown metric string', () {
      expect(() => AchievementMetric.fromDb('bogus'), throwsArgumentError);
    });
  });
}
