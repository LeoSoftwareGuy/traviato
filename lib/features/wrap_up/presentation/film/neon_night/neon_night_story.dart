import 'package:equatable/equatable.dart';

/// One row of "Tonight's plan" (#363, NEON_NIGHT_SPEC.md §5.2, §7): a
/// quest with a time, ticked if it was done.
class NnPlanRow extends Equatable {
  const NnPlanRow({required this.time, required this.item, this.done = false});

  /// 'HH:MM'.
  final String time;

  /// The quest's title, in the user's words (shown in capitals).
  final String item;
  final bool done;

  @override
  List<Object?> get props => [time, item, done];
}

/// One photo of the night (§7): its id and when it was taken.
class NnPhoto extends Equatable {
  const NnPhoto({required this.id, required this.takenAt});

  final String id;

  /// 'HH:MM'.
  final String takenAt;

  @override
  List<Object?> get props => [id, takenAt];
}

/// One chapter of the night (§7): a stretch of time with its photos.
class NnChapter extends Equatable {
  NnChapter({
    required this.title,
    required this.from,
    required this.to,
    required this.photos,
    this.note,
  }) : assert(photos.isNotEmpty, 'a chapter has photos');

  /// The director's title in the UI language, e.g. "Doors open".
  final String title;

  /// 'HH:MM'.
  final String from;
  final String to;

  /// In order; the contact sheet shows the first 34.
  final List<NnPhoto> photos;

  /// The user's own words, typed out on the card; none → no typed line.
  final String? note;

  @override
  List<Object?> get props => [title, from, to, photos, note];
}

/// What the Neon Night film shows of one memory (#363, spec §7). Grows
/// phase by phase: the title, the night's date, the plan and the chapters.
class NeonNightStory extends Equatable {
  NeonNightStory({
    required this.title,
    required this.date,
    required this.chapters,
    this.plan = const [],
  }) : assert(
         chapters.isNotEmpty && chapters.length <= 5,
         '1–5 chapters',
       );

  /// The memory's title, e.g. "Night out" (shown in capitals).
  final String title;

  /// The night it started; shown as 'SAT 14 NOV' in the UI language.
  final DateTime date;

  /// The memory's quests with times, in order; none → no Plan scene.
  final List<NnPlanRow> plan;

  /// 1–5.
  final List<NnChapter> chapters;

  bool get hasPlan => plan.isNotEmpty;

  @override
  List<Object?> get props => [title, date, plan, chapters];
}

/// The spec's reference night (the MP4 in docs/design/neon-night/), for
/// the debug preview and the goldens.
abstract final class NeonNightFixtures {
  /// [count] photos `'$prefix-1'…`, taken evenly from [from] (minutes
  /// after midnight, may pass 24 h) over [minutes].
  static List<NnPhoto> photos(
    String prefix,
    int count, {
    required int from,
    required int minutes,
  }) => [
    for (var i = 0; i < count; i++)
      NnPhoto(
        id: '$prefix-${i + 1}',
        takenAt: _clock(from + (count == 1 ? 0 : minutes * i ~/ (count - 1))),
      ),
  ];

  static String _clock(int minutes) {
    final m = minutes % (24 * 60);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(m ~/ 60)}:${two(m % 60)}';
  }

  /// The reference's chapters (34, 12 and 40 photos: 5, 2 and 5 sheet
  /// rows, as in the MP4).
  static List<NnChapter> _chapters({required bool russian}) => [
    NnChapter(
      title: russian ? 'Двери открыты' : 'Doors open',
      from: '22:10',
      to: '23:40',
      photos: photos('ch1', 34, from: 22 * 60 + 10, minutes: 90),
      note: russian
          ? 'Очередь того стоила. Почти.'
          : 'Queue was worth it. Barely.',
    ),
    NnChapter(
      title: russian ? 'После полуночи' : 'After midnight',
      from: '23:40',
      to: '00:10',
      photos: photos('ch2', 12, from: 23 * 60 + 40, minutes: 30),
    ),
    NnChapter(
      title: russian ? 'Пик ночи' : 'Peak time',
      from: '00:10',
      to: '03:10',
      photos: photos('ch3', 40, from: 24 * 60 + 10, minutes: 180),
      note: russian
          ? 'Нашли всех у сцены. Потеряли куртку.'
          : 'Found everyone at the front. Lost the jacket.',
    ),
  ];

  static final reference = NeonNightStory(
    title: 'Night out',
    date: DateTime(2026, 11, 14),
    chapters: _chapters(russian: false),
    plan: const [
      NnPlanRow(time: '22:00', item: 'Pre-drinks', done: true),
      NnPlanRow(time: '23:30', item: 'Main stage', done: true),
      NnPlanRow(time: '01:00', item: 'Secret room', done: true),
      NnPlanRow(time: '03:00', item: 'Afterparty'),
      NnPlanRow(time: '06:00', item: 'Sunrise'),
    ],
  );

  static final referenceRu = NeonNightStory(
    title: 'Ночь в городе',
    date: DateTime(2026, 11, 14),
    chapters: _chapters(russian: true),
    plan: const [
      NnPlanRow(time: '22:00', item: 'Разогрев', done: true),
      NnPlanRow(time: '23:30', item: 'Главная сцена', done: true),
      NnPlanRow(time: '01:00', item: 'Тайная комната', done: true),
      NnPlanRow(time: '03:00', item: 'Афтепати'),
      NnPlanRow(time: '06:00', item: 'Рассвет'),
    ],
  );

  /// A longer plan: 8 quests, so "+3 MORE" shows.
  static final longPlan = NeonNightStory(
    title: 'Festival weekend',
    date: DateTime(2026, 7, 4),
    chapters: _chapters(russian: false),
    plan: const [
      NnPlanRow(time: '14:00', item: 'Gates open', done: true),
      NnPlanRow(time: '15:30', item: 'Tent stage', done: true),
      NnPlanRow(time: '18:00', item: 'Food trucks'),
      NnPlanRow(time: '20:00', item: 'Headliner', done: true),
      NnPlanRow(time: '22:00', item: 'Silent disco', done: true),
      NnPlanRow(time: '23:30', item: 'Fireworks', done: true),
      NnPlanRow(time: '01:00', item: 'Afterparty'),
      NnPlanRow(time: '04:00', item: 'Camp'),
    ],
  );

  /// A small night: 2 photos in Ch 1 (two zooms, a 12-beat card), 1 in
  /// the last (one zoom), and no notes.
  static final few = NeonNightStory(
    title: 'Small hours',
    date: DateTime(2026, 11, 14),
    chapters: [
      NnChapter(
        title: 'Warm-up',
        from: '23:00',
        to: '23:30',
        photos: photos('few1', 2, from: 23 * 60, minutes: 30),
      ),
      NnChapter(
        title: 'The long middle bit',
        from: '23:30',
        to: '01:00',
        photos: photos('few2', 6, from: 23 * 60 + 30, minutes: 90),
      ),
      NnChapter(
        title: 'Home',
        from: '01:00',
        to: '01:20',
        photos: photos('few3', 1, from: 60, minutes: 20),
      ),
    ],
  );

  /// Every photo id in [story], in order.
  static Iterable<String> photoIds(NeonNightStory story) => [
    for (final chapter in story.chapters)
      for (final photo in chapter.photos) photo.id,
  ];
}
