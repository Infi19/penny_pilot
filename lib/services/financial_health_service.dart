import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/financial_health_model.dart';

class FinancialHealthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the latest financial health score for the current user
  Future<FinancialHealthScore?> getLatestHealthScore() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('financial_health_scores')
          .orderBy('assessmentDate', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return FinancialHealthScore.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error fetching health score: $e');
      return null;
    }
  }

  // Get all health scores for the current user
  Future<List<FinancialHealthScore>> getAllHealthScores() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('financial_health_scores')
          .orderBy('assessmentDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FinancialHealthScore.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching health scores: $e');
      return [];
    }
  }

  // Save a new financial health score
  Future<String> saveHealthScore({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double monthlySavings,
    required double totalDebt,
    required Map<String, double> investments,
    required double emergencyFund,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Generate a temporary ID
      final tempId = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('financial_health_scores')
          .doc()
          .id;

      // Create the financial health score
      final healthScore = FinancialHealthScore.createFromUserInputs(
        id: tempId,
        monthlyIncome: monthlyIncome,
        monthlyExpenses: monthlyExpenses,
        monthlySavings: monthlySavings,
        totalDebt: totalDebt,
        investments: investments,
        emergencyFund: emergencyFund,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('financial_health_scores')
          .add(healthScore.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error saving health score: $e');
      throw Exception('Failed to save health score');
    }
  }

  // Delete a health score
  Future<void> deleteHealthScore(String scoreId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('financial_health_scores')
          .doc(scoreId)
          .delete();
    } catch (e) {
      print('Error deleting health score: $e');
      throw Exception('Failed to delete health score');
    }
  }
} 