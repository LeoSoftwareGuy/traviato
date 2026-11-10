import '../../../domain/entities/wrap_up_collage_layout.dart';
import '../../../domain/entities/wrap_up_footnote.dart';
import '../../../domain/entities/wrap_up_invitation.dart';
import '../../../domain/entities/wrap_up_keepsake.dart';
import '../../../domain/entities/wrap_up_moment.dart';
import '../../../domain/entities/wrap_up_photo_ref.dart';
import '../../../domain/entities/wrap_up_unlock.dart';
import 'film_scene_spec.dart';

/// The classic film's scenes (#344): one subtype per scene type, carrying
/// exactly the data its frame needs. Sealed, so the classic canvas handles
/// every one of them.
sealed class ClassicSceneSpec extends FilmSceneSpec {
  const ClassicSceneSpec();
}

/// The opening specks and the memory's dates.
final class DustSceneSpec extends ClassicSceneSpec {
  const DustSceneSpec({required this.datesFormatted});

  final String datesFormatted;

  @override
  List<Object?> get props => [datesFormatted];
}

/// The two-line invitation over the cover.
final class InvitationSceneSpec extends ClassicSceneSpec {
  const InvitationSceneSpec({required this.invitation});

  final WrapUpInvitation invitation;

  @override
  List<Object?> get props => [invitation];
}

/// A text interlude between chapters. [index] picks the look: the second
/// bridge of the template is fully opaque.
final class BridgeSceneSpec extends ClassicSceneSpec {
  const BridgeSceneSpec({required this.index, required this.line});

  final int index;
  final String line;

  @override
  List<Object?> get props => [index, line];
}

/// A card thrown in, flipped, then dropped into the pile. [pileIndex] is
/// its place in the pile (the moment's index in the film).
final class CardFlipSceneSpec extends ClassicSceneSpec {
  const CardFlipSceneSpec({required this.pileIndex, required this.moment});

  final int pileIndex;
  final WrapUpMoment moment;

  @override
  List<Object?> get props => [pileIndex, moment];
}

/// A moment shown as a collage of [layout]'s tiles; never enters the pile.
final class CollageSceneSpec extends ClassicSceneSpec {
  const CollageSceneSpec({required this.moment, required this.layout});

  final WrapUpMoment moment;
  final WrapUpCollageLayout layout;

  @override
  List<Object?> get props => [moment, layout];
}

/// The leftovers dropped onto a table. [round] 1 is the grid, 2 the
/// scattered pile that carries [remainingLabel].
final class FlurrySceneSpec extends ClassicSceneSpec {
  const FlurrySceneSpec({
    required this.round,
    required this.photos,
    this.remainingLabel,
  });

  final int round;
  final List<WrapUpPhotoRef> photos;
  final String? remainingLabel;

  @override
  List<Object?> get props => [round, photos, remainingLabel];
}

/// The stats footnote.
final class FootnoteSceneSpec extends ClassicSceneSpec {
  const FootnoteSceneSpec({required this.footnote});

  final WrapUpFootnote footnote;

  @override
  List<Object?> get props => [footnote];
}

/// The badge earned on this memory.
final class UnlockSceneSpec extends ClassicSceneSpec {
  const UnlockSceneSpec({required this.unlock});

  final WrapUpUnlock unlock;

  @override
  List<Object?> get props => [unlock];
}

/// The closing title and quote.
final class KeepsakeSceneSpec extends ClassicSceneSpec {
  const KeepsakeSceneSpec({required this.keepsake});

  final WrapUpKeepsake keepsake;

  @override
  List<Object?> get props => [keepsake];
}

/// Time that passes with nothing of its own on screen: a pre-#151 film
/// always runs 8 moment slots, even when it has fewer moments.
final class HoldSceneSpec extends ClassicSceneSpec {
  const HoldSceneSpec();

  @override
  List<Object?> get props => const [];
}
