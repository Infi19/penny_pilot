import '../utils/expense_model.dart';
import 'expense_service.dart';

class AnalyticsService {
  final ExpenseService _expenseService = ExpenseService();

  /// Get expenses grouped by category for a given month
  Stream<Map<String, double>> getCategoryBreakdown(DateTime month) {
    return _expenseService.getExpensesStream().map((expenses) {
      final Map<String, double> breakdown = {};
      
      for (var expense in expenses) {
        // Filter by month and year, and only expenses
        if (expense.type == 'expense' && 
            expense.date.year == month.year && 
            expense.date.month == month.month) {
          
          breakdown[expense.category] = (breakdown[expense.category] ?? 0) + expense.amount;
        }
      }
      return breakdown;
    });
  }

  /// Get daily spending for the last 7 days
  Stream<Map<String, double>> getWeeklySpendingTrend() {
    return _expenseService.getExpensesStream().map((expenses) {
      final Map<String, double> trend = {};
      final now = DateTime.now();
      
      // Initialize last 7 days with 0
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        // keys as "Mon", "Tue" etc is risky for uniqueness if spanning weeks, but for simple charts:
        // Let's use weekday index to sort or custom logic.
        // For simplicity, let's just return a list of values? No, map is safer.
        // Let's use 'YYYY-MM-DD' as key for sorting, or just Date object?
        // Let's use readable keys for UI directly if possible, or raw for parsing.
        // Let's use simple Day Name for display (Mon, Tue).
      }
      
      // Better approach: grouping by DateTime(y,m,d)
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      for (var expense in expenses) {
        if (expense.type == 'expense' && expense.date.isAfter(sevenDaysAgo)) {
           // Normalize date to remove time
           // Use standard ISO format YYYY-MM-DD
           final y = expense.date.year;
           final m = expense.date.month.toString().padLeft(2, '0');
           final d = expense.date.day.toString().padLeft(2, '0');
           final dateKey = "$y-$m-$d";
           trend[dateKey] = (trend[dateKey] ?? 0) + expense.amount;
        }
      }
      return trend; // logic to be refined in UI to ensure all days present
    });
  }
}
