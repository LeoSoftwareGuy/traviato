import 'package:equatable/equatable.dart';

import 'wrap_up_route_stop.dart';

/// Chapter one — "The route": an illustrated (not geographic) path panel,
/// stops in order, and a KM/stops stat line. Works the same whether the trip
/// covered five cities or stayed at one lake the whole time.
class WrapUpRouteChapter extends Equatable {
  const WrapUpRouteChapter({
    required this.intro,
    required this.stops,
    this.totalKm,
    required this.stopCount,
  });

  final String intro;
  final List<WrapUpRouteStop> stops;
  final double? totalKm;
  final int stopCount;

  @override
  List<Object?> get props => [intro, stops, totalKm, stopCount];
}
