import 'package:equatable/equatable.dart';

/// What the Golden Vows film shows of one memory (#346, spec §6). Phase 2
/// covers the invitation and the packing card; later phases add the
/// album's pages.
class GoldenVowsStory extends Equatable {
  const GoldenVowsStory({
    required this.names,
    required this.date,
    this.occasionLine,
    this.place,
    this.packed = const [],
    this.packedTotal,
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

  static const maxPacked = 5;

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
  );
}
