import '../../../../l10n/app_localizations.dart';

/// The words on the bonus reminders and their Android channel, in one UI
/// language (#252). Built at scheduling time, so a reminder carries the
/// language the app was in when it was scheduled.
class BonusNotificationCopy {
  const BonusNotificationCopy({
    required this.morningTitle,
    required this.morningBody,
    required this.eveningTitle,
    required this.eveningBody,
    required this.arrivalTitle,
    required this.arrivalBody,
    required this.channelName,
    required this.channelDescription,
  });

  factory BonusNotificationCopy.fromL10n(AppLocalizations l10n) =>
      BonusNotificationCopy(
        morningTitle: l10n.notif_morningTitle,
        morningBody: l10n.notif_morningBody,
        eveningTitle: l10n.notif_eveningTitle,
        eveningBody: l10n.notif_eveningBody,
        arrivalTitle: l10n.notif_arrivalTitle,
        arrivalBody: l10n.notif_arrivalBody,
        channelName: l10n.notif_channelName,
        channelDescription: l10n.notif_channelDescription,
      );

  final String morningTitle;
  final String morningBody;
  final String eveningTitle;
  final String eveningBody;
  final String arrivalTitle;
  final String arrivalBody;
  final String channelName;
  final String channelDescription;
}
