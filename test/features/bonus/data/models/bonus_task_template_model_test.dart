import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/bonus/data/models/bonus_task_template_model.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';

void main() {
  group('BonusTaskTemplateModel.fromJson', () {
    test('parses a fully populated row', () {
      final model = BonusTaskTemplateModel.fromJson({
        'id': 1,
        'code': 'snap_anything',
        'title': 'Snap anything at all',
        'detail': "Seriously. Anything. This one's just to get you started.",
        'points': 1,
        'phase': 'arrival',
        'kind': 'starter',
      });

      expect(model.id, 1);
      expect(model.code, 'snap_anything');
      expect(model.points, 1);
      expect(model.phase, BonusTaskPhase.arrival);
      expect(model.kind, BonusTaskKind.starter);
    });

    test('parses a null detail', () {
      final model = BonusTaskTemplateModel.fromJson({
        'id': 2,
        'code': 'x',
        'title': 'X',
        'detail': null,
        'points': 2,
        'phase': 'anytime',
        'kind': 'regular',
      });
      expect(model.detail, isNull);
    });
  });
}
