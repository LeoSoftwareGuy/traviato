import 'package:equatable/equatable.dart';

import '../../domain/entities/achievement_entity.dart';

/// An `achievement_templates` row, before it's combined with the caller's
/// `user_achievements` and a current metric value into an
/// [AchievementEntity] (`ProfileRepositoryImpl.getAchievements()`).
class AchievementTemplateModel extends Equatable {
  const AchievementTemplateModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.metric,
    required this.target,
    required this.position,
  });

  factory AchievementTemplateModel.fromJson(Map<String, dynamic> json) =>
      AchievementTemplateModel(
        id: (json['id'] as num).toInt(),
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        metric: AchievementMetric.fromDb(json['metric'] as String),
        target: (json['target'] as num).toInt(),
        position: (json['position'] as num).toInt(),
      );

  final int id;
  final String code;
  final String title;
  final String description;
  final AchievementMetric metric;
  final int target;
  final int position;

  @override
  List<Object?> get props => [
    id,
    code,
    title,
    description,
    metric,
    target,
    position,
  ];
}
