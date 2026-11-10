import '../timeline/film_scene_spec.dart';
import 'sky_story.dart';

/// The Sky Story film's scenes (#345): which beat is playing. What a page
/// shows lives in `SkyStory`, by chapter index, so the timeline stays a
/// plain, comparable schedule.
sealed class SkySceneSpec extends FilmSceneSpec {
  const SkySceneSpec();
}

/// The big balloon rises out of the sunset, then the title reads under it.
final class SkyOpeningSpec extends SkySceneSpec {
  const SkyOpeningSpec();

  @override
  List<Object?> get props => const [];
}

/// The camera keeps climbing between pages; the balloon drifts across.
/// [index] 0 leads from the title into the first chapter.
final class SkyInterludeSpec extends SkySceneSpec {
  const SkyInterludeSpec({required this.index});

  final int index;

  @override
  List<Object?> get props => [index];
}

/// One chapter page, [index] of [count].
final class SkyChapterSpec extends SkySceneSpec {
  const SkyChapterSpec({required this.index, required this.count});

  final int index;
  final int count;

  bool get isLast => index == count - 1;

  SkyPageLayout get layout => SkyPageLayout.forChapter(index, count);

  @override
  List<Object?> get props => [index, count];
}

/// The sky flattens into night and the photo tiles swirl up.
final class SkyGatherSpec extends SkySceneSpec {
  const SkyGatherSpec();

  @override
  List<Object?> get props => const [];
}

/// The tiles hold as a balloon mosaic, the count and the brand mark.
final class SkyOutroSpec extends SkySceneSpec {
  const SkyOutroSpec();

  @override
  List<Object?> get props => const [];
}
