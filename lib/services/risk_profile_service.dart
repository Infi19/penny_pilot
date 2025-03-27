import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/risk_profile_model.dart';
import '../utils/retry_helper.dart';

class RiskProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Predefined risk assessment questions
  List<RiskQuestion> getAssessmentQuestions() {
    return [
      RiskQuestion(
        id: 1,
        question: 'How would you react if your investment lost 20% of its value in a month?',
        options: [
          RiskOption(value: 1, text: 'Sell all my investments to avoid further losses'),
          RiskOption(value: 2, text: 'Sell some of my investments'),
          RiskOption(value: 3, text: 'Do nothing and wait for recovery'),
          RiskOption(value: 4, text: 'Buy more at the lower price'),
        ],
      ),
      RiskQuestion(
        id: 2,
        question: 'What is your primary investment goal?',
        options: [
          RiskOption(value: 1, text: 'Preserving capital (minimal risk)'),
          RiskOption(value: 2, text: 'Generating income'),
          RiskOption(value: 3, text: 'Balanced growth and income'),
          RiskOption(value: 4, text: 'Aggressive growth (higher risk)'),
        ],
      ),
      RiskQuestion(
        id: 3,
        question: 'When do you expect to need the money you\'re investing?',
        options: [
          RiskOption(value: 1, text: 'Within the next 2 years'),
          RiskOption(value: 2, text: 'In 2-5 years'),
          RiskOption(value: 3, text: 'In 5-10 years'),
          RiskOption(value: 4, text: 'More than 10 years from now'),
        ],
      ),
      RiskQuestion(
        id: 4,
        question: 'Which statement best describes your investment knowledge?',
        options: [
          RiskOption(value: 1, text: 'I\'m new to investing'),
          RiskOption(value: 2, text: 'I understand basics but am not confident'),
          RiskOption(value: 3, text: 'I have moderate knowledge and experience'),
          RiskOption(value: 4, text: 'I\'m an experienced investor'),
        ],
      ),
      RiskQuestion(
        id: 5,
        question: 'How comfortable are you with investment volatility?',
        options: [
          RiskOption(value: 1, text: 'Not comfortable - I prefer stability'),
          RiskOption(value: 2, text: 'Somewhat comfortable with occasional fluctuations'),
          RiskOption(value: 3, text: 'Comfortable with moderate volatility'),
          RiskOption(value: 4, text: 'Very comfortable with significant volatility'),
        ],
      ),
    ];
  }

  // Calculate risk profile based on assessment answers
  RiskProfile calculateRiskProfile(List<int> answers) {
    final totalScore = answers.fold(0, (sum, score) => sum + score);
    final maxPossibleScore = getAssessmentQuestions().length * 4; // Assuming 4 is max per question
    
    String riskLevel;
    String description;
    List<String> recommendations;

    if (totalScore <= maxPossibleScore * 0.25) {
      riskLevel = 'Conservative';
      description = 'You prefer security and stability over higher returns. You\'re not comfortable with significant market fluctuations.';
      recommendations = [
        'Consider bonds and fixed income investments',
        'Maintain higher cash reserves',
        'Focus on blue-chip stocks with consistent dividends',
        'Consider certificates of deposit (CDs) and money market accounts'
      ];
    } else if (totalScore <= maxPossibleScore * 0.5) {
      riskLevel = 'Moderately Conservative';
      description = 'You prioritize capital preservation but are open to some growth opportunities with limited risk.';
      recommendations = [
        'Mix of bonds (60-70%) and stocks (30-40%)',
        'Focus on established companies with growth potential',
        'Consider balanced mutual funds',
        'Maintain moderate cash reserves'
      ];
    } else if (totalScore <= maxPossibleScore * 0.75) {
      riskLevel = 'Moderate';
      description = 'You seek a balance between growth and safety, willing to accept some volatility for better returns.';
      recommendations = [
        'Balanced portfolio of stocks (50-60%) and bonds (40-50%)',
        'Consider index funds for diversification',
        'Explore growth-oriented mutual funds',
        'Some exposure to international markets'
      ];
    } else if (totalScore <= maxPossibleScore * 0.9) {
      riskLevel = 'Moderately Aggressive';
      description = 'You prioritize growth over stability and can tolerate significant market fluctuations.';
      recommendations = [
        'Higher allocation to stocks (70-80%)',
        'Consider growth-oriented stocks and funds',
        'Moderate exposure to international and emerging markets',
        'Limited bond allocation (20-30%) for some stability'
      ];
    } else {
      riskLevel = 'Aggressive';
      description = 'You seek maximum growth and are comfortable with high volatility and potential for larger losses in pursuit of higher returns.';
      recommendations = [
        'Predominantly stock-focused portfolio (80-90%)',
        'Consider small-cap and growth stocks',
        'Significant allocation to international and emerging markets',
        'Minimal bond allocation (10-20%) or alternative investments'
      ];
    }

    return RiskProfile(
      totalScore: totalScore,
      riskLevel: riskLevel,
      description: description,
      recommendations: recommendations,
      assessmentDate: DateTime.now(),
    );
  }

  // Save user's risk profile to Firestore
  Future<void> saveRiskProfile(String userId, RiskProfile profile) async {
    try {
      await RetryHelper.withRetry(
        operation: () => _firestore
            .collection('users')
            .doc(userId)
            .collection('riskProfile')
            .doc('current')
            .set(profile.toMap()),
      );
      
      // Also update the main user document with the risk level
      await RetryHelper.withRetry(
        operation: () => _firestore
            .collection('users')
            .doc(userId)
            .update({
              'riskLevel': profile.riskLevel,
              'lastRiskAssessment': profile.assessmentDate.toIso8601String(),
            }),
      );
    } catch (e) {
      print('Error saving risk profile: $e');
      rethrow;
    }
  }

  // Get user's current risk profile from Firestore
  Future<RiskProfile?> getRiskProfile(String userId) async {
    try {
      final doc = await RetryHelper.withRetry(
        operation: () => _firestore
            .collection('users')
            .doc(userId)
            .collection('riskProfile')
            .doc('current')
            .get(),
      );
      
      if (doc.exists && doc.data() != null) {
        return RiskProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting risk profile: $e');
      rethrow;
    }
  }
} 