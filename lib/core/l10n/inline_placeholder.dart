/// Splits a translated sentence around its one inline placeholder, so the
/// placeholder can be styled on its own (bold email, highlighted "10 stars")
/// while translators stay free to move it anywhere in the sentence (#220).
///
/// [message] is the generated l10n getter, e.g. `l10n.auth_rewardTease`.
({String before, String after}) splitAroundPlaceholder(
  String Function(String placeholder) message,
) {
  const marker = '\u{E000}';
  final text = message(marker);
  final index = text.indexOf(marker);
  if (index < 0) return (before: text, after: '');
  return (
    before: text.substring(0, index),
    after: text.substring(index + marker.length),
  );
}
