import 'package:equatable/equatable.dart';

/// One photo-with-note page (spec §5.3): the photo, the note on its taped
/// card and the caption under it ("THE VOWS · 15:10"), each optional.
class GvHero extends Equatable {
  const GvHero({required this.photoId, this.note, this.caption});

  final String photoId;
  final String? note;
  final String? caption;

  @override
  List<Object?> get props => [photoId, note, caption];
}

/// A titled album page of up to 3 prints ("Getting ready" · "CHAPTER ONE
/// · MORNING"); the carousel page is one too, with up to 12.
class GvChapter extends Equatable {
  const GvChapter({required this.title, required this.photoIds, this.line});

  final String title;
  final String? line;
  final List<String> photoIds;

  @override
  List<Object?> get props => [title, line, photoIds];
}

/// What the Golden Vows film shows of one memory (#346, spec §6).
class GoldenVowsStory extends Equatable {
  const GoldenVowsStory({
    required this.names,
    required this.date,
    this.occasionLine,
    this.place,
    this.packed = const [],
    this.packedTotal,
    this.heroes = const [],
    this.chapters = const [],
    this.carousel,
    this.heartPhotoIds = const [],
    this.endLine,
    this.dayCount = 1,
  });

  /// The occasion in the UI language ("Our Wedding Day"); none → the
  /// line is left out.
  final String? occasionLine;

  /// The memory's title, e.g. "Anna & Marco".
  final String names;
  final DateTime date;

  /// The memory's "where"; none → left out.
  final String? place;

  /// What was packed, in the user's own words; the card shows up to
  /// [maxPacked]. None → no packing card.
  final List<String> packed;

  /// "X OF Y": how many there were to pack, at least the packed ones.
  final int? packedTotal;

  /// One photo-with-note page each.
  final List<GvHero> heroes;

  /// One page of 3 prints each, layouts cycling A, B, C.
  final List<GvChapter> chapters;

  /// Two rows of prints sliding past; null or no photos → no page.
  final GvChapter? carousel;

  /// Every photo of the memory (spec §6 `allPhotos`): they form the heart,
  /// up to [maxHeartPhotos] of them. None → no heart.
  final List<String> heartPhotoIds;

  /// The line under the balloon; null → "Forever starts here".
  final String? endLine;

  /// The heart page's line: "{N} MOMENTS · ONE DAY".
  int get momentCount => heartPhotoIds.length;
  final int dayCount;

  static const maxHeartPhotos = 200;

  /// The heart's photos, capped.
  List<String> get heartPhotos => heartPhotoIds.take(maxHeartPhotos).toList();

  static const maxPacked = 5;
  static const maxChapterPhotos = 3;
  static const maxCarouselPhotos = 12;

  bool get hasCarousel => carousel?.photoIds.isNotEmpty ?? false;

  /// Every photo the album shows, each once, in order of appearance.
  List<String> get albumPhotoIds => {
    for (final hero in heroes) hero.photoId,
    for (final chapter in chapters) ...chapter.photoIds.take(maxChapterPhotos),
    if (hasCarousel) ...carousel!.photoIds.take(maxCarouselPhotos),
  }.toList();

  List<String> get packedShown => packed.take(maxPacked).toList();

  bool get hasPackingCard => packed.isNotEmpty;

  @override
  List<Object?> get props => [
    occasionLine,
    names,
    date,
    place,
    packed,
    packedTotal,
    heroes,
    chapters,
    carousel,
    heartPhotoIds,
    endLine,
    dayCount,
  ];
}

/// The spec's wedding (§5), for the debug preview and tests.
abstract final class GoldenVowsFixtures {
  static final wedding = GoldenVowsStory(
    occasionLine: 'Our Wedding Day',
    names: 'Anna & Marco',
    date: DateTime(2026, 6, 14),
    place: 'Lake Bled, Slovenia',
    packed: const [
      'Rings, triple-checked',
      "Grandma's pearl earrings",
      'Vows, written at 2am',
      'Flat shoes for dancing',
      'Tissues. So many tissues.',
    ],
    packedTotal: 5,
    heroes: _heroes([
      ('You cried before I did.', 'The vows · 15:10'),
      ("Picked from Mum's garden", 'The bouquet · 11:40'),
      ('Gold, like that evening', 'The rings · 15:22'),
      ('Barefoot by the last song', 'First dance · 21:05'),
    ]),
    chapters: _chapters([
      ('Getting ready', 'Chapter one · Morning'),
      ('The ceremony', 'Chapter two · Midday'),
      ('Just married', 'Chapter three · Afternoon'),
    ]),
    carousel: _carousel('And the night went on', 'Chapter four · Evening'),
    heartPhotoIds: heartIds(64),
  );

  static final weddingRu = GoldenVowsStory(
    occasionLine: 'День нашей свадьбы',
    names: 'Анна и Марко',
    date: DateTime(2026, 6, 14),
    place: 'Озеро Блед, Словения',
    packed: const [
      'Кольца, трижды проверены',
      'Бабушкины жемчужные серьги',
      'Клятвы, написанные в 2 ночи',
      'Балетки для танцев',
      'Салфетки. Очень много салфеток.',
    ],
    packedTotal: 5,
    heroes: _heroes([
      ('Ты заплакала раньше меня.', 'Клятвы · 15:10'),
      ('Цветы из маминого сада', 'Букет · 11:40'),
      ('Золото, как тот вечер', 'Кольца · 15:22'),
      ('Босиком до последней песни', 'Первый танец · 21:05'),
    ]),
    chapters: _chapters([
      ('Сборы', 'Глава первая · Утро'),
      ('Церемония', 'Глава вторая · Полдень'),
      ('Мы женаты', 'Глава третья · День'),
    ]),
    carousel: _carousel('А вечер продолжался', 'Глава четвёртая · Вечер'),
    heartPhotoIds: heartIds(64),
  );

  /// The fixture's photo ids: `hero-1`…, `chapter-1-1`…, `carousel-1`….
  /// Nothing ships for them; tests generate placeholder images.
  static List<GvHero> _heroes(List<(String, String)> pages) => [
    for (final (i, (note, caption)) in pages.indexed)
      GvHero(photoId: 'hero-${i + 1}', note: note, caption: caption),
  ];

  static List<GvChapter> _chapters(List<(String, String)> pages) => [
    for (final (i, (title, line)) in pages.indexed)
      GvChapter(
        title: title,
        line: line,
        photoIds: [for (var p = 1; p <= 3; p++) 'chapter-${i + 1}-$p'],
      ),
  ];

  /// `heart-1`…`heart-[count]`.
  static List<String> heartIds(int count) => [
    for (var i = 1; i <= count; i++) 'heart-$i',
  ];

  static GvChapter _carousel(String title, String line) => GvChapter(
    title: title,
    line: line,
    photoIds: [for (var p = 1; p <= 12; p++) 'carousel-$p'],
  );
}
