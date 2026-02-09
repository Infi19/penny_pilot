import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/retry_helper.dart';
import '../utils/risk_profile_model.dart';
import '../utils/financial_goal_model.dart';
import '../utils/financial_health_model.dart';
import 'risk_profile_service.dart';
import 'financial_goals_service.dart';
import 'financial_health_service.dart';
import 'user_service.dart';
import 'expense_service.dart';
import 'budget_service.dart';
import '../utils/expense_model.dart';

class PersonalizedAdviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RiskProfileService _riskService = RiskProfileService();
  final FinancialGoalsService _goalsService = FinancialGoalsService();
  final FinancialHealthService _healthService = FinancialHealthService();
  final UserService _userService = UserService();
  final ExpenseService _expenseService = ExpenseService();
  final BudgetService _budgetService = BudgetService();
  
  // Cache to store user financial context for the session
  Map<String, dynamic>? _cachedUserContext;
  DateTime? _cacheTimestamp;

  /// Retrieves all user financial context data for AI personalization
  Future<Map<String, dynamic>> getUserFinancialContext() async {
    try {
      // Return cached data if less than 5 minutes old
      if (_cachedUserContext != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge.inMinutes < 5) {
          return _cachedUserContext!;
        }
      }
    
      final user = _auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }
      
      final now = DateTime.now();
      final startOfCurrentMonth = DateTime(now.year, now.month, 1);
      final endOfCurrentMonth = DateTime(now.year, now.month + 1, 0);
      
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);

      // Execute all requests in parallel for better performance
      final userProfileFuture = _userService.getUserProfile(user.uid);
      final riskProfileFuture = _riskService.getRiskProfile(user.uid);
      final goalsFuture = _goalsService.getUserGoals();
      final healthScoreFuture = _healthService.getLatestHealthScore();
      final currentMonthExpensesFuture = _expenseService.getExpensesInPeriod(startOfCurrentMonth, endOfCurrentMonth);
      final lastMonthExpensesFuture = _expenseService.getExpensesInPeriod(startOfLastMonth, endOfLastMonth);
      final budgetsFuture = _budgetService.getUserBudgets();
      
      // Await results individually to handle types correctly
      final userProfile = await userProfileFuture;
      final riskProfile = await riskProfileFuture;
      final goals = await goalsFuture;
      final healthScore = await healthScoreFuture;
      final budgets = await budgetsFuture;
      // Filter for expenses only
      final currentMonthExpenses = (await currentMonthExpensesFuture).where((e) => e.type == 'expense').toList();
      final lastMonthExpenses = (await lastMonthExpensesFuture).where((e) => e.type == 'expense').toList();
      
      // Calculate summary metrics for personalization
      List<Map<String, dynamic>> goalsSummary = [];
      for (var goal in goals) {
        goalsSummary.add({
          'name': goal.name,
          'category': goal.category,
          'progress': goal.progressPercentage,
          'daysRemaining': goal.daysRemaining,
          'monthlyNeeded': goal.monthlyContributionNeeded,
          'isCompleted': goal.isCompleted,
        });
      }

      // Process Spending Data
      double currentMonthTotal = currentMonthExpenses.fold(0, (sum, e) => sum + e.amount);
      double lastMonthTotal = lastMonthExpenses.fold(0, (sum, e) => sum + e.amount);
      
      Map<String, double> currentCategoryTotals = {};
      for (var e in currentMonthExpenses) {
        currentCategoryTotals[e.category] = (currentCategoryTotals[e.category] ?? 0) + e.amount;
      }
      
      Map<String, double> lastCategoryTotals = {};
      for (var e in lastMonthExpenses) {
        lastCategoryTotals[e.category] = (lastCategoryTotals[e.category] ?? 0) + e.amount;
      }
      
      List<Map<String, dynamic>> categoryTrends = [];
      currentCategoryTotals.forEach((category, amount) {
          double lastAmount = lastCategoryTotals[category] ?? 0;
          double percentChange = lastAmount > 0 ? ((amount - lastAmount) / lastAmount) * 100 : 100;
          categoryTrends.add({
              'category': category,
              'currentAmount': amount,
              'lastAmount': lastAmount,
              'percentChange': percentChange,
          });
      });
      // Sort by current amount descending
      categoryTrends.sort((a, b) => (b['currentAmount'] as double).compareTo(a['currentAmount'] as double));

      // Process Budgets
      List<Map<String, dynamic>> budgetSummary = [];
      for (var budget in budgets) {
        double spent = currentCategoryTotals[budget.category] ?? 0.0;
        budgetSummary.add({
          'category': budget.category,
          'limit': budget.limitAmount,
          'spent': spent,
          'remaining': budget.limitAmount - spent,
          'percentUsed': (spent / budget.limitAmount) * 100,
        });
      }
      
      // Format the financial context in a structure suitable for AI consumption
      final Map<String, dynamic> context = {
        'userProfile': userProfile ?? {},
        'financialGoals': goalsSummary,
        'budgets': budgetSummary,
        'spending': {
            'month': '${now.month}/${now.year}',
            'currentMonthTotal': currentMonthTotal,
            'lastMonthTotal': lastMonthTotal,
            'trends': categoryTrends,
        }
      };
      
      // Add risk profile if available
      if (riskProfile != null) {
        context['riskProfile'] = {
          'riskLevel': riskProfile.riskLevel,
          'score': riskProfile.totalScore,
          'assessmentDate': riskProfile.assessmentDate.toIso8601String(),
        };
      }
      
      // Add health score if available
      if (healthScore != null) {
        context['financialHealth'] = {
          'score': healthScore.totalScore,
          'category': healthScore.healthCategory,
          'recommendations': healthScore.recommendations,
          'incomeExpensesRatio': healthScore.incomeExpensesRatio,
          'savingsRate': healthScore.savingsRate,
          'debtToIncomeRatio': healthScore.debtToIncomeRatio,
          'emergencyFundRatio': healthScore.emergencyFundRatio,
        };
      }
      
      // Cache the context
      _cachedUserContext = context;
      _cacheTimestamp = DateTime.now();
      
      return context;
    } catch (e) {
      print('Error getting user financial context: $e');
      // Return empty map or cached data if available
      return _cachedUserContext ?? {};
    }
  }
  
  /// Saves the interaction with advice for future reference
  Future<void> logAdviceInteraction(String query, String advice, String category) async {
    // Don't block the response with logging
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }
      
      // Store only a short excerpt of advice to reduce database writes
      final shortAdvice = advice.length > 150 ? advice.substring(0, 150) + '...' : advice;
      
      // Use a background operation to not block the UI
      Future(() async {
        try {
          await RetryHelper.withRetry(
            operation: () => _firestore
                .collection('users')
                .doc(user.uid)
                .collection('adviceHistory')
                .add({
                  'query': query,
                  'advice': shortAdvice,
                  'category': category,
                  'timestamp': FieldValue.serverTimestamp(),
                }),
          );
        } catch (e) {
          print('Error in background logging of advice: $e');
        }
      });
    } catch (e) {
      print('Error setting up advice logging: $e');
    }
  }
  
  /// Gets the user's recent advice history
  Future<List<Map<String, dynamic>>> getRecentAdviceHistory({int limit = 5}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }
      
      final adviceRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('adviceHistory')
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      final adviceSnapshot = await RetryHelper.withRetry(
        operation: () => adviceRef.get(),
      );
      
      return adviceSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'query': data['query'] ?? '',
          'advice': data['advice'] ?? '',
          'category': data['category'] ?? '',
          'timestamp': data['timestamp']?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error getting advice history: $e');
      return [];
    }
  }
} 