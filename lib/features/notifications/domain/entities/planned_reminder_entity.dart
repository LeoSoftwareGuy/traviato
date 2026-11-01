import 'package:equatable/equatable.dart';

/// What a planned memory reminder says (#307). The words live in
/// `BonusNotificationCopy`; the kind also decides where a tap lands.
enum ReminderKind {
  /// ~9:00 on a middle day — "Day N of {name} ✦".
  dayMorning,

  /// ~9:00 on the last day.
  lastDayMorning,

  /// ~19:00 when nothing has been logged that day (the default for every
  /// future day, since a reminder scheduled ahead can't know).
  eveningNothingLogged,

  /// ~19:00 today when something was logged but a bonus task is still open.
  eveningDareOpen,

  /// ~18:00 on the last day — bonus tasks end tonight.
  lastDayEvening,

  /// ~10:00 the day after the memory ends — keep it forever.
  afterEnd,
}

/// One reminder in the pre-scheduled plan for a memory (#307).
class PlannedReminderEntity extends Equatable {
  const PlannedReminderEntity({
    required this.kind,
    required this.fireAt,
    required this.tripId,
    required this.tripName,
    this.dayNumber,
  });

  /// Payload prefix for a reminder whose tap opens the Journal rather than
  /// the bonus tray.
  static const journalPayloadPrefix = 'journal:';

  final ReminderKind kind;
  final DateTime fireAt;
  final String tripId;
  final String tripName;

  /// "Day N" of the memory; `null` for [ReminderKind.afterEnd].
  final int? dayNumber;

  /// Bonus-task reminders open the tray; "log your day" ones the Journal.
  bool get opensJournal => switch (kind) {
    ReminderKind.dayMorning ||
    ReminderKind.lastDayMorning ||
    ReminderKind.eveningDareOpen => false,
    ReminderKind.eveningNothingLogged ||
    ReminderKind.lastDayEvening ||
    ReminderKind.afterEnd => true,
  };

  String get payload => opensJournal ? '$journalPayloadPrefix$tripId' : tripId;

  @override
  List<Object?> get props => [kind, fireAt, tripId, tripName, dayNumber];
}
