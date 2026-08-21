import 'package:equatable/equatable.dart';

import 'expense_category.dart';

/// One expense row for a memory (Figma "expenses" / "add expenses").
class ExpenseEntity extends Equatable {
  const ExpenseEntity({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.category,
    required this.spentOn,
    required this.createdAt,
  });

  final String id;
  final String tripId;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime spentOn;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    tripId,
    title,
    amount,
    category,
    spentOn,
    createdAt,
  ];
}
