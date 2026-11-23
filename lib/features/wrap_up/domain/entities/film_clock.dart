import 'package:equatable/equatable.dart';

/// The clock a film's times play on (#461, `content.local_times`): each
/// photo's and note's UTC offset where it was taken or written. A film
/// without it — kept before #461 — plays on the phone's clock until it is
/// rebuilt.
class FilmClock extends Equatable {
  const FilmClock({
    this.photoOffsets = const {},
    this.noteOffsets = const {},
    this.zone,
    this.zoneSource,
    this.zoneDetail,
    this.photoSources = const {},
    this.noteSources = const {},
  });

  /// The phone's clock: films kept before #461.
  static const phone = FilmClock();

  /// Minutes from UTC by photo id and by note id.
  final Map<String, int> photoOffsets;
  final Map<String, int> noteOffsets;

  /// The memory's IANA zone, when found.
  final String? zone;

  /// For the Plan inspector: where [zone] came from (stored, gps, country,
  /// destination, unresolved) and what decided it.
  final String? zoneSource;
  final String? zoneDetail;

  /// How many photos and notes took each offset source (exif, device,
  /// gps, nearby, place, phone).
  final Map<String, int> photoSources;
  final Map<String, int> noteSources;

  /// Whether the film carries place clocks at all (#461); false for a film
  /// kept before, which plays on the phone's clock until rebuilt.
  bool get isPlaceClock => zoneSource != null || photoOffsets.isNotEmpty;

  /// [instant] as the wall-clock time of where [photoId] was taken: a
  /// [DateTime] whose fields read that clock. The phone's clock without
  /// an offset for it.
  DateTime photo(String photoId, DateTime instant) =>
      _at(instant, photoOffsets[photoId]);

  /// [instant] on the clock of where [noteId] was written.
  DateTime note(String? noteId, DateTime instant) =>
      _at(instant, noteId == null ? null : noteOffsets[noteId]);

  static DateTime _at(DateTime instant, int? offset) => offset == null
      ? instant.toLocal()
      : instant.toUtc().add(Duration(minutes: offset));

  /// 'HH:MM' of a wall-clock time from [photo] or [note].
  static String hhmm(DateTime wallClock) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(wallClock.hour)}:${two(wallClock.minute)}';
  }

  @override
  List<Object?> get props => [
    photoOffsets,
    noteOffsets,
    zone,
    zoneSource,
    zoneDetail,
    photoSources,
    noteSources,
  ];
}
