import '../timeline/film_scene_spec.dart';

/// What one scene of the Golden Vows film shows (#346). The album's pages
/// are one scene each, from the moment they lie open until the next page
/// lies open (their dwell, then their turn).
sealed class GoldenVowsSceneSpec extends FilmSceneSpec {
  const GoldenVowsSceneSpec();
}

/// The balloon rises, the occasion, names, date and place (spec §5.1).
final class GvInvitationSpec extends GoldenVowsSceneSpec {
  const GvInvitationSpec();

  @override
  List<Object?> get props => const [];
}

/// "Before the big day": what was packed (spec §5.2).
final class GvPackingCardSpec extends GoldenVowsSceneSpec {
  const GvPackingCardSpec();

  @override
  List<Object?> get props => const [];
}

/// The closed album rises and its cover turns (spec §5.3).
final class GvAlbumOpenSpec extends GoldenVowsSceneSpec {
  const GvAlbumOpenSpec();

  @override
  List<Object?> get props => const [];
}

enum GvPageKind {
  /// One photo with its note card.
  hero,

  /// A titled page of 3 photos.
  chapter,

  /// Two rows of prints sliding past.
  carousel,

  /// Every photo forms a heart, which lifts off as the balloon.
  heart,
}

/// One open album page. [number] counts the album's pages from 1; [index]
/// counts pages of the same [kind] from 0 (which hero, which chapter).
final class GvPageSpec extends GoldenVowsSceneSpec {
  const GvPageSpec({
    required this.kind,
    required this.number,
    required this.index,
  });

  final GvPageKind kind;
  final int number;
  final int index;

  @override
  List<Object?> get props => [kind, number, index];
}

/// The cover swings back and the album leaves (spec §5.5).
final class GvAlbumCloseSpec extends GoldenVowsSceneSpec {
  const GvAlbumCloseSpec();

  @override
  List<Object?> get props => const [];
}

/// The balloon comes down over "Storyni" (spec §5.6).
final class GvEndingSpec extends GoldenVowsSceneSpec {
  const GvEndingSpec();

  @override
  List<Object?> get props => const [];
}
