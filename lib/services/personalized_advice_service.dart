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

class PersonalizedAdviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RiskProfileService _riskService = RiskProfileService();
  final FinancialGoalsService _goalsService = FinancialGoalsService();
  final FinancialHealthService _healthService = FinancialHealthService();
  final UserService _userService = UserService();
  
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
      
      // Execute all requests in parallel for better performance
      final userProfileFuture = _userService.getUserProfile(user.uid);
      final riskProfileFuture = _riskService.getRiskProfile(user.uid);
      final goalsFuture = _goalsService.getUserGoals();
      final healthScoreFuture = _healthService.getLatestHealthScore();
      
      // Await results individually to handle types correctly
      final userProfile = await userProfileFuture;
      final riskProfile = await riskProfileFuture;
      final goals = await goalsFuture;
      final healthScore = await healthScoreFuture;
      
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
      
      // Format the financial context in a structure suitable for AI consumption
      final Map<String, dynamic> context = {
        'userProfile': userProfile ?? {},
        'financialGoals': goalsSummary,
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