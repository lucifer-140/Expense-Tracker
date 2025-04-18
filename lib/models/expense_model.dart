import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String note;  // Used 'note' instead of 'notes'

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String category;

  Expense({
    required this.id,
    required this.amount,
    required this.note,  // Correct field name 'note'
    required this.date,
    required this.category,
  });

  // Add the copyWith method to allow easy updating
  Expense copyWith({
    String? id,
    double? amount,
    String? note,  // Use 'note' instead of 'notes'
    DateTime? date,
    String? category,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      note: note ?? this.note,  // Update the 'note' field
      date: date ?? this.date,
      category: category ?? this.category,
    );
  }
}
