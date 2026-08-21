import 'package:equatable/equatable.dart';

/// One row of the "Your spending" list — one trip's spend summary, merging
/// `trip_card_view` (name/place/duration/total) with `expense_summary_view`
/// (item count) for that trip.
class ExpenseSummaryEntity extends Equatable {
  const ExpenseSummaryEntity({
    required this.tripId,
    required this.tripName,
    this.place,
    this.durationDays,
    required this.totalAmount,
    required this.itemCount,
  });

  final String tripId;
  final String tripName;
  final String? place;
  final int? durationDays;
  final double totalAmount;
  final int itemCount;

  /// Total spent per day of the trip — null when the trip has no duration
  /// (undated memory) or no expenses yet.
  double? get perDay =>
      (durationDays == null || durationDays == 0 || totalAmount == 0)
      ? null
      : totalAmount / durationDays!;

  @override
  List<Object?> get props => [
    tripId,
    tripName,
    place,
    durationDays,
    totalAmount,
    itemCount,
  ];
}
