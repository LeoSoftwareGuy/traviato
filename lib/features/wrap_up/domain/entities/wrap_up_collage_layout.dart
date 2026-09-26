/// A collage moment's layout (docs/design/WRAP_UP_FILM_COLLAGE_SPEC.md §3).
/// Tile 0 is always the moment's own photo.
enum WrapUpCollageLayout {
  stack3(3),
  torn4(4),
  tilt6(6),
  torn6(6);

  const WrapUpCollageLayout(this.tileCount);

  final int tileCount;
}
