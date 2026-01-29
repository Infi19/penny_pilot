import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String merchant;
  final DateTime date;
  final String notes;
  final bool isAutoLogged;
  final String? originalMessage;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.merchant,
    required this.date,
    this.notes = '',
    this.isAutoLogged = false,
    this.originalMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'category': category,
      'merchant': merchant,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'isAutoLogged': isAutoLogged,
      'originalMessage': originalMessage,
    };
  }

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'General',
      merchant: map['merchant'] ?? 'Unknown',
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'] ?? '',
      isAutoLogged: map['isAutoLogged'] ?? false,
      originalMessage: map['originalMessage'],
    );
  }
}
