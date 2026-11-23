import 'package:equatable/equatable.dart';

import 'golden_vows_scene_spec.dart' show GvPageKind;

/// One photo-with-note page (spec §5.3): the photo, the note on its taped
/// card and the caption under it ("THE VOWS · 15:10"), each optional.
class GvHero extends Equatable {
  const GvHero({required this.photoId, this.note, this.caption, this.order});

  final String photoId;
  final String? note;
  final String? caption;

  /// Its place in the album's play order (#460); null = after the one
  /// before it, before the chapters.
  final int? order;

  @override
  List<Object?> get props => [photoId, note, caption, order];
}

/// A titled album page of up to 3 prints ("Getting ready" · "CHAPTER ONE
/// · MORNING"); the carousel page is one too, with up to 12. A chapter of
/// 4–6 prints is two of these (#460), the second [isSecondPage].
class GvChapter extends Equatable {
  const GvChapter({
    required this.title,
    required this.photoIds,
    this.line,
    this.layout,
    this.order,
    this.isSecondPage = false,
    this.isLineANote = false,
  });

  final String title;

  /// The eyebrow ("Chapter one · Morning"), or the user's own line
  /// ([isLineANote], #460).
  final String? line;

  /// [line] is the user's words: set as a note, read in full.
  final bool isLineANote;
  final List<String> photoIds;

  /// Where its prints go (spec §5.3); null cycles A, B, C by chapter.
  final GvChapterLayout? layout;

  /// Its place in the album's play order (#460); null = after the main
  /// pages, in turn.
  final int? order;

  /// A chapter's second page of prints (#460): GvFit's first to go.
  final bool isSecondPage;

  @override
  List<Object?> get props => [
    title,
    line,
    photoIds,
    layout,
    order,
    isSecondPage,
    isLineANote,
  ];
}

/// The chapter pages' print arrangements (`GvChapterLayouts`): A — a wide
/// print over two; B — a tall print beside two; C — two over a wide one;
/// B2 (#460) — a tall print beside one, for a page of 2.
enum GvChapterLayout { a, b, c, b2 }

/// One page of the album in play order: which hero or chapter page.
typedef GvPageRef = ({GvPageKind kind, int index});

/// What the Golden Vows film shows of one memory (#346, spec §6).
class GoldenVowsStory extends Equatable {
  const GoldenVowsStory({
    required this.names,
    required this.date,
    this.occasionLine,
    this.place,
    this.packed = const [],
    this.packedCodes = const [],
    this.packedChecked,
    this.packedTotal,
    this.isPackedFromQuests = false,
    this.heroes = const [],
    this.chapters = const [],
    this.carousel,
    this.heartPhotoIds = const [],
    this.endLine,
    this.dayCount = 1,
    this.moments,
    this.targetSeconds,
    this.chapterDwellScale = 1,
  });

  /// How long the film should play (#434, from its photos); the timeline
  /// fits its scenes to it. Null = the reference pacing.
  final double? targetSeconds;

  /// How long chapter pages lie open, × their dwell (#458: GvFit's last
  /// step, never below a title's reading time); 1 = the timeline's.
  final double chapterDwellScale;

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

  /// The seeded checklist code of each [packed] item, by position (null or
  /// missing = the user's own words): the film shows a seeded item in its
  /// language.
  final List<String?> packedCodes;

  /// "X OF Y": how many were packed (null = the items shown) and how many
  /// there were to pack (null = all of [packed]).
  final int? packedChecked;
  final int? packedTotal;

  /// The items are the memory's planned quests (nothing was checked off):
  /// the card reads "What we planned", with no count.
  final bool isPackedFromQuests;

  /// One photo-with-note page each.
  final List<GvHero> heroes;

  /// One page of up to 3 prints each, layouts cycling A, B, C.
  final List<GvChapter> chapters;

  /// The main and chapter pages in the order they play (#460): by their
  /// [GvHero.order] / [GvChapter.order] when every page has one, else
  /// every main page, then every chapter page.
  List<GvPageRef> get pageOrder {
    final refs = <GvPageRef>[
      for (var i = 0; i < heroes.length; i++) (kind: GvPageKind.hero, index: i),
      for (var i = 0; i < chapters.length; i++)
        (kind: GvPageKind.chapter, index: i),
    ];
    int? orderOf(GvPageRef r) => r.kind == GvPageKind.hero
        ? heroes[r.index].order
        : chapters[r.index].order;
    if (refs.any((r) => orderOf(r) == null)) return refs;
    return refs..sort((a, b) => orderOf(a)!.compareTo(orderOf(b)!));
  }

  /// Two rows of prints sliding past; null or no photos → no page.
  final GvChapter? carousel;

  /// Every photo of the memory (spec §6 `allPhotos`): they form the heart,
  /// up to [maxHeartPhotos] of them. None → no heart.
  final List<String> heartPhotoIds;

  /// The line under the balloon; null → "Forever starts here".
  final String? endLine;

  /// The heart page's line: "{N} MOMENTS · ONE DAY" — every photo of the
  /// memory ([moments]), else the heart's.
  int get momentCount => moments ?? heartPhotoIds.length;
  final int? moments;
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

  /// This story with the pages GvFit keeps (#458).
  GoldenVowsStory fitted({
    List<GvHero>? heroes,
    List<GvChapter>? chapters,
    bool dropCarousel = false,
    bool dropPacking = false,
    double? chapterDwellScale,
  }) => GoldenVowsStory(
    names: names,
    date: date,
    occasionLine: occasionLine,
    place: place,
    packed: dropPacking ? const [] : packed,
    packedCodes: dropPacking ? const [] : packedCodes,
    packedChecked: dropPacking ? null : packedChecked,
    packedTotal: dropPacking ? null : packedTotal,
    isPackedFromQuests: !dropPacking && isPackedFromQuests,
    heroes: heroes ?? this.heroes,
    chapters: chapters ?? this.chapters,
    carousel: dropCarousel ? null : carousel,
    heartPhotoIds: heartPhotoIds,
    endLine: endLine,
    dayCount: dayCount,
    moments: moments,
    targetSeconds: targetSeconds,
    chapterDwellScale: chapterDwellScale ?? this.chapterDwellScale,
  );

  bool get hasPackingCard => packed.isNotEmpty;

  @override
  List<Object?> get props => [
    occasionLine,
    names,
    date,
    place,
    packed,
    packedCodes,
    packedChecked,
    packedTotal,
    isPackedFromQuests,
    heroes,
    chapters,
    carousel,
    heartPhotoIds,
    endLine,
    dayCount,
    moments,
    targetSeconds,
    chapterDwellScale,
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
