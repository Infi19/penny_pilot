class RiskQuestion {
  final int id;
  final String question;
  final List<RiskOption> options;

  RiskQuestion({
    required this.id,
    required this.question,
    required this.options,
  });
}

class RiskOption {
  final int value;
  final String text;

  RiskOption({
    required this.value,
    required this.text,
  });
}

class RiskProfile {
  final int totalScore;
  final String riskLevel;
  final String description;
  final List<String> recommendations;
  final DateTime assessmentDate;

  RiskProfile({
    required this.totalScore,
    required this.riskLevel,
    required this.description,
    required this.recommendations,
    required this.assessmentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalScore': totalScore,
      'riskLevel': riskLevel,
      'description': description,
      'recommendations': recommendations,
      'assessmentDate': assessmentDate.toIso8601String(),
    };
  }

  factory RiskProfile.fromMap(Map<String, dynamic> map) {
    return RiskProfile(
      totalScore: map['totalScore'] ?? 0,
      riskLevel: map['riskLevel'] ?? 'Unknown',
      description: map['description'] ?? '',
      recommendations: List<String>.from(map['recommendations'] ?? []),
      assessmentDate: map['assessmentDate'] != null
          ? DateTime.parse(map['assessmentDate'])
          : DateTime.now(),
    );
  }
} 