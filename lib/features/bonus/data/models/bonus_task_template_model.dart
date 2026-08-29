import '../../domain/entities/bonus_task_template_entity.dart';

class BonusTaskTemplateModel extends BonusTaskTemplateEntity {
  const BonusTaskTemplateModel({
    required super.id,
    required super.code,
    required super.title,
    super.detail,
    required super.points,
    required super.phase,
    required super.kind,
  });

  factory BonusTaskTemplateModel.fromJson(Map<String, dynamic> json) =>
      BonusTaskTemplateModel(
        id: (json['id'] as num).toInt(),
        code: json['code'] as String,
        title: json['title'] as String,
        detail: json['detail'] as String?,
        points: (json['points'] as num).toInt(),
        phase: BonusTaskPhase.fromDbValue(json['phase'] as String),
        kind: BonusTaskKind.fromDbValue(json['kind'] as String),
      );
}
