import 'package:equatable/equatable.dart';

/// The badge-unlocked card — the most recently earned achievement within the
/// trip's window, chosen server-side by `generate_wrap_up` (#93). `null` on
/// [WrapUpEntity.achievementMoment] means no achievement was earned during
/// this trip; the client hides the block rather than showing an empty one.
class WrapUpAchievementMoment extends Equatable {
  const WrapUpAchievementMoment({
    required this.code,
    required this.title,
    required this.description,
  });

  final String code;
  final String title;
  final String description;

  @override
  List<Object?> get props => [code, title, description];
}
