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
    }).asBroadcastStream();
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

  /// Get total income
  Stream<double> getTotalIncome() {
     return getExpensesStream().map((expenses) {
       return expenses
           .where((e) => e.type == 'income')
           .fold(0.0, (sum, e) => sum + e.amount);
     });
  }

  /// Get total expenses
  Stream<double> getTotalExpenses() {
    return getExpensesStream().map((expenses) {
      return expenses
          .where((e) => e.type == 'expense')
          .fold(0.0, (sum, e) => sum + e.amount);
    });
  }

  /// Check for duplicate expense (same amount, merchant, date within threshold)
  Future<bool> isDuplicateExpense(double amount, String merchant, DateTime date) async {
    if (_userId == null) return false;
    
    // Check range: +/- 24 hours just in case of slight parsing diffs, OR exact date if preferred.
    // For SMS, usually Date is precise. Let's check for same day.
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = await _expensesRef(_userId!)
        .where('amount', isEqualTo: amount)
        .where('merchant', isEqualTo: merchant)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return query.docs.isNotEmpty;
  }
  /// Get expenses for a specific period
  Future<List<Expense>> getExpensesInPeriod(DateTime start, DateTime end) async {
    if (_userId == null) return [];

    final query = await _expensesRef(_userId!)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();

    return query.docs.map((doc) => Expense.fromMap(doc.id, doc.data())).toList();
  }
}
