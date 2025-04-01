import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/financial_goal_model.dart';

class FinancialGoalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all goals for current user
  Future<List<FinancialGoal>> getUserGoals() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('financial_goals')
          .orderBy('targetDate')
          .get();

      return snapshot.docs
          .map((doc) => FinancialGoal.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching user goals: $e');
      return [];
    }
  }

  // Add a new goal
  Future<String> addGoal(FinancialGoal goal) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('financial_goals')
          .add(goal.toFirestore());
          
      return docRef.id;
    } catch (e) {
      print('Error adding goal: $e');
      throw Exception('Failed to add goal');
    }
  }

  // Update existing goal
  Future<void> updateGoal(FinancialGoal goal) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('financial_goals')
          .doc(goal.id)
          .update(goal.toFirestore());
    } catch (e) {
      print('Error updating goal: $e');
      throw Exception('Failed to update goal');
    }
  }

  // Delete a goal
  Future<void> deleteGoal(String goalId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('financial_goals')
          .doc(goalId)
          .delete();
    } catch (e) {
      print('Error deleting goal: $e');
      throw Exception('Failed to delete goal');
    }
  }

  // Add a progress update to a goal
  Future<void> addProgressUpdate(
      String goalId, double amount, String note) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the current goal
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('financial_goals')
          .doc(goalId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Goal not found');
      }

      final goal = FinancialGoal.fromFirestore(docSnapshot);
      
      // Create new progress entry
      final progressEntry = GoalProgress(
        date: DateTime.now(),
        amount: amount,
        note: note,
      );

      // Add to history and update current amount
      final newHistory = List<GoalProgress>.from(goal.progressHistory)
        ..add(progressEntry);
      
      final newCurrentAmount = goal.currentAmount + amount;

      // Update the goal
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('financial_goals')
          .doc(goalId)
          .update({
        'progressHistory': newHistory.map((e) => e.toMap()).toList(),
        'currentAmount': newCurrentAmount,
      });
    } catch (e) {
      print('Error adding progress update: $e');
      throw Exception('Failed to add progress update');
    }
  }
} 