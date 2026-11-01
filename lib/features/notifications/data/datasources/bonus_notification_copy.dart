import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/planned_reminder_entity.dart';

/// The words on the memory reminders and their Android channel, in one UI
/// language (#252, #307). Built at scheduling time, so a reminder carries
/// the language the app was in when it was scheduled.
class BonusNotificationCopy {
  const BonusNotificationCopy(this._l10n);

  factory BonusNotificationCopy.fromL10n(AppLocalizations l10n) =>
      BonusNotificationCopy(l10n);

  final AppLocalizations _l10n;

  String get arrivalTitle => _l10n.notif_arrivalTitle;
  String get arrivalBody => _l10n.notif_arrivalBody;
  String get channelName => _l10n.notif_channelName;
  String get channelDescription => _l10n.notif_channelDescription;

  /// Title and body for one planned reminder.
  ({String title, String body}) forReminder(PlannedReminderEntity r) {
    final name = r.tripName;
    return switch (r.kind) {
      ReminderKind.dayMorning => (
        title: _l10n.notif_dayMorningTitle(r.dayNumber ?? 1, name),
        body: _l10n.notif_dayMorningBody,
      ),
      ReminderKind.lastDayMorning => (
        title: _l10n.notif_lastDayMorningTitle(name),
        body: _l10n.notif_lastDayMorningBody,
      ),
      ReminderKind.eveningNothingLogged => (
        title: _l10n.notif_nothingLoggedTitle,
        body: _l10n.notif_nothingLoggedBody(name),
      ),
      ReminderKind.eveningDareOpen => (
        title: _l10n.notif_eveningTitle,
        body: _l10n.notif_eveningBody,
      ),
      ReminderKind.lastDayEvening => (
        title: _l10n.notif_lastDayEveningTitle,
        body: _l10n.notif_lastDayEveningBody(name),
      ),
      ReminderKind.afterEnd => (
        title: _l10n.notif_afterEndTitle(name),
        body: _l10n.notif_afterEndBody,
      ),
    };
  }
}
