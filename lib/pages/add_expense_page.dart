import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _categoryController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<String> _categorySuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadCategorySuggestions();
  }

  void _loadCategorySuggestions() {
    final expenseBox = Hive.box<Expense>('expenses');
    final allCategories = expenseBox.values.map((e) => e.category).toSet().toList();
    setState(() {
      _categorySuggestions = allCategories.where((c) => c.isNotEmpty).toList();
    });
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    final note = _noteController.text;
    final category = _categoryController.text.trim().isEmpty 
        ? 'General' 
        : _categoryController.text.trim();

    final newExpense = Expense(
      id: UniqueKey().toString(),
      amount: amount,
      note: note,
      date: _selectedDate,
      category: category,
    );

    final expenseBox = Hive.box<Expense>('expenses');
    await expenseBox.add(newExpense);

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter amount';
                  if (double.tryParse(val) == null) return 'Enter valid number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Note field
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Category field with autocomplete
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _categorySuggestions.where((String option) {
                    return option.toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  _categoryController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      hintText: 'Enter or choose category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                onSelected: (String selection) {
                  _categoryController.text = selection;
                },
              ),

              const SizedBox(height: 16),

              // Date picker
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    isToday ? 'Today' : DateFormat('MMMM d, y').format(_selectedDate),
                    style: theme.textTheme.titleMedium,
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.calendar_today, 
                      color: colorScheme.primary),
                    onPressed: _selectDate,
                  ),
                  onTap: _selectDate,
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Expense',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}