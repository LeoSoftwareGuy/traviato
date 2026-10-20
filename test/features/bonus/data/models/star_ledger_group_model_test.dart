import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/bonus/data/models/star_ledger_group_model.dart';
import 'package:traviato/features/bonus/domain/entities/star_ledger_group_entity.dart';

void main() {
  test('maps a star_breakdown_view row', () {
    final model = StarLedgerGroupModel.fromJson(const {
      'user_id': 'u1',
      'trip_id': 't1',
      'source': 'photo',
      'entry_count': 9,
      'points_total': 18,
    });
    expect(model.props, const [
      't1',
      StarSource.photo,
      9,
      18,
    ]);
  });

  test('keeps a null trip_id (stars orphaned before #247)', () {
    final model = StarLedgerGroupModel.fromJson(const {
      'trip_id': null,
      'source': 'note',
      'entry_count': 1,
      'points_total': 1,
    });
    expect(model.tripId, isNull);
  });

  test('maps every known source and counts an unknown one as bonus', () {
    StarSource sourceOf(String value) => StarLedgerGroupModel.fromJson({
      'trip_id': 't1',
      'source': value,
      'entry_count': 1,
      'points_total': 1,
    }).source;

    expect(sourceOf('photo'), StarSource.photo);
    expect(sourceOf('note'), StarSource.note);
    expect(sourceOf('quest'), StarSource.quest);
    expect(sourceOf('bonus_task'), StarSource.bonusTask);
    expect(sourceOf('mystery'), StarSource.bonusTask);
  });
}
