import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/trip/presentation/widgets/vibe_chip_group.dart';
import 'package:traviato/features/trip/presentation/widgets/vibe_label.dart';
import 'package:traviato/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ru = lookupAppLocalizations(const Locale('ru'));

  test('English labels equal the stored vibe names', () {
    for (final vibe in kTripVibes) {
      expect(vibeLabel(en, vibe), vibe);
    }
  });

  test('every canonical vibe has its own translation', () {
    final labels = {for (final vibe in kTripVibes) vibeLabel(ru, vibe)};
    expect(labels, hasLength(kTripVibes.length));
    expect(labels.intersection(kTripVibes.toSet()), isEmpty);
  });

  test('an unknown stored vibe is shown as stored', () {
    expect(vibeLabel(ru, 'Skiing'), 'Skiing');
  });
}
