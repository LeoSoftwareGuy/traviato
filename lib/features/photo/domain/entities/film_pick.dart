/// The user's say in whether the Wrap-Up Film uses a photo (#294), stored
/// in `photos.use_in_wrap_up`.
enum FilmPick {
  /// The generator decides (`null`).
  auto,

  /// Gets a main moment before automatic picks do (`true`).
  always,

  /// Never appears anywhere in the film (`false`).
  never;

  static FilmPick fromColumn(Object? value) => switch (value) {
    true => always,
    false => never,
    _ => auto,
  };

  bool? get columnValue => switch (this) {
    auto => null,
    always => true,
    never => false,
  };
}
