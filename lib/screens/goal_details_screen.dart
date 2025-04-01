import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../utils/financial_goal_model.dart';
import '../services/financial_goals_service.dart';
import 'add_progress_screen.dart';
import 'add_edit_goal_screen.dart';

class GoalDetailsScreen extends StatefulWidget {
  final FinancialGoal goal;

  const GoalDetailsScreen({super.key, required this.goal});

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  late FinancialGoal _goal;
  final FinancialGoalsService _goalsService = FinancialGoalsService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  Future<void> _refreshGoal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final goals = await _goalsService.getUserGoals();
      for (final goal in goals) {
        if (goal.id == _goal.id) {
          setState(() {
            _goal = goal;
          });
          break;
        }
      }
    } catch (e) {
      print('Error refreshing goal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing goal: $e')),
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

  Future<void> _navigateToAddProgress() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddProgressScreen(goal: _goal),
      ),
    );

    if (result == true) {
      await _refreshGoal();
    }
  }

  Future<void> _navigateToEditGoal() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditGoalScreen(goal: _goal),
      ),
    );

    if (result == true) {
      await _refreshGoal();
    }
  }

  Future<void> _deleteGoal() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: const Text(
          'Delete Goal',
          style: TextStyle(color: AppColors.lightest),
        ),
        content: Text(
          'Are you sure you want to delete "${_goal.name}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.lightest),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.lightGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _goalsService.deleteGoal(_goal.id);
        if (mounted) {
          Navigator.of(context).pop(true); // Return to goals list
        }
      } catch (e) {
        print('Error deleting goal: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting goal: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final monthlyContribution = _goal.monthlyContributionNeeded;
    final isCompleted = _goal.isCompleted;
    final daysRemaining = _goal.daysRemaining;
    
    // Sort progress history by date (newest first)
    final sortedHistory = List<GoalProgress>.from(_goal.progressHistory)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _goal.name,
          style: const TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditGoal,
            tooltip: 'Edit Goal',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteGoal,
            tooltip: 'Delete Goal',
          ),
        ],
      ),
      floatingActionButton: !isCompleted
          ? FloatingActionButton(
              onPressed: _navigateToAddProgress,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshGoal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Overview Card
                    Card(
                      margin: const EdgeInsets.all(16),
                      color: AppColors.darkGrey,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _goal.name,
                                        style: const TextStyle(
                                          color: AppColors.lightest,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _goal.category,
                                        style: TextStyle(
                                          color: AppColors.lightGrey,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          backgroundColor: AppColors.darkest.withOpacity(0.3),
                                          // Add a little rounded background
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.green.withOpacity(0.2)
                                        : AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    isCompleted ? 'Completed' : 'In Progress',
                                    style: TextStyle(
                                      color: isCompleted
                                          ? Colors.green
                                          : AppColors.mediumGrey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Progress Bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_goal.progressPercentage.toStringAsFixed(1)}% Complete',
                                      style: const TextStyle(
                                        color: AppColors.lightest,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${currencyFormat.format(_goal.currentAmount)} / ${currencyFormat.format(_goal.targetAmount)}',
                                      style: const TextStyle(
                                        color: AppColors.lightest,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (_goal.currentAmount / _goal.targetAmount).clamp(0.0, 1.0),
                                    backgroundColor: AppColors.darkest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isCompleted
                                          ? Colors.green
                                          : _goal.progressPercentage > 75
                                              ? Colors.orange
                                              : AppColors.lightest,
                                    ),
                                    minHeight: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Goal Details
                            if (!isCompleted) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDetailItem(
                                      'Amount Needed',
                                      currencyFormat.format(_goal.targetAmount - _goal.currentAmount),
                                      Colors.orange,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDetailItem(
                                      'Days Remaining',
                                      daysRemaining > 0 ? daysRemaining.toString() : '0',
                                      Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Monthly savings needed
                              if (monthlyContribution > 0)
                                _buildDetailItem(
                                  'Monthly Contribution Needed',
                                  currencyFormat.format(monthlyContribution),
                                  AppColors.primary,
                                ),
                            ],
                            if (_goal.description.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(color: AppColors.mediumGrey),
                              const SizedBox(height: 8),
                              Text(
                                _goal.description,
                                style: const TextStyle(
                                  color: AppColors.lightGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Progress History Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Progress History',
                        style: TextStyle(
                          color: AppColors.lightest,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    if (sortedHistory.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No progress history yet.',
                            style: TextStyle(color: AppColors.lightGrey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedHistory.length,
                        itemBuilder: (context, index) {
                          final progress = sortedHistory[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            color: AppColors.darkGrey,
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.trending_up,
                                  color: AppColors.lightest,
                                ),
                              ),
                              title: Text(
                                '${progress.amount > 0 ? '+' : ''}${currencyFormat.format(progress.amount)}',
                                style: const TextStyle(
                                  color: AppColors.lightest,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(progress.date),
                                    style: const TextStyle(color: AppColors.lightGrey),
                                  ),
                                  if (progress.note.isNotEmpty)
                                    Text(
                                      progress.note,
                                      style: const TextStyle(color: AppColors.lightGrey),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                    const SizedBox(height: 80), // Extra space at bottom for FAB
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailItem(String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          color: iconColor,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.lightest,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 