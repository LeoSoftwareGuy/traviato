import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ru = lookupAppLocalizations(const Locale('ru'));
  final et = lookupAppLocalizations(const Locale('et'));

  test('film footnote labels agree with their numbers (#220)', () {
    expect(en.wrapUp_bonusTasks(1), 'bonus task');
    expect(en.wrapUp_bonusTasks(3), 'bonus tasks');
    expect(ru.wrapUp_photographs(1), 'фотография');
    expect(ru.wrapUp_photographs(3), 'фотографии');
    expect(ru.wrapUp_photographs(25), 'фотографий');
    expect(ru.wrapUp_stars(21), 'звезда');
    expect(et.wrapUp_stars(1), 'täht');
    expect(et.wrapUp_stars(47), 'tähte');
  });

  test('dare toast keeps the spec format', () {
    expect(en.toast_dareDone(3), '+3 ✦ · dare done');
    expect(ru.toast_dareDone(2), '+2 ✦ · задание выполнено');
  });
}
