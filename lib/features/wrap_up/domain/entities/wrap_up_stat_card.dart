import 'package:equatable/equatable.dart';

/// One stat card in chapter three (days, photos, stars…), rendered with an
/// animating fill bar. `value` is pre-formatted text, not a number, since
/// the generator may include a unit (e.g. "312").
class WrapUpStatCard extends Equatable {
  const WrapUpStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  List<Object?> get props => [label, value];
}
