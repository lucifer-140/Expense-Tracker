import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../utils/date_utils.dart';

class EditExpensePage extends StatefulWidget {
  final Expense expense;

  const EditExpensePage({super.key, required this.expense});

  @override
  _EditExpensePageState createState() => _EditExpensePageState();
}



class _EditExpensePageState extends State<EditExpensePage> {
  late Box<Expense> expenseBox;
  late TextEditingController amountController;
  late TextEditingController categoryController;
  late TextEditingController noteController;  // Use 'note' instead of 'notes'

  @override
  void initState() {
    super.initState();
    expenseBox = Hive.box<Expense>('expenses');
    amountController = TextEditingController(text: widget.expense.amount.toString());
    categoryController = TextEditingController(text: widget.expense.category);
    noteController = TextEditingController(text: widget.expense.note);  // Use 'note'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Expense"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: noteController,  // Use 'note'
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _updateExpense();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateExpense() {
    final updatedExpense = widget.expense.copyWith(
      amount: double.parse(amountController.text),
      category: categoryController.text,
      note: noteController.text,  // Use 'note'
    );

    expenseBox.put(widget.expense.key, updatedExpense); // Save the updated expense
    Navigator.pop(context); // Go back to the previous page
  }
}
