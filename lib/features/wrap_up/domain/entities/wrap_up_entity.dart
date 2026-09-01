import 'package:equatable/equatable.dart';

import 'wrap_up_achievement_moment.dart';
import 'wrap_up_close.dart';
import 'wrap_up_hero.dart';
import 'wrap_up_photo_beat.dart';
import 'wrap_up_route_chapter.dart';
import 'wrap_up_stat_chapter.dart';

/// The generated wrap-up screenplay for a trip (docs/data-model.md
/// `wrap_ups`, #93's schema). Every block field is nullable and parsed
/// defensively at the data layer — a block that doesn't match the expected
/// shape comes through as `null` rather than throwing, so the page can skip
/// it instead of crashing (issue #94 AC).
class WrapUpEntity extends Equatable {
  const WrapUpEntity({
    this.hero,
    this.routeChapter,
    this.photoBeats = const [],
    this.statChapter,
    this.achievementMoment,
    this.close,
    required this.generatedAt,
    this.publishedAt,
  });

  final WrapUpHero? hero;
  final WrapUpRouteChapter? routeChapter;
  final List<WrapUpPhotoBeat> photoBeats;
  final WrapUpStatChapter? statChapter;
  final WrapUpAchievementMoment? achievementMoment;
  final WrapUpClose? close;
  final DateTime generatedAt;
  final DateTime? publishedAt;

  bool get isPublished => publishedAt != null;

  WrapUpEntity copyWith({DateTime? Function()? publishedAt}) => WrapUpEntity(
    hero: hero,
    routeChapter: routeChapter,
    photoBeats: photoBeats,
    statChapter: statChapter,
    achievementMoment: achievementMoment,
    close: close,
    generatedAt: generatedAt,
    publishedAt: publishedAt != null ? publishedAt() : this.publishedAt,
  );

  @override
  List<Object?> get props => [
    hero,
    routeChapter,
    photoBeats,
    statChapter,
    achievementMoment,
    close,
    generatedAt,
    publishedAt,
  ];
}
