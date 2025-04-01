import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../utils/financial_goal_model.dart';
import '../services/financial_goals_service.dart';
import 'add_edit_goal_screen.dart';
import 'goal_details_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final FinancialGoalsService _goalsService = FinancialGoalsService();
  List<FinancialGoal> _goals = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadGoals();
  }
  
  Future<void> _loadGoals() async {
    try {
      final goals = await _goalsService.getUserGoals();
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading goals: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading goals: $e')),
        );
      }
    }
  }
  
  Future<void> _navigateToAddGoal() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditGoalScreen(),
      ),
    );
    
    if (result == true) {
      await _loadGoals();
    }
  }
  
  Future<void> _navigateToGoalDetails(FinancialGoal goal) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoalDetailsScreen(goal: goal),
      ),
    );
    
    if (result == true) {
      await _loadGoals();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Financial Goals',
          style: TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddGoal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGoals,
              child: _goals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _goals.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        return _buildGoalCard(goal);
                      },
                    ),
            ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings,
            size: 64,
            color: AppColors.mediumGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Financial Goals Yet',
            style: TextStyle(
              color: AppColors.lightest,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create your first goal',
            style: TextStyle(
              color: AppColors.lightGrey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddGoal,
            icon: const Icon(Icons.add),
            label: const Text('Add New Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.mediumGrey,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGoalCard(FinancialGoal goal) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final isCompleted = goal.isCompleted;
    final daysLeft = goal.daysRemaining;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.darkGrey,
      elevation: 4,
      child: InkWell(
        onTap: () => _navigateToGoalDetails(goal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Category Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(goal.category).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getCategoryIcon(goal.category),
                            color: _getCategoryColor(goal.category),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.name,
                                style: const TextStyle(
                                  color: AppColors.lightest,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                goal.category,
                                style: const TextStyle(
                                  color: AppColors.lightGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.2)
                          : daysLeft < 30
                              ? Colors.red.withOpacity(0.2)
                              : AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCompleted
                          ? 'Completed'
                          : daysLeft < 30
                              ? '$daysLeft days left'
                              : '${(daysLeft / 30).round()} months left',
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.green
                            : daysLeft < 30
                                ? Colors.red
                                : AppColors.mediumGrey,
                        fontSize: 12,
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
                        '${goal.progressPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.lightest,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${currencyFormat.format(goal.currentAmount)} / ${currencyFormat.format(goal.targetAmount)}',
                        style: const TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0),
                      backgroundColor: AppColors.darkest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green : AppColors.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Savings':
        return Icons.savings;
      case 'Retirement':
        return Icons.beach_access;
      case 'Emergency Fund':
        return Icons.health_and_safety;
      case 'Home':
        return Icons.home;
      case 'Education':
        return Icons.school;
      case 'Travel':
        return Icons.flight;
      case 'Car':
        return Icons.directions_car;
      default:
        return Icons.attach_money;
    }
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Savings':
        return Colors.blue;
      case 'Retirement':
        return Colors.purple;
      case 'Emergency Fund':
        return Colors.red;
      case 'Home':
        return Colors.green;
      case 'Education':
        return Colors.orange;
      case 'Travel':
        return Colors.teal;
      case 'Car':
        return Colors.indigo;
      default:
        return AppColors.primary;
    }
  }
} 