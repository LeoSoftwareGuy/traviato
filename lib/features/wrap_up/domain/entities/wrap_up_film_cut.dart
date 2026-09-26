/// How much of the Wrap-Up Film a trip's photo library can fill without
/// ever repeating a photo (#151), chosen by `generate_wrap_up`:
/// [highlight] (≤11 photos) is card flips only with no Flurry, [compact]
/// (12–23) caps collages at torn4 with at most one Flurry, and [full]
/// (24+) runs the whole collage ladder with up to two Flurries.
///
/// The player never derives this itself; it performs whatever plan the
/// generator resolved. `null` on the entity means a pre-#151 wrap-up.
enum WrapUpFilmCut { highlight, compact, full }
