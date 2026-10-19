import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/notifications/data/datasources/bonus_notification_copy.dart';
import 'package:traviato/l10n/app_localizations.dart';

void main() {
  test('English keeps the reminder copy from #65', () {
    final copy = BonusNotificationCopy.fromL10n(
      lookupAppLocalizations(const Locale('en')),
    );
    expect(copy.morningTitle, 'Two little dares today ✦');
    expect(copy.eveningTitle, 'Still time for a dare');
    expect(copy.arrivalTitle, 'Your trip starts today ✦');
    expect(copy.channelName, 'Bonus dares');
  });

  test('Russian reminders are translated (#252)', () {
    final en = BonusNotificationCopy.fromL10n(
      lookupAppLocalizations(const Locale('en')),
    );
    final ru = BonusNotificationCopy.fromL10n(
      lookupAppLocalizations(const Locale('ru')),
    );
    expect(ru.morningTitle, 'Два маленьких задания на сегодня ✦');
    for (final (a, b) in [
      (ru.morningBody, en.morningBody),
      (ru.eveningTitle, en.eveningTitle),
      (ru.eveningBody, en.eveningBody),
      (ru.arrivalTitle, en.arrivalTitle),
      (ru.arrivalBody, en.arrivalBody),
      (ru.channelName, en.channelName),
      (ru.channelDescription, en.channelDescription),
    ]) {
      expect(a, isNot(b));
      expect(a, isNotEmpty);
    }
  });
}
