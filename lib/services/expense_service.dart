import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Collection reference
  CollectionReference<Map<String, dynamic>> _expensesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('expenses');
  }

  /// Add a new expense
  Future<void> addExpense(Expense expense) async {
    if (_userId == null) return;
    
    // We ignore the ID in the object and let Firestore generate one
    await _expensesRef(_userId!).add(expense.toMap());
  }

  /// Get stream of expenses ordered by date (newest first)
  Stream<List<Expense>> getExpensesStream() {
    if (_userId == null) return Stream.value([]);

    return _expensesRef(_userId!)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    if (_userId == null) return;
    await _expensesRef(_userId!).doc(expenseId).delete();
  }

  /// Update an expense
  Future<void> updateExpense(Expense expense) async {
    if (_userId == null) return;
    await _expensesRef(_userId!).doc(expense.id).update(expense.toMap());
  }
}
