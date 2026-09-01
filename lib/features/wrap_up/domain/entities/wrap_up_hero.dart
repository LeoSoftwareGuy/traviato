import 'package:equatable/equatable.dart';

/// The wrap-up's opening block: ken-burns cover + staggered title reveal
/// (docs/design/README.md § 12).
class WrapUpHero extends Equatable {
  const WrapUpHero({required this.title, this.subtitle, this.coverPhotoId});

  final String title;
  final String? subtitle;

  /// Resolved to an actual image via the trip's photos — `null` falls back
  /// to the trip's cover image.
  final String? coverPhotoId;

  @override
  List<Object?> get props => [title, subtitle, coverPhotoId];
}
