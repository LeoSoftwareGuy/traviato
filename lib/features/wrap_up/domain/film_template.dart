/// The film a memory plays, chosen from its vibes (#433) — the same
/// mapping as `supabase/functions/generate_wrap_up/film_templates.json`
/// (`film_template_test.dart` fails if they disagree). The edge function
/// decides it before the director runs, and the director can't change it.
enum FilmTemplate {
  goldenVows('golden_vows'),
  neonNight('neon_night'),
  fieldNotes('field_notes'),
  skyStory('sky_story');

  const FilmTemplate(this.code);

  /// The id the edge function uses.
  final String code;

  /// The vibe rules in priority order: the first with a vibe of the memory
  /// wins (Romantic > Nightlife > outdoors > the rest).
  static const priority = <(FilmTemplate, List<String>)>[
    (FilmTemplate.goldenVows, ['Romantic']),
    (FilmTemplate.neonNight, ['Nightlife']),
    (FilmTemplate.fieldNotes, ['Adventure', 'Road trip', 'Wildlife']),
  ];

  /// No rule matched.
  static const fallback = FilmTemplate.skyStory;

  /// What a template plays as until it ships.
  static const playsAs = {FilmTemplate.fieldNotes: FilmTemplate.skyStory};

  /// The template [vibes] choose. Vibes match ignoring case and spacing.
  static FilmTemplate chosenFor(Iterable<String> vibes) {
    final own = {for (final v in vibes) v.trim().toLowerCase()};
    for (final (template, ruleVibes) in priority) {
      if (ruleVibes.any((v) => own.contains(v.toLowerCase()))) return template;
    }
    return fallback;
  }

  /// The film [vibes] play today (Field Notes → Sky Story until it ships).
  static FilmTemplate playedFor(Iterable<String> vibes) {
    final chosen = chosenFor(vibes);
    return playsAs[chosen] ?? chosen;
  }
}
