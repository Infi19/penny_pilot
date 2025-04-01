import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/financial_goal_model.dart';
import '../services/financial_goals_service.dart';

class AddProgressScreen extends StatefulWidget {
  final FinancialGoal goal;

  const AddProgressScreen({super.key, required this.goal});

  @override
  State<AddProgressScreen> createState() => _AddProgressScreenState();
}

class _AddProgressScreenState extends State<AddProgressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  bool _isLoading = false;
  final FinancialGoalsService _goalsService = FinancialGoalsService();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final amount = double.parse(_amountController.text);
        final note = _noteController.text;

        await _goalsService.addProgressUpdate(
          widget.goal.id, 
          amount, 
          note,
        );

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } catch (e) {
        print('Error saving progress: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving progress: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Add Progress',
          style: TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal Info Card
                    Card(
                      color: AppColors.darkGrey,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.goal.name,
                              style: const TextStyle(
                                color: AppColors.lightest,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current progress: \$${widget.goal.currentAmount.toStringAsFixed(2)} of \$${widget.goal.targetAmount.toStringAsFixed(2)} (${widget.goal.progressPercentage.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                color: AppColors.lightGrey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: widget.goal.currentAmount / widget.goal.targetAmount,
                              backgroundColor: AppColors.mediumGrey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.goal.progressPercentage >= 100
                                    ? Colors.green
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      style: const TextStyle(color: AppColors.lightest),
                      decoration: const InputDecoration(
                        labelText: 'Amount to Add (\$)',
                        labelStyle: TextStyle(color: AppColors.lightGrey),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.mediumGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Note Field
                    TextFormField(
                      controller: _noteController,
                      style: const TextStyle(color: AppColors.lightest),
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        labelStyle: TextStyle(color: AppColors.lightGrey),
                        hintText: 'e.g., Savings from this month',
                        hintStyle: TextStyle(color: AppColors.mediumGrey),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.mediumGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),
                    
                    // Add Progress Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProgress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.darkest,
                        ),
                        child: const Text(
                          'Add Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 