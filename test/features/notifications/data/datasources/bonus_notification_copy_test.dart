import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/notifications/data/datasources/bonus_notification_copy.dart';
import 'package:traviato/features/notifications/domain/entities/planned_reminder_entity.dart';
import 'package:traviato/l10n/app_localizations.dart';

PlannedReminderEntity _reminder(ReminderKind kind) => PlannedReminderEntity(
  kind: kind,
  fireAt: DateTime(2026, 8, 10, 9),
  tripId: 't1',
  tripName: 'Lisbon',
  dayNumber: 3,
);

BonusNotificationCopy _copy(String locale) =>
    BonusNotificationCopy.fromL10n(lookupAppLocalizations(Locale(locale)));

void main() {
  test('English reminders name the memory and its day (#307)', () {
    final copy = _copy('en');
    expect(
      copy.forReminder(_reminder(ReminderKind.dayMorning)).title,
      'Day 3 of Lisbon ✦',
    );
    expect(
      copy.forReminder(_reminder(ReminderKind.lastDayMorning)).title,
      'Last day of Lisbon ✦',
    );
    expect(
      copy.forReminder(_reminder(ReminderKind.eveningDareOpen)).title,
      'Still time for a dare',
    );
    expect(
      copy.forReminder(_reminder(ReminderKind.afterEnd)).title,
      'Lisbon has ended',
    );
    expect(copy.arrivalTitle, 'Your memory starts today ✦');
    expect(copy.channelName, 'Memory reminders');
  });

  test('every reminder kind has a Russian title and body (#252)', () {
    final en = _copy('en');
    final ru = _copy('ru');
    for (final kind in ReminderKind.values) {
      final a = ru.forReminder(_reminder(kind));
      final b = en.forReminder(_reminder(kind));
      expect(a.title, isNot(b.title), reason: '$kind title');
      expect(a.body, isNot(b.body), reason: '$kind body');
      expect(a.title, isNotEmpty);
      expect(a.body, isNotEmpty);
    }
    expect(ru.arrivalTitle, isNot(en.arrivalTitle));
    expect(ru.channelName, isNot(en.channelName));
  });
}
