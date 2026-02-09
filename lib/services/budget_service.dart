import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/budget_model.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _budgetsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('budgets');
  }

  /// Set or Update budget for a category
  Future<void> setBudget(Budget budget) async {
    if (_userId == null) return;
    
    // Check if budget for category exists
    final query = await _budgetsRef(_userId!)
        .where('category', isEqualTo: budget.category)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // Update existing
      await _budgetsRef(_userId!).doc(query.docs.first.id).update({
        'limitAmount': budget.limitAmount,
      });
    } else {
      // Create new
      await _budgetsRef(_userId!).add(budget.toMap());
    }
  }

  /// Get all budgets
  Stream<List<Budget>> getBudgetsStream() {
    if (_userId == null) return Stream.value([]);

    return _budgetsRef(_userId!).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Budget.fromMap(doc.id, doc.data())).toList();
    });
  }

  /// Get all budgets as a Future List
  Future<List<Budget>> getUserBudgets() async {
    if (_userId == null) return [];
    
    try {
      final snapshot = await _budgetsRef(_userId!).get();
      return snapshot.docs.map((doc) => Budget.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('Error getting user budgets: $e');
      return [];
    }
  }

  /// Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    if (_userId == null) return;
    await _budgetsRef(_userId!).doc(budgetId).delete();
  }
}
