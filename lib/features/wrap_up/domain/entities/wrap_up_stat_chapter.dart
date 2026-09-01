import 'package:equatable/equatable.dart';

import 'wrap_up_stat_card.dart';

/// Chapter three — "By the numbers": a grid of [WrapUpStatCard]s.
class WrapUpStatChapter extends Equatable {
  const WrapUpStatChapter({required this.stats});

  final List<WrapUpStatCard> stats;

  @override
  List<Object?> get props => [stats];
}
