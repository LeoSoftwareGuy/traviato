import 'package:equatable/equatable.dart';

import 'neon_night_scene_spec.dart';

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

/// A block that shows a few of a chapter's photos after its card
/// (§5.4–5.6, §7). Which one a chapter gets is the app's choice.
sealed class NnMoment extends Equatable {
  // Not const: the moments assert their photo counts, which a const
  // constructor cannot.
  // ignore: prefer_const_constructors_in_immutables
  NnMoment(this.photos);

  final List<NnPhoto> photos;

  NnMomentType get type;

  @override
  List<Object?> get props => [type, photos];
}

/// 2–3 photos side by side, taken close together (§5.4a). Labelled with
/// the first one's time and, when known, the place.
class NnSplit extends NnMoment {
  NnSplit(super.photos, {this.place})
    : assert(photos.length >= 2 && photos.length <= 3, 'split: 2–3 photos');

  final String? place;

  @override
  NnMomentType get type => NnMomentType.split;

  @override
  List<Object?> get props => [...super.props, place];
}

/// 2–4 photos taken within a minute, tossed in one by one (§5.4b).
class NnBurst extends NnMoment {
  NnBurst(super.photos)
    : assert(photos.length >= 2 && photos.length <= 4, 'burst: 2–4 photos');

  @override
  NnMomentType get type => NnMomentType.burst;
}

/// 2–8 photos across the chapter, in time order, with their times
/// (§5.5b).
class NnTimeline extends NnMoment {
  NnTimeline(super.photos)
    : assert(
        photos.length >= 2 && photos.length <= 8,
        'timeline: 2–8 photos',
      );

  @override
  NnMomentType get type => NnMomentType.timeline;
}

/// 3–5 standout photos fanned over a laser fan (§5.6b), labelled with
/// the first and last one's times.
class NnPeak extends NnMoment {
  NnPeak(super.photos)
    : assert(photos.length >= 3 && photos.length <= 5, 'peak: 3–5 photos');

  @override
  NnMomentType get type => NnMomentType.peak;
}

/// One chapter of the night (§7): a stretch of time with its photos.
class NnChapter extends Equatable {
  NnChapter({
    required this.title,
    required this.from,
    required this.to,
    required this.photos,
    required this.moments,
    this.note,
  }) : assert(photos.isNotEmpty, 'a chapter has photos'),
       assert(
         moments.isNotEmpty && moments.length <= 2,
         'a chapter has 1–2 moments',
       );

  /// The director's title in the UI language, e.g. "Doors open".
  final String title;

  /// 'HH:MM'.
  final String from;
  final String to;

  /// In order; the contact sheet shows the first 34.
  final List<NnPhoto> photos;

  /// The user's own words, typed out on the card; none → no typed line.
  final String? note;

  /// The 1–2 blocks after the card, in order.
  final List<NnMoment> moments;

  @override
  List<Object?> get props => [title, from, to, photos, note, moments];
}

/// The note the film writes out in neon (§5.7, §7): the user's own words,
/// over a blurred photo of the night.
class NnNoteMoment extends Equatable {
  const NnNoteMoment({
    required this.text,
    required this.number,
    this.time,
    this.photo,
  });

  /// The note as the user wrote it; their line breaks are kept.
  final String text;

  /// Its place among the memory's notes, from 1: the tag's "NOTE 04".
  final int number;

  /// 'HH:MM', when it was written; none → the tag is just the number.
  final String? time;

  /// The blurred background; none → the haze shows through.
  final NnPhoto? photo;

  @override
  List<Object?> get props => [text, number, time, photo];
}

