import '../../../domain/entities/wrap_up_entity.dart';
import '../../../domain/entities/wrap_up_moment.dart';
import 'classic_scene_spec.dart';
import 'film_timeline.dart';

/// The original film template (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md §1)
/// as a [FilmTimeline] (#344), plus the anchors its cross-scene chrome is
/// keyed to.
///
/// Computed per wrap-up rather than fixed: a scene with nothing to show is
/// cut from the schedule entirely and every later scene moves up to fill the
/// gap. Every scene that does play keeps its fixed duration regardless of
/// trip/library size: a 20-photo trip and a 200-photo trip run at the same
/// pace, just different densities. A moment's length depends only on what
/// it shows (#304): a bare card flip is quick, a caption or a collage gets
/// reading time.
class TemplateTimeline {
  const TemplateTimeline._(this.timeline, this.anchors);

  /// The schedule for [wrapUp]'s resolved plan (#151): one slot per moment
  /// that exists, timed by what it shows (#304), a Flurry only when it has
  /// photos, and Bridge2/Bridge3 only when moments follow them (M4 / M7 in
  /// the 8-moment film, M7 / M13 in the 16-moment one). A pre-#151 wrap-up
  /// (`cut == null`) keeps the original shape: 8 moment slots, Flurry1
  /// always, all three bridges.
  ///
  /// [collages] off (docs/design/WRAP_UP_FILM_COLLAGE_SPEC.md §1) shows a
  /// collage moment as a card flip, but keeps its collage timing.
  factory TemplateTimeline.forWrapUp(
    WrapUpEntity wrapUp, {
    bool collages = true,
  }) {
    final isLegacy = wrapUp.cut == null;
    final slots = isLegacy ? 8 : (wrapUp.momentSlots == 16 ? 16 : 8);
    final moments = wrapUp.moments.take(slots).toList();
    final momentSlotCount = isLegacy ? 8 : moments.length;
    final (end1, end2) = groupEndsFor(slots);

    final scenes = <(double, ClassicSceneSpec)>[];
    final anchors = <String, double>{};
    var cursor = 0.0;
    void add(double duration, ClassicSceneSpec spec, [String? anchor]) {
      if (anchor != null) anchors[anchor] = cursor;
      scenes.add((duration, spec));
      cursor += duration;
    }

    void addBridge(int index, double duration) {
      final line = index < wrapUp.bridges.length ? wrapUp.bridges[index] : null;
      add(
        duration,
        line == null
            ? const HoldSceneSpec()
            : BridgeSceneSpec(index: index, line: line),
        index == 0 ? 'bridge1' : null,
      );
    }

    void addMoments(int from, int to) {
      for (var i = from; i < to && i < momentSlotCount; i++) {
        if (i >= moments.length) {
          add(flipMomentDur, const HoldSceneSpec());
          continue;
        }
        final moment = moments[i];
        final layout = isLegacy ? null : moment.layout;
        add(
          momentDurationFor(moment, isCollage: layout != null),
          collages && layout != null
              ? CollageSceneSpec(moment: moment, layout: layout)
              : CardFlipSceneSpec(pileIndex: i, moment: moment),
        );
      }
    }

    final flurry1 = wrapUp.flurry1Photos;
    final flurry2 = wrapUp.flurry2Photos;

    add(dustDur, DustSceneSpec(datesFormatted: wrapUp.dates.formatted));
    add(
      invitationDur,
      InvitationSceneSpec(invitation: wrapUp.invitation),
      'invitation',
    );
    addBridge(0, bridge1Dur);
    addMoments(0, end1);
    if (isLegacy || flurry1.isNotEmpty) {
      add(flurry1Dur, FlurrySceneSpec(round: 1, photos: flurry1));
    }
    if (isLegacy || momentSlotCount > end1) addBridge(1, bridge2Dur);
    addMoments(end1, end2);
    if (flurry2.isNotEmpty) {
      add(
        flurry2Dur,
        FlurrySceneSpec(
          round: 2,
          photos: flurry2,
          remainingLabel: wrapUp.flurryLeftovers.totalRemainingLabel,
        ),
      );
    }
    if (isLegacy || momentSlotCount > end2) addBridge(2, bridge3Dur);
    addMoments(end2, slots);
    add(
      footnoteDur,
      FootnoteSceneSpec(footnote: wrapUp.footnote),
      'footnote',
    );
    final unlock = wrapUp.unlock;
    if (unlock != null) add(unlockDur, UnlockSceneSpec(unlock: unlock));
    add(
      keepsakeDur,
      KeepsakeSceneSpec(keepsake: wrapUp.keepsake),
      'keepsake',
    );

    return TemplateTimeline._(
      FilmTimeline.sequence(scenes),
      TemplateAnchors(
        invitationStart: anchors['invitation']!,
        bridge1Start: anchors['bridge1']!,
        footnoteStart: anchors['footnote']!,
        keepsakeStart: anchors['keepsake']!,
      ),
    );
  }

  final FilmTimeline<ClassicSceneSpec> timeline;
  final TemplateAnchors anchors;

  double get total => timeline.total;

  /// Where the first two moment groups end. Bridge2 and Bridge3 fall
  /// there: 3 / 3 / 2 in the 8-moment film, 6 / 6 / 4 in the 16 (#304).
  static (int, int) groupEndsFor(int momentSlots) =>
      momentSlots == 16 ? (6, 12) : (3, 6);

  /// How long [moment] is on screen (#304): a bare card flip is quick, a
  /// caption or badge needs reading time, a collage's tiles need to land.
  static double momentDurationFor(
    WrapUpMoment moment, {
    required bool isCollage,
  }) {
    if (isCollage) return collageMomentDur;
    if (moment.note != null || moment.badge != null) {
      return captionedMomentDur;
    }
    return flipMomentDur;
  }

  // Fixed durations (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md §1), same for
  // every wrap-up. Bridges run +4.0s over the spec's original 3.4/3.2/4.2,
  // twice-revised after watching real playback: pure-text interludes need
  // real time to read, and (see WrapUpFilmBridge) the fade-out is tied to
  // each bridge's own duration, so extending only the schedule slot without
  // also retuning the fade would have added dead air, not reading time.
  static const double dustDur = 3.2;
  static const double invitationDur = 4.2;
  static const double bridge1Dur = 7.4;
  static const double bridge2Dur = 7.2;
  static const double bridge3Dur = 8.2;

  /// Moment lengths (#304; ~5s each before): a bare card flip, one with a
  /// caption or badge to read, and a collage.
  static const double flipMomentDur = 2.5;
  static const double captionedMomentDur = 3.5;
  static const double collageMomentDur = 4.0;

  static const double flurry1Dur = 6.3;
  static const double flurry2Dur = 7.0;
  static const double footnoteDur = 4.2;
  static const double unlockDur = 4.6;
  static const double keepsakeDur = 6.8;
}

/// The instants the template's cross-scene chrome is keyed to: the cover
/// wash, the dust's fade-out and the card pile (#344). These scenes always
/// play in the template; a new template brings its own chrome.
class TemplateAnchors {
  const TemplateAnchors({
    required this.invitationStart,
    required this.bridge1Start,
    required this.footnoteStart,
    required this.keepsakeStart,
  });

  final double invitationStart;
  final double bridge1Start;
  final double footnoteStart;
  final double keepsakeStart;
}
