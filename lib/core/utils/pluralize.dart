/// `pluralize(1, 'day', 'days')` → `day`; any other count → [plural].
/// Returns the noun only — callers place the count themselves so the same
/// helper serves "1 DAY" metas and stat tiles where the number sits apart.
String pluralize(int count, String singular, String plural) =>
    count == 1 ? singular : plural;
