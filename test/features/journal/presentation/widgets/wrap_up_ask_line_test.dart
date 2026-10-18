import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/l10n/app_localizations.dart';

void main() {
  final ru = lookupAppLocalizations(const Locale('ru'));
  final et = lookupAppLocalizations(const Locale('et'));

  test('Russian ask lines', () {
    expect(
      ru.journal_wrapUpAskPhotosAndNote(2),
      'Добавьте ещё 2 фото и одну заметку, чтобы открыть фильм.',
    );
    expect(
      ru.journal_wrapUpAskPhotos(1),
      'Добавьте ещё 1 фото, чтобы открыть фильм.',
    );
  });

  test('Estonian ask lines use the partitive after 2+', () {
    expect(et.journal_wrapUpAskPhotos(1), 'Lisa veel 1 foto, et film avada.');
    expect(et.journal_wrapUpAskPhotos(3), 'Lisa veel 3 fotot, et film avada.');
  });

  test('batch photo toast keeps the spec format', () {
    expect(ru.toast_photosLogged(6, 3), '+6 ✦ · 3 фото добавлено');
    expect(et.toast_photosLogged(2, 1), '+2 ✦ · 1 foto lisatud');
  });
}
