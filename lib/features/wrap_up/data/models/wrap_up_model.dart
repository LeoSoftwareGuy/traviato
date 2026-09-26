import '../../domain/entities/wrap_up_collage_layout.dart';
import '../../domain/entities/wrap_up_cover_photo.dart';
import '../../domain/entities/wrap_up_dates.dart';
import '../../domain/entities/wrap_up_entity.dart';
import '../../domain/entities/wrap_up_film_cut.dart';
import '../../domain/entities/wrap_up_flurry_leftovers.dart';
import '../../domain/entities/wrap_up_footnote.dart';
import '../../domain/entities/wrap_up_invitation.dart';
import '../../domain/entities/wrap_up_keepsake.dart';
import '../../domain/entities/wrap_up_moment.dart';
import '../../domain/entities/wrap_up_photo_ref.dart';
import '../../domain/entities/wrap_up_unlock.dart';

/// Hand-parsed rather than `@JsonSerializable`-generated: `content` is
/// function-generated JSONB (#125's data contract), and every field must
/// degrade to a neutral default on a shape mismatch instead of throwing, so
/// the film can still play (possibly with a gap) instead of crashing (#126
/// AC).
class WrapUpModel extends WrapUpEntity {
  const WrapUpModel({
    super.cut,
    required super.dates,
    required super.coverPhoto,
    required super.invitation,
    super.bridges,
    super.moments,
    super.flurryLeftovers,
    required super.footnote,
    super.unlock,
    required super.keepsake,
    required super.generatedAt,
    super.publishedAt,
  });

  /// [row] is a `wrap_ups` row shape: `content`, `generated_at`,
  /// `published_at`.
  factory WrapUpModel.fromRow(Map<String, dynamic> row) {
    final content = row['content'];
    final contentMap = content is Map
        ? content.cast<String, dynamic>()
        : const <String, dynamic>{};

    return WrapUpModel(
      cut: _parseEnum(WrapUpFilmCut.values, contentMap['cut']),
      dates: _parseDates(contentMap['dates']),
      coverPhoto: _parseCoverPhoto(contentMap['cover_photo']),
      invitation: _parseInvitation(contentMap['invitation']),
      bridges: _parseBridges(contentMap['bridges']),
      moments: _parseMoments(contentMap['moments']),
      flurryLeftovers: _parseFlurryLeftovers(contentMap['flurry_leftovers']),
      footnote: _parseFootnote(contentMap['footnote']),
      unlock: _parseUnlock(contentMap['unlock']),
      keepsake: _parseKeepsake(contentMap['keepsake']),
      generatedAt: _parseDateTime(row['generated_at']) ?? DateTime.now(),
      publishedAt: _parseDateTime(row['published_at']),
    );
  }
}

WrapUpDates _parseDates(dynamic json) {
  if (json is! Map) return const WrapUpDates(formatted: '');
  return WrapUpDates(
    startDate: _parseDate(json['start_date']),
    endDate: _parseDate(json['end_date']),
    formatted: json['formatted'] is String ? json['formatted'] as String : '',
  );
}

WrapUpCoverPhoto _parseCoverPhoto(dynamic json) {
  if (json is! Map) return const WrapUpCoverPhoto();
  final path = json['image_path'];
  return WrapUpCoverPhoto(imagePath: path is String ? path : null);
}

WrapUpInvitation _parseInvitation(dynamic json) {
  if (json is! Map) return const WrapUpInvitation(line1: '', line2: '');
  final line1 = json['line1'];
  final line2 = json['line2'];
  return WrapUpInvitation(
    line1: line1 is String ? line1 : '',
    line2: line2 is String ? line2 : '',
  );
}

/// Always returns exactly 3 entries — an empty string for any slot that
/// isn't a valid string, rather than dropping the whole block, so the
/// Bridge scenes stay on their fixed timing regardless.
List<String> _parseBridges(dynamic json) {
  if (json is! List) return const ['', '', ''];
  return List.generate(
    3,
    (i) => i < json.length && json[i] is String ? json[i] as String : '',
  );
}

List<WrapUpMoment> _parseMoments(dynamic json) {
  if (json is! List) return const [];
  final moments = <WrapUpMoment>[];
  for (final raw in json) {
    if (raw is! Map) continue;
    final photoId = raw['photo_id'];
    if (photoId is! String) continue;
    moments.add(
      WrapUpMoment(
        photoId: photoId,
        dayDate: _parseDate(raw['day_date']),
        note: raw['note'] is String ? raw['note'] as String : null,
        badge: raw['badge'] is String ? raw['badge'] as String : null,
        layout: _parseEnum(WrapUpCollageLayout.values, raw['layout']),
        collageExtras: _parsePhotoRefs(raw['collage_extras']),
      ),
    );
  }
  return moments;
}

WrapUpPhotoRef? _parsePhotoRef(dynamic json) {
  if (json is! Map) return null;
  final photoId = json['photo_id'];
  if (photoId is! String) return null;
  return WrapUpPhotoRef(
    photoId: photoId,
    dayDate: _parseDate(json['day_date']),
  );
}

List<WrapUpPhotoRef> _parsePhotoRefs(dynamic json) {
  if (json is! List) return const [];
  final refs = <WrapUpPhotoRef>[];
  for (final raw in json) {
    final ref = _parsePhotoRef(raw);
    if (ref != null) refs.add(ref);
  }
  return refs;
}

WrapUpFlurryLeftovers _parseFlurryLeftovers(dynamic json) {
  if (json is! Map) return const WrapUpFlurryLeftovers();
  final label = json['total_remaining_label'];
  return WrapUpFlurryLeftovers(
    photos: _parsePhotoRefs(json['photos']),
    flurry1: _parsePhotoRefs(json['flurry1']),
    flurry2: _parsePhotoRefs(json['flurry2']),
    totalRemainingLabel: label is String ? label : null,
  );
}

WrapUpFootnote _parseFootnote(dynamic json) {
  if (json is! Map) {
    return const WrapUpFootnote(
      photoCount: 0,
      bonusCompletedCount: 0,
      stars: 0,
    );
  }
  return WrapUpFootnote(
    photoCount: _parseInt(json['photo_count']),
    bonusCompletedCount: _parseInt(json['bonus_completed_count']),
    stars: _parseInt(json['stars']),
  );
}

WrapUpUnlock? _parseUnlock(dynamic json) {
  if (json is! Map) return null;
  final code = json['code'];
  final name = json['name'];
  final reason = json['reason'];
  if (code is! String || name is! String || reason is! String) return null;
  return WrapUpUnlock(code: code, name: name, reason: reason);
}

WrapUpKeepsake _parseKeepsake(dynamic json) {
  if (json is! Map) {
    return const WrapUpKeepsake(
      titleLine1: '',
      titleLine2: '',
      closingQuote: '',
    );
  }
  final line1 = json['title_line1'];
  final line2 = json['title_line2'];
  final quote = json['closing_quote'];
  return WrapUpKeepsake(
    titleLine1: line1 is String ? line1 : '',
    titleLine2: line2 is String ? line2 : '',
    closingQuote: quote is String ? quote : '',
  );
}

/// An unknown or missing value parses to `null` — for `cut` that means
/// legacy playback, for a moment's `layout` a plain card flip.
T? _parseEnum<T extends Enum>(List<T> values, dynamic value) {
  if (value is! String) return null;
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  return null;
}

int _parseInt(dynamic value) {
  if (value is num) return value.toInt();
  return 0;
}

DateTime? _parseDateTime(dynamic value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

DateTime? _parseDate(dynamic value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}