/// What the Neon Night film shows of one memory (#363, spec §7). Grows
/// phase by phase: the title, the night's date, the plan, the chapters
/// and the note.
class NeonNightStory extends Equatable {
  NeonNightStory({
    required this.title,
    required this.date,
    required this.chapters,
    this.plan = const [],
    this.note,
    this.firstName,
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

  /// The note written out in neon; none → no Note scene.
  final NnNoteMoment? note;

  /// Signs the note (`— Leo`); none → no signature.
  final String? firstName;

  bool get hasPlan => plan.isNotEmpty;
  bool get hasNote => note != null;

  @override
  List<Object?> get props => [title, date, plan, chapters, note, firstName];
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
  /// rows, as in the MP4) and their moments: Ch 1 split + burst, Ch 2
  /// timeline, Ch 3 peak.
  static List<NnChapter> _chapters({required bool russian}) {
    final ch1 = photos('ch1', 34, from: 22 * 60 + 10, minutes: 90);
    final ch2 = photos('ch2', 12, from: 23 * 60 + 40, minutes: 30);
    final ch3 = photos('ch3', 40, from: 24 * 60 + 10, minutes: 180);
    return [
      NnChapter(
        title: russian ? 'Двери открыты' : 'Doors open',
        from: '22:10',
        to: '23:40',
        photos: ch1,
        note: russian
            ? 'Очередь того стоила. Почти.'
            : 'Queue was worth it. Barely.',
        moments: [
          NnSplit(
            ch1.sublist(22, 25),
            place: russian ? 'Главная сцена' : 'Main stage',
          ),
          NnBurst(ch1.sublist(30, 34)),
        ],
      ),
      NnChapter(
        title: russian ? 'После полуночи' : 'After midnight',
        from: '23:40',
        to: '00:10',
        photos: ch2,
        moments: [NnTimeline(ch2.sublist(0, 8))],
      ),
      NnChapter(
        title: russian ? 'Пик ночи' : 'Peak time',
        from: '00:10',
        to: '03:10',
        photos: ch3,
        note: russian
            ? 'Нашли всех у сцены. Потеряли куртку.'
            : 'Found everyone at the front. Lost the jacket.',
        moments: [
          NnPeak([ch3[0], ch3[2], ch3[4], ch3[5], ch3[6]]),
        ],
      ),
    ];
  }

  static final reference = NeonNightStory(
    title: 'Night out',
    date: DateTime(2026, 11, 14),
    chapters: _chapters(russian: false),
    firstName: 'Leo',
    note: const NnNoteMoment(
      text:
          'We lost each other\nFound each other\nBy the bass\n'
          'Best night ever',
      number: 4,
      time: '00:31',
      photo: NnPhoto(id: 'ch3-10', takenAt: '00:56'),
    ),
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
    firstName: 'Лео',
    note: const NnNoteMoment(
      text: 'Потерялись\nНашлись у басов\nЛучшая ночь',
      number: 4,
      time: '00:31',
      photo: NnPhoto(id: 'ch3-10', takenAt: '00:56'),
    ),
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

  /// A small night: 2 photos in Ch 1 (two zooms, a 12-beat card, a
  /// 2-strip split), 6 in Ch 2 (a 2-frame burst and a 3-item timeline), 3
  /// in the last (one zoom, a 3-strip peak), and no notes or places.
  static final few = () {
    final ch1 = photos('few1', 2, from: 23 * 60, minutes: 30);
    final ch2 = photos('few2', 6, from: 23 * 60 + 30, minutes: 90);
    final ch3 = photos('few3', 3, from: 60, minutes: 20);
    return NeonNightStory(
      title: 'Small hours',
      date: DateTime(2026, 11, 14),
      // No time, no photo, no first name: the tag is just the number and
      // the note isn't signed.
      note: const NnNoteMoment(text: 'Short and sweet', number: 1),
      chapters: [
        NnChapter(
          title: 'Warm-up',
          from: '23:00',
          to: '23:30',
          photos: ch1,
          moments: [NnSplit(ch1)],
        ),
        NnChapter(
          title: 'The long middle bit',
          from: '23:30',
          to: '01:00',
          photos: ch2,
          moments: [
            NnBurst(ch2.sublist(0, 2)),
            NnTimeline(ch2.sublist(2, 5)),
          ],
        ),
        NnChapter(
          title: 'Home',
          from: '01:00',
          to: '01:20',
          photos: ch3,
          moments: [NnPeak(ch3)],
        ),
      ],
    );
  }();

  /// Every photo id in [story], in order.
  static Iterable<String> photoIds(NeonNightStory story) => {
    for (final chapter in story.chapters) ...[
      for (final photo in chapter.photos) photo.id,
      for (final moment in chapter.moments)
        for (final photo in moment.photos) photo.id,
    ],
    ?story.note?.photo?.id,
  };
}
