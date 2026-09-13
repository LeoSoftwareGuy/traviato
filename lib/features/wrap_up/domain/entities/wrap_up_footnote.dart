import 'package:equatable/equatable.dart';

/// Plain counts for the Footnote frame (#125 `footnote`) — deliberately no
/// distance/steps, so a trip that never left one room still has all three.
class WrapUpFootnote extends Equatable {
  const WrapUpFootnote({
    required this.photoCount,
    required this.bonusCompletedCount,
    required this.stars,
  });

  final int photoCount;
  final int bonusCompletedCount;
  final int stars;

  @override
  List<Object?> get props => [photoCount, bonusCompletedCount, stars];
}
