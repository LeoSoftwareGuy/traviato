import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.tripId,
    required super.title,
    required super.amount,
    required super.category,
    required super.spentOn,
    required super.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    id: json['id'] as String,
    tripId: json['trip_id'] as String,
    title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: ExpenseCategory.fromDbValue(json['category'] as String),
    spentOn: DateTime.parse(json['spent_on'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
