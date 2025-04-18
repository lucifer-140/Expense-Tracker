import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/income_model.dart';
import '../utils/date_utils.dart';

class SetMonthlyIncomePage extends StatefulWidget {
  const SetMonthlyIncomePage({super.key});

  @override
  State<SetMonthlyIncomePage> createState() => _SetMonthlyIncomePageState();
}

class _SetMonthlyIncomePageState extends State<SetMonthlyIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  late Box<Income> _incomeBox;

  @override
  void initState() {
    super.initState();
    _incomeBox = Hive.box<Income>('income');
    _loadCurrentIncome();
  }

  Future<void> _loadCurrentIncome() async {
    final now = DateTime.now();
    final monthKey = getMonthKey(now);
    final currentIncome = _incomeBox.get(monthKey);
    
    if (currentIncome != null && mounted) {
      _incomeController.text = currentIncome.monthlyIncome.toStringAsFixed(0);
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    final income = double.tryParse(_incomeController.text);
    final now = DateTime.now();
    final monthKey = getMonthKey(now);

    await _incomeBox.put(
      monthKey,
      Income(monthlyIncome: income!, month: now),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Monthly Income'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Current month display
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Current Month',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.textTheme.titleSmall?.color?.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Income input field
              TextFormField(
                controller: _incomeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monthly Income',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Save button
              ElevatedButton(
                onPressed: _saveIncome,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Income',
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