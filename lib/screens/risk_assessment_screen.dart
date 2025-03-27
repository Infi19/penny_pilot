import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/risk_profile_service.dart';
import '../utils/risk_profile_model.dart';
import '../utils/app_colors.dart';
import 'risk_profile_result_screen.dart';

class RiskAssessmentScreen extends StatefulWidget {
  const RiskAssessmentScreen({super.key});

  @override
  State<RiskAssessmentScreen> createState() => _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends State<RiskAssessmentScreen> {
  final RiskProfileService _riskService = RiskProfileService();
  late List<RiskQuestion> _questions;
  List<int?> _selectedAnswers = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _questions = _riskService.getAssessmentQuestions();
    _selectedAnswers = List.filled(_questions.length, null);
  }

  void _selectAnswer(int value) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = value;
    });
  }

  bool get _canGoNext {
    return _selectedAnswers[_currentQuestionIndex] != null;
  }

  bool get _canGoBack {
    return _currentQuestionIndex > 0;
  }

  bool get _isLastQuestion {
    return _currentQuestionIndex == _questions.length - 1;
  }

  void _goToNextQuestion() {
    if (_canGoNext) {
      if (_isLastQuestion) {
        _submitAssessment();
      } else {
        setState(() {
          _currentQuestionIndex++;
        });
      }
    }
  }

  void _goToPreviousQuestion() {
    if (_canGoBack) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitAssessment() async {
    // Convert List<int?> to List<int> - should be safe as we validated all questions are answered
    final answers = _selectedAnswers.map((a) => a!).toList();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = _riskService.calculateRiskProfile(answers);
        await _riskService.saveRiskProfile(user.uid, profile);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RiskProfileResultScreen(profile: profile),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting assessment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Risk Profile Assessment',
          style: TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkest,
        iconTheme: const IconThemeData(color: AppColors.lightest),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.lightest))
          : Column(
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: AppColors.darkGrey,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lightest),
                ),
                
                // Question number
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                        style: const TextStyle(
                          color: AppColors.lightest,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Question
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    currentQuestion.question,
                    style: const TextStyle(
                      color: AppColors.lightest,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Options
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.options.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final option = currentQuestion.options[index];
                      final isSelected = _selectedAnswers[_currentQuestionIndex] == option.value;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          color: isSelected ? AppColors.lightest : AppColors.darkGrey,
                          elevation: isSelected ? 4 : 2,
                          child: InkWell(
                            onTap: () => _selectAnswer(option.value),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                option.text,
                                style: TextStyle(
                                  color: isSelected ? AppColors.darkest : AppColors.lightest,
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _canGoBack ? _goToPreviousQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGrey,
                          foregroundColor: AppColors.lightest,
                          disabledForegroundColor: AppColors.mediumGrey.withOpacity(0.38),
                          disabledBackgroundColor: AppColors.darkGrey.withOpacity(0.12),
                        ),
                        child: const Text('Previous'),
                      ),
                      ElevatedButton(
                        onPressed: _canGoNext ? _goToNextQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightest,
                          foregroundColor: AppColors.darkest,
                          disabledForegroundColor: AppColors.mediumGrey.withOpacity(0.38),
                          disabledBackgroundColor: AppColors.lightest.withOpacity(0.12),
                        ),
                        child: Text(_isLastQuestion ? 'Submit' : 'Next'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 