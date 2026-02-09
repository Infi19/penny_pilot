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

  /// Gather data for Monthly Financial Summary
  Future<Map<String, dynamic>> getMonthlySummaryData(DateTime month) async {
    // 1. Get all expenses
    final allExpenses = await _expenseService.getExpensesStream().first;
    
    // 2. Filter for Target Month and Previous Month
    final targetMonthExpenses = <Expense>[];
    final prevMonthExpenses = <Expense>[];
    
    final prevMonthDate = DateTime(month.year, month.month - 1);
    final nextMonthDate = DateTime(month.year, month.month + 1);

    for (var e in allExpenses) {
      if (e.type != 'expense') continue;

      if (e.date.year == month.year && e.date.month == month.month) {
        targetMonthExpenses.add(e);
      } else if (e.date.year == prevMonthDate.year && e.date.month == prevMonthDate.month) {
        prevMonthExpenses.add(e);
      }
    }

    // 3. Calculate Totals
    double totalSpend = targetMonthExpenses.fold(0, (sum, e) => sum + e.amount);
    double prevTotalSpend = prevMonthExpenses.fold(0, (sum, e) => sum + e.amount);

    // 4. Category Breakdown & Patterns
    final categoryTotals = <String, double>{};
    final dayOfWeekTotals = <int, double>{}; // 1=Mon, 7=Sun

    for (var e in targetMonthExpenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
      dayOfWeekTotals[e.date.weekday] = (dayOfWeekTotals[e.date.weekday] ?? 0) + e.amount;
    }

    // Calculate % change per category (simplified, comparing to prev month same category)
    // Note: This requires prev month category data too.
    final prevCategoryTotals = <String, double>{};
    for (var e in prevMonthExpenses) {
      prevCategoryTotals[e.category] = (prevCategoryTotals[e.category] ?? 0) + e.amount;
    }

    final categoryBreakdown = <Map<String, dynamic>>[];
    categoryTotals.forEach((cat, amount) {
      final prevAmount = prevCategoryTotals[cat] ?? 0;
      double percentChange = 0.0;
      if (prevAmount > 0) {
        percentChange = ((amount - prevAmount) / prevAmount) * 100;
      } else if (amount > 0) {
         percentChange = 100.0; // New expense
      }
      
      categoryBreakdown.add({
        'category': cat,
        'amount': amount,
        'percentChange': percentChange,
      });
    });

    // 5. High Spend Days Pattern
    // Simple heuristic: Get top 2 days of week
    final sortedDays = dayOfWeekTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final highSpendDays = sortedDays.take(2).map((e) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[e.key - 1]; // weekday is 1-7
    }).join(' and ');

    return {
      'month': "${month.year}-${month.month.toString().padLeft(2, '0')}", // YYYY-MM
      'totalSpend': totalSpend,
      'previousMonthTotal': prevTotalSpend,
      'categoryBreakdown': categoryBreakdown,
      'highSpendDays': highSpendDays.isNotEmpty ? highSpendDays : "No specific pattern",
    };
  }
}
