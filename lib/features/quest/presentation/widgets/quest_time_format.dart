/// Formats a quest's time-of-day offset as `"HH:mm"`.
String formatQuestTime(Duration time) {
  final hours = time.inHours.toString().padLeft(2, '0');
  final minutes = (time.inMinutes % 60).toString().padLeft(2, '0');
  return '$hours:$minutes';
}
