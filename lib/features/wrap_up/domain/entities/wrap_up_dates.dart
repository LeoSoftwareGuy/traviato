import 'package:equatable/equatable.dart';

/// The trip's start/end dates for the film's Dust frame (#125/#126) — a
/// display-ready [formatted] string alongside the raw dates.
class WrapUpDates extends Equatable {
  const WrapUpDates({this.startDate, this.endDate, required this.formatted});

  final DateTime? startDate;
  final DateTime? endDate;
  final String formatted;

  @override
  List<Object?> get props => [startDate, endDate, formatted];
}
