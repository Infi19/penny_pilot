import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../utils/budget_model.dart';
import '../services/budget_service.dart';
import '../services/analytics_service.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BudgetService budgetService = BudgetService();
    final AnalyticsService analyticsService = AnalyticsService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Monthly Budgets'),
        backgroundColor: AppColors.darkest,
        foregroundColor: AppColors.lightest,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context),
        backgroundColor: AppColors.lightest,
        foregroundColor: AppColors.darkest,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<Map<String, double>>(
        stream: analyticsService.getCategoryBreakdown(DateTime.now()),
        builder: (context, spendingSnapshot) {
          final spendingMap = spendingSnapshot.data ?? {};

          return StreamBuilder<List<Budget>>(
            stream: budgetService.getBudgetsStream(),
            builder: (context, budgetSnapshot) {
              if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final budgets = budgetSnapshot.data ?? [];

              if (budgets.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.savings, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No budgets set. Tap + to add.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  final spent = spendingMap[budget.category] ?? 0.0;
                  final progress = (spent / budget.limitAmount).clamp(0.0, 1.0);
                  final isOverBudget = spent > budget.limitAmount;

                  return Dismissible(
                    key: Key(budget.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                       budgetService.deleteBudget(budget.id);
                    },
                    child: Card(
                      color: AppColors.darkGrey,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(budget.category, style: const TextStyle(color: AppColors.lightest, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  '${NumberFormat.compactSimpleCurrency(locale: 'en_IN').format(spent)} / ${NumberFormat.compactSimpleCurrency(locale: 'en_IN').format(budget.limitAmount)}',
                                  style: TextStyle(color: isOverBudget ? Colors.red : AppColors.lightGrey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade800,
                              color: isOverBudget ? Colors.red : (progress > 0.9 ? Colors.orange : Colors.green),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            if (isOverBudget) 
                               Padding(
                                 padding: const EdgeInsets.only(top: 8),
                                 child: Text(
                                   'Over budget by ${NumberFormat.simpleCurrency(locale: 'en_IN').format(spent - budget.limitAmount)}',
                                   style: const TextStyle(color: Colors.red, fontSize: 12),
                                 ),
                               ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddBudgetDialog(),
    );
  }
}

class AddBudgetDialog extends StatefulWidget {
  const AddBudgetDialog({super.key});

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _category = 'Food';
  final BudgetService _budgetService = BudgetService();

  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Travel', 'Rent', 'Education', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Budget Limit'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _category = val!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Limit Amount',
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final amount = double.parse(_amountController.text);
              final budget = Budget(
                id: '', 
                userId: '', 
                category: _category, 
                limitAmount: amount
              );
              await _budgetService.setBudget(budget);
              if (mounted) Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
