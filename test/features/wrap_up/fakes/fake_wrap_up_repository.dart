import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_achievement_moment.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_close.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_entity.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_hero.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_photo_beat.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_route_chapter.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_stat_chapter.dart';
import 'package:traviato/features/wrap_up/domain/repositories/wrap_up_repository.dart';

class FakeWrapUpRepository implements WrapUpRepository {
  Either<Failure, WrapUpEntity>? getOrGenerateResult;
  Either<Failure, void>? publishResult;
  var getOrGenerateCallCount = 0;
  var publishCallCount = 0;

  /// Delays [getOrGenerate] so tests can observe the loading state.
  Duration delay = Duration.zero;

  @override
  Future<Either<Failure, WrapUpEntity>> getOrGenerate(String tripId) async {
    getOrGenerateCallCount++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return getOrGenerateResult ?? Right(buildWrapUpEntity());
  }

  @override
  Future<Either<Failure, void>> publish(String tripId) async {
    publishCallCount++;
    return publishResult ?? const Right(null);
  }
}

WrapUpEntity buildWrapUpEntity({
  WrapUpHero? hero,
  WrapUpRouteChapter? routeChapter,
  List<WrapUpPhotoBeat> photoBeats = const [],
  WrapUpStatChapter? statChapter,
  WrapUpAchievementMoment? achievementMoment,
  WrapUpClose? close,
  DateTime? generatedAt,
  DateTime? publishedAt,
}) {
  return WrapUpEntity(
    hero: hero ?? const WrapUpHero(title: 'Dolomites, slowly'),
    routeChapter: routeChapter,
    photoBeats: photoBeats,
    statChapter: statChapter,
    achievementMoment: achievementMoment,
    close: close ?? const WrapUpClose(line: "This one you'll keep."),
    generatedAt: generatedAt ?? DateTime(2026, 1, 1),
    publishedAt: publishedAt,
  );
}
