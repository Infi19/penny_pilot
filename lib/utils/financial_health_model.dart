import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialHealthScore {
  final String id;
  final double incomeExpensesRatio;
  final double savingsRate;
  final double debtToIncomeRatio;
  final double investmentDiversification;
  final double emergencyFundRatio;
  final double totalScore;
  final String healthCategory;
  final List<String> recommendations;
  final DateTime assessmentDate;

  FinancialHealthScore({
    required this.id,
    required this.incomeExpensesRatio,
    required this.savingsRate,
    required this.debtToIncomeRatio,
    required this.investmentDiversification,
    required this.emergencyFundRatio,
    required this.totalScore,
    required this.healthCategory,
    required this.recommendations,
    required this.assessmentDate,
  });

  // Get specific metric score based on input values
  static double calculateIncomeExpensesScore(double ratio) {
    if (ratio >= 1.5) return 25.0;
    if (ratio >= 1.3) return 20.0;
    if (ratio >= 1.1) return 15.0;
    if (ratio >= 1.0) return 10.0;
    return 5.0;
  }

  static double calculateSavingsRateScore(double rate) {
    if (rate >= 0.20) return 20.0; // 20% or more
    if (rate >= 0.15) return 15.0; // 15-19%
    if (rate >= 0.10) return 10.0; // 10-14%
    if (rate >= 0.05) return 5.0;  // 5-9%
    return 2.0;                    // Less than 5%
  }

  static double calculateDebtToIncomeScore(double ratio) {
    if (ratio < 0.20) return 20.0;  // Less than 20%
    if (ratio < 0.35) return 15.0;  // 20-35%
    if (ratio < 0.45) return 10.0;  // 35-45%
    if (ratio < 0.55) return 5.0;   // 45-55%
    return 2.0;                     // More than 55%
  }

  static double calculateInvestmentDiversificationScore(double score) {
    if (score >= 0.80) return 15.0; // Well diversified (80%+)
    if (score >= 0.60) return 10.0; // Moderately diversified (60-79%)
    if (score >= 0.40) return 7.0;  // Somewhat diversified (40-59%)
    if (score >= 0.20) return 3.0;  // Poorly diversified (20-39%)
    return 1.0;                     // No diversification (<20%)
  }

  static double calculateEmergencyFundScore(double monthsCovered) {
    if (monthsCovered >= 6.0) return 20.0;  // 6+ months
    if (monthsCovered >= 4.0) return 15.0;  // 4-5 months
    if (monthsCovered >= 3.0) return 10.0;  // 3 months
    if (monthsCovered >= 1.0) return 5.0;   // 1-2 months
    return 2.0;                            // Less than 1 month
  }

  // Calculate the total score
  static double calculateTotalScore({
    required double incomeExpensesRatio,
    required double savingsRate,
    required double debtToIncomeRatio,
    required double investmentDiversification,
    required double emergencyFundRatio,
  }) {
    final incomeExpensesScore = calculateIncomeExpensesScore(incomeExpensesRatio);
    final savingsRateScore = calculateSavingsRateScore(savingsRate);
    final debtToIncomeScore = calculateDebtToIncomeScore(debtToIncomeRatio);
    final investmentScore = calculateInvestmentDiversificationScore(investmentDiversification);
    final emergencyFundScore = calculateEmergencyFundScore(emergencyFundRatio);

    return incomeExpensesScore + savingsRateScore + debtToIncomeScore + 
           investmentScore + emergencyFundScore;
  }

  // Get health category based on score
  static String getHealthCategory(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Moderate Risk';
    return 'High Risk';
  }

  // Get color for the health category
  static String getHealthCategoryColor(String category) {
    switch (category) {
      case 'Excellent': return 'green';
      case 'Good': return 'yellow';
      case 'Moderate Risk': return 'orange';
      case 'High Risk': return 'red';
      default: return 'grey';
    }
  }

  // Generate recommendations based on scores
  static List<String> generateRecommendations({
    required double incomeExpensesRatio,
    required double savingsRate,
    required double debtToIncomeRatio,
    required double investmentDiversification,
    required double emergencyFundRatio,
  }) {
    List<String> recommendations = [];
    
    if (incomeExpensesRatio < 1.1) {
      recommendations.add('Focus on increasing income or reducing expenses to improve your income-to-expenses ratio.');
    }
    
    if (savingsRate < 0.10) {
      recommendations.add('Try to increase your savings rate to at least 10% of income.');
    }
    
    if (debtToIncomeRatio > 0.35) {
      recommendations.add('Work on reducing your debt-to-income ratio to less than 35%.');
    }
    
    if (investmentDiversification < 0.40) {
      recommendations.add('Consider diversifying your investments across different asset classes.');
    }
    
    if (emergencyFundRatio < 3.0) {
      recommendations.add('Build an emergency fund that covers at least 3 months of expenses.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Your financial health is in good shape. Continue your current financial practices.');
    }
    
    return recommendations;
  }

  // Create a FinancialHealthScore from user inputs
  static FinancialHealthScore createFromUserInputs({
    required String id,
    required double monthlyIncome,
    required double monthlyExpenses,
    required double monthlySavings,
    required double totalDebt,
    required Map<String, double> investments,
    required double emergencyFund,
  }) {
    // Calculate key ratios
    final incomeExpensesRatio = monthlyIncome / monthlyExpenses;
    final savingsRate = monthlySavings / monthlyIncome;
    final debtToIncomeRatio = totalDebt / (monthlyIncome * 12); // Annual income
    
    // Calculate investment diversification score
    double investmentDiversification = 0.0;
    if (investments.isNotEmpty) {
      final double totalInvestment = investments.values.reduce((a, b) => a + b);
      
      if (totalInvestment > 0) {
        // Calculate Herfindahl-Hirschman Index (HHI) for diversification
        double sumSquaredShares = 0.0;
        for (final value in investments.values) {
          final marketShare = value / totalInvestment;
          sumSquaredShares += (marketShare * marketShare);
        }
        
        // Convert HHI to a diversification score (1 - HHI)
        investmentDiversification = 1.0 - sumSquaredShares;
      }
    }
    
    // Calculate emergency fund ratio (months of expenses covered)
    final emergencyFundRatio = emergencyFund / monthlyExpenses;
    
    // Calculate total score
    final totalScore = calculateTotalScore(
      incomeExpensesRatio: incomeExpensesRatio,
      savingsRate: savingsRate,
      debtToIncomeRatio: debtToIncomeRatio,
      investmentDiversification: investmentDiversification,
      emergencyFundRatio: emergencyFundRatio,
    );
    
    // Determine health category
    final healthCategory = getHealthCategory(totalScore);
    
    // Generate recommendations
    final recommendations = generateRecommendations(
      incomeExpensesRatio: incomeExpensesRatio,
      savingsRate: savingsRate,
      debtToIncomeRatio: debtToIncomeRatio,
      investmentDiversification: investmentDiversification,
      emergencyFundRatio: emergencyFundRatio,
    );
    
    return FinancialHealthScore(
      id: id,
      incomeExpensesRatio: incomeExpensesRatio,
      savingsRate: savingsRate,
      debtToIncomeRatio: debtToIncomeRatio,
      investmentDiversification: investmentDiversification,
      emergencyFundRatio: emergencyFundRatio,
      totalScore: totalScore,
      healthCategory: healthCategory,
      recommendations: recommendations,
      assessmentDate: DateTime.now(),
    );
  }

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'incomeExpensesRatio': incomeExpensesRatio,
      'savingsRate': savingsRate,
      'debtToIncomeRatio': debtToIncomeRatio,
      'investmentDiversification': investmentDiversification,
      'emergencyFundRatio': emergencyFundRatio,
      'totalScore': totalScore,
      'healthCategory': healthCategory,
      'recommendations': recommendations,
      'assessmentDate': Timestamp.fromDate(assessmentDate),
    };
  }

  // Create from Firestore
  factory FinancialHealthScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FinancialHealthScore(
      id: doc.id,
      incomeExpensesRatio: (data['incomeExpensesRatio'] ?? 0).toDouble(),
      savingsRate: (data['savingsRate'] ?? 0).toDouble(),
      debtToIncomeRatio: (data['debtToIncomeRatio'] ?? 0).toDouble(),
      investmentDiversification: (data['investmentDiversification'] ?? 0).toDouble(),
      emergencyFundRatio: (data['emergencyFundRatio'] ?? 0).toDouble(),
      totalScore: (data['totalScore'] ?? 0).toDouble(),
      healthCategory: data['healthCategory'] ?? 'Unknown',
      recommendations: List<String>.from(data['recommendations'] ?? []),
      assessmentDate: (data['assessmentDate'] as Timestamp).toDate(),
    );
  }
} 