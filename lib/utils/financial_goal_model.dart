import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String description;
  final String category; // e.g., "Retirement", "Home", "Education", "Emergency Fund"
  final List<GoalProgress> progressHistory;

  FinancialGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.description,
    required this.category,
    required this.progressHistory,
  });

  double get progressPercentage => (currentAmount / targetAmount) * 100;
  
  bool get isCompleted => currentAmount >= targetAmount;
  
  int get daysRemaining {
    final now = DateTime.now();
    return targetDate.difference(now).inDays;
  }
  
  double get monthlyContributionNeeded {
    if (isCompleted || daysRemaining <= 0) return 0;
    final monthsLeft = daysRemaining / 30;
    return (targetAmount - currentAmount) / monthsLeft;
  }

  factory FinancialGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    List<GoalProgress> progress = [];
    if (data['progressHistory'] != null) {
      progress = (data['progressHistory'] as List)
          .map((e) => GoalProgress.fromMap(e))
          .toList();
    }
    
    return FinancialGoal(
      id: doc.id,
      name: data['name'] ?? '',
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0).toDouble(),
      targetDate: (data['targetDate'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      progressHistory: progress,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': Timestamp.fromDate(targetDate),
      'description': description,
      'category': category,
      'progressHistory': progressHistory.map((e) => e.toMap()).toList(),
    };
  }
}

class GoalProgress {
  final DateTime date;
  final double amount;
  final String note;

  GoalProgress({
    required this.date,
    required this.amount,
    this.note = '',
  });

  factory GoalProgress.fromMap(Map<String, dynamic> map) {
    return GoalProgress(
      date: (map['date'] as Timestamp).toDate(),
      amount: (map['amount'] ?? 0).toDouble(),
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'note': note,
    };
  }
} 