import 'package:equatable/equatable.dart';

/// What a share link's 1200×630 link-preview image says (#309, design 2a):
/// the memory's title and the `HIGHLANDS · 12–16 AUG 2026` eyebrow, already
/// in the UI language and uppercased.
class OgCardContent extends Equatable {
  const OgCardContent({required this.title, required this.eyebrow});

  final String title;
  final String eyebrow;

  @override
  List<Object?> get props => [title, eyebrow];
}
