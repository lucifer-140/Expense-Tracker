import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../utils/date_utils.dart';
import 'edit_expense_page.dart';

class ViewExpensesPage extends StatefulWidget {
  final Function? onExpenseUpdated;

  const ViewExpensesPage({super.key, this.onExpenseUpdated});

  @override
  State<ViewExpensesPage> createState() => _ViewExpensesPageState();
}

class _ViewExpensesPageState extends State<ViewExpensesPage> {
  late Box<Expense> _expenseBox;
  String _filterMode = "month"; // "month" or "category"
  final _dateFormat = DateFormat('MMMM yyyy');

  @override
  void initState() {
    super.initState();
    _expenseBox = Hive.box<Expense>('expenses');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groupedExpenses = _filterMode == "month"
        ? _groupExpensesByMonth()
        : _groupExpensesByCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Expenses'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(12),
                isSelected: [_filterMode == "month", _filterMode == "category"],
                onPressed: (index) {
                  setState(() {
                    _filterMode = index == 0 ? "month" : "category";
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('By Month')),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('By Category')),
                ],
                fillColor: colorScheme.primary,
                color: colorScheme.onSurface,
                selectedColor: colorScheme.onPrimary,
                constraints: const BoxConstraints(
                  minHeight: 40,
                  minWidth: 120,
                ),
              ),
            ),
          ),
          Expanded(
            child: groupedExpenses.isEmpty
                ? Center(
                    child: Text(
                      'No expenses found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.textTheme.titleMedium?.color?.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: groupedExpenses.length,
                    itemBuilder: (context, index) {
                      final key = groupedExpenses.keys.elementAt(index);
                      final expenses = groupedExpenses[key]!;
                      final totalAmount = expenses
                          .fold(0.0, (sum, expense) => sum + expense.amount);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  key,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Rp ${totalAmount.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: colorScheme.error),
                            onPressed: () => _confirmDeleteGroup(key, expenses),
                          ),
                          children: expenses
                              .map((expense) => _buildExpenseTile(expense))
                              .toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(Expense expense) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(
        'Rp ${expense.amount.toStringAsFixed(0)}',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(expense.category),
          Text(
            DateFormat('MMM d, y').add_jm().format(expense.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
          if (expense.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                expense.note,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: colorScheme.primary),
            onPressed: () => _editExpense(expense),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: () => _confirmDeleteSingle(expense),
          ),
        ],
      ),
    );
  }

  Future<void> _editExpense(Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditExpensePage(expense: expense),
      ),
    );
    widget.onExpenseUpdated?.call();
    setState(() {});
  }

  Future<void> _confirmDeleteSingle(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text(
            'Delete expense of Rp ${expense.amount.toStringAsFixed(0)} for ${expense.category}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _expenseBox.delete(expense.key);
      widget.onExpenseUpdated?.call();
      setState(() {});
    }
  }

  Future<void> _confirmDeleteGroup(String key, List<Expense> expenses) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete All?'),
        content: Text('Delete all ${expenses.length} expenses in "$key"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final keysToDelete = expenses.map((e) => e.key).toList();
      await _expenseBox.deleteAll(keysToDelete);
      widget.onExpenseUpdated?.call();
      setState(() {});
    }
  }

  Map<String, List<Expense>> _groupExpensesByMonth() {
    final Map<String, List<Expense>> grouped = {};
    for (var e in _expenseBox.values) {
      final key = _dateFormat.format(e.date);
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => b.value.first.date.compareTo(a.value.first.date)),
    );
  }

  Map<String, List<Expense>> _groupExpensesByCategory() {
    final Map<String, List<Expense>> grouped = {};
    for (var e in _expenseBox.values) {
      final key = e.category;
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => b.value.fold(0.0, (sum, e) => sum + e.amount)
            .compareTo(a.value.fold(0.0, (sum, e) => sum + e.amount))),
    );
  }
}