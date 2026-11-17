import 'package:intl/intl.dart';

/// Date/time formats shared across features, in the UI language (#220).
/// English keeps the exact patterns the app shipped with; ru/et use the
/// locale's own order (day first, 24-hour clock).
abstract final class L10nDates {
  /// "Aug 24" · "24 авг." · "24. aug"
  static DateFormat monthDay(String locale) => DateFormat.MMMd(locale);

  /// "24 Aug" · "24 авг." · "24. aug"
  static DateFormat dayMonth(String locale) =>
      locale == 'en' ? DateFormat('d MMM', locale) : DateFormat.MMMd(locale);

  /// "8:05 AM" · "08:05" · "08:05". English keeps its explicit pattern:
  /// `DateFormat.jm('en')` separates "AM" with a narrow no-break space.
  static DateFormat time(String locale) =>
      locale == 'en' ? DateFormat('h:mm a', locale) : DateFormat.jm(locale);

  /// "Aug 24, 8:05 AM" · "24 авг., 08:05" · "24. aug, 08:05"
  static DateFormat monthDayTime(String locale) => locale == 'en'
      ? DateFormat('MMM d, h:mm a', locale)
      : DateFormat(
          '${DateFormat.MMMd(locale).pattern}, '
          '${DateFormat.jm(locale).pattern}',
          locale,
        );

  /// A clock time on the journal timeline (#401): "06:45" / "21:16" with
  /// the 24-hour clock, else "6:45 AM" — following the phone's setting
  /// (`MediaQuery.alwaysUse24HourFormatOf`).
  static DateFormat clock(String locale, {required bool use24h}) =>
      use24h ? DateFormat('HH:mm', locale) : DateFormat('h:mm a', locale);

  /// "Thu 23 Oct" · "чт, 23 окт." — a day header or divider date.
  static DateFormat weekdayDayMonth(String locale) => locale == 'en'
      ? DateFormat('EEE d MMM', locale)
      : DateFormat.MMMEd(locale);

  /// "Thursday" · "четверг".
  static DateFormat weekday(String locale) => DateFormat.EEEE(locale);
}
