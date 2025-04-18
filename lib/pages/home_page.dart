import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../utils/date_utils.dart';
import 'add_expense_page.dart';
import 'set_monthly_income_page.dart';
import 'view_expenses_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Box<Expense> expenseBox;
  late Box<Income> incomeBox;

  double monthlyIncome = 0;
  double totalSpent = 0;

  @override
  void initState() {
    super.initState();
    expenseBox = Hive.box<Expense>('expenses');
    incomeBox = Hive.box<Income>('income');
    _loadData();
  }

  void _loadData() {
    final now = DateTime.now();
    final monthKey = getMonthKey(now);

    // Get income
    final income = incomeBox.values.firstWhere(
      (i) => getMonthKey(i.month) == monthKey,
      orElse: () => Income(monthlyIncome: 0, month: now),
    );
    monthlyIncome = income.monthlyIncome;

    // Get expenses for this month
    totalSpent = expenseBox.values
        .where((e) => getMonthKey(e.date) == monthKey)
        .fold(0.0, (sum, e) => sum + e.amount);

    setState(() {});
  }

  Color getSpendingColor(double percentSpent) {
    if (percentSpent < 0.25) return Colors.green;
    if (percentSpent < 0.5) return Colors.lightGreen;
    if (percentSpent < 0.75) return Colors.orange;
    if (percentSpent < 0.9) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    double available = monthlyIncome - totalSpent;
    double percentSpent = (monthlyIncome == 0) ? 0 : (totalSpent / monthlyIncome).clamp(0.0, 1.0);
    final spendingColor = getSpendingColor(percentSpent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Income display
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Monthly Budget',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.textTheme.titleSmall?.color?.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${monthlyIncome.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Progress indicator
            CircularPercentIndicator(
              radius: 120.0,
              lineWidth: 16.0,
              percent: percentSpent,
              animation: true,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${(percentSpent * 100).toStringAsFixed(1)}%",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Spent",
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
              progressColor: spendingColor,
              backgroundColor: colorScheme.surfaceVariant,
              circularStrokeCap: CircularStrokeCap.round,
            ),

            const SizedBox(height: 24),

            // Amount cards
            Row(
              children: [
                Expanded(
                  child: _AmountCard(
                    label: "Available",
                    amount: available,
                    color: spendingColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AmountCard(
                    label: "Spent",
                    amount: totalSpent,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Action buttons
            _ActionButton(
              icon: Icons.add,
              label: "Add Expense",
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpensePage()),
                );
                _loadData();
              },
            ),

            const SizedBox(height: 12),

            _ActionButton(
              icon: Icons.account_balance_wallet,
              label: "Set Monthly Income",
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SetMonthlyIncomePage()),
                );
                _loadData();
              },
            ),

            const SizedBox(height: 12),

            _ActionButton(
              icon: Icons.view_list,
              label: "View Past Expenses",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewExpensesPage(onExpenseUpdated: _loadData),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _confirmReset,
              icon: const Icon(Icons.refresh),
              label: const Text("Reset This Month"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset This Month?"),
        content: const Text("This will delete all expenses and income for the current month only."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reset", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final now = DateTime.now();
      final currentMonthKey = getMonthKey(now);

      // Delete current month's expenses only
      final keysToDelete = expenseBox.keys.where((key) {
        final expense = expenseBox.get(key);
        return getMonthKey(expense?.date ?? now) == currentMonthKey;
      }).toList();
      await expenseBox.deleteAll(keysToDelete);

      // Reset income for current month
      await incomeBox.put(
        currentMonthKey,
        Income(monthlyIncome: 0, month: now),
      );

      _loadData();
    }
  }
}

class _AmountCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.textTheme.titleSmall?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Rp ${amount.toStringAsFixed(0)}",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
