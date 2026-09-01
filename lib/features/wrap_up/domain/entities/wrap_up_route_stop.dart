import 'package:equatable/equatable.dart';

/// One stop in the route chapter's illustrated path — a place and when the
/// trip was there. `lat`/`lng` are carried through but unused by the
/// stylized (non-geographic) route panel; see docs/design/README.md § 12.
class WrapUpRouteStop extends Equatable {
  const WrapUpRouteStop({
    required this.placeText,
    required this.dayDate,
    this.lat,
    this.lng,
  });

  final String placeText;
  final DateTime dayDate;
  final double? lat;
  final double? lng;

  @override
  List<Object?> get props => [placeText, dayDate, lat, lng];
}
