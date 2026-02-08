class Budget {
  final String id;
  final String userId;
  final String category;
  final double limitAmount;
  final String period; // 'monthly'

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    this.period = 'monthly',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'limitAmount': limitAmount,
      'period': period,
    };
  }

  factory Budget.fromMap(String id, Map<String, dynamic> map) {
    return Budget(
      id: id,
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      limitAmount: (map['limitAmount'] ?? 0.0).toDouble(),
      period: map['period'] ?? 'monthly',
    );
  }
}
