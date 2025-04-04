import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../widgets/quiz_result_dialog.dart';
import '../utils/app_colors.dart';

class QuizScreen extends StatefulWidget {
  final DailyQuiz quiz;
  
  const QuizScreen({Key? key, required this.quiz}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  List<int?> _userAnswers = [];
  bool _quizCompleted = false;
  bool _submitting = false;
  
  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }
  
  void _initializeQuiz() {
    // Initialize user answers list with null values for each question
    _userAnswers = List.filled(widget.quiz.questions.length, null);
    print('DEBUG: Initialized quiz with ${widget.quiz.questions.length} questions');
    print('DEBUG: Quiz difficulty: ${userLevelToString(widget.quiz.difficulty ?? UserLevel.beginner)}');
    
    // If the quiz is already completed, mark as completed
    if (widget.quiz.isCompleted) {
      _quizCompleted = true;
    } else {
      _quizCompleted = false;
    }
    
    // Reset to first question
    _currentQuestionIndex = 0;
  }
  
  @override
  void didUpdateWidget(QuizScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the quiz ID has changed, reinitialize the state
    if (oldWidget.quiz.id != widget.quiz.id) {
      print('DEBUG: Quiz changed, reinitializing state');
      _initializeQuiz();
    }
  }
  
  void _selectAnswer(int answerIndex) {
    if (_userAnswers[_currentQuestionIndex] != null) return; // Prevent changing answer
    
    setState(() {
      _userAnswers[_currentQuestionIndex] = answerIndex;
    });
    
    // Auto-advance to next question after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
        _nextQuestion();
      } else {
        _finishQuiz();
      }
    });
  }
  
  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }
  
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }
  
  Future<void> _finishQuiz() async {
    // First check if the user has already completed a quiz today
    final quizService = Provider.of<QuizService>(context, listen: false);
    final hasAlreadyCompleted = await quizService.hasCompletedTodaysQuiz();
    
    if (hasAlreadyCompleted && !widget.quiz.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already completed a quiz today. Please return tomorrow for a new quiz.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate back to the Learn screen
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    
    // Check if all questions have been answered
    if (_userAnswers.contains(null)) {
      // Show a message that not all questions are answered
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submitting.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _quizCompleted = true;
    });
    
    // Calculate score
    int correctAnswers = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_userAnswers[i] == widget.quiz.questions[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }
    
    // Calculate score (10 points per correct answer)
    final score = correctAnswers * 10;
    
    try {
      setState(() {
        _submitting = true;
      });
      
      // Create quiz result
      final result = QuizResult(
        quizId: widget.quiz.id,
        date: DateTime.now().toIso8601String(),
        score: score,
        userAnswers: _userAnswers.cast<int>(), // Safe to cast since we've verified no nulls
        correctAnswers: correctAnswers,
        totalQuestions: widget.quiz.questions.length,
      );
      
      // Submit result
      await quizService.submitQuizResult(result);
      
      // Show results dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => QuizResultDialog(
            correctAnswers: correctAnswers,
            totalQuestions: widget.quiz.questions.length,
            score: score,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit quiz: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
  
  String _getDifficultyLabel(UserLevel level) {
    switch (level) {
      case UserLevel.beginner:
        return 'Beginner';
      case UserLevel.intermediate:
        return 'Intermediate';
      case UserLevel.advanced:
        return 'Advanced';
      default:
        return 'Beginner';
    }
  }
  
  Color _getDifficultyColor(UserLevel level) {
    switch (level) {
      case UserLevel.beginner:
        return Colors.green;
      case UserLevel.intermediate:
        return Colors.orange;
      case UserLevel.advanced:
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final userAnswer = _userAnswers[_currentQuestionIndex];
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Daily Investment Quiz',
          style: TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(
                _getDifficultyLabel(widget.quiz.difficulty ?? UserLevel.beginner),
                style: const TextStyle(
                  color: AppColors.lightest,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _getDifficultyColor(widget.quiz.difficulty ?? UserLevel.beginner),
            ),
          ),
        ],
      ),
      body: _submitting
          ? const Center(child: CircularProgressIndicator(color: AppColors.lightest))
          : widget.quiz.isCompleted
              ? _buildCompletedQuizView()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Progress indicator
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: LinearProgressIndicator(
                            value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                            backgroundColor: AppColors.darkGrey,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        
                        // Question counter
                        Text(
                          'Question ${_currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
                          style: const TextStyle(
                            color: AppColors.lightest,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Question text
                        Card(
                          elevation: 3,
                          color: AppColors.darkGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentQuestion.question,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightest,
                                  ),
                                ),
                                if (currentQuestion.difficulty != null) 
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Chip(
                                      label: Text(
                                        _getDifficultyLabel(currentQuestion.difficulty!),
                                        style: const TextStyle(
                                          color: AppColors.lightest,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: _getDifficultyColor(currentQuestion.difficulty!),
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      padding: const EdgeInsets.all(0),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Options
                        ...List.generate(
                          currentQuestion.options.length,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: OptionButton(
                              option: currentQuestion.options[index],
                              index: index,
                              isSelected: userAnswer == index,
                              isCorrect: _quizCompleted ? index == currentQuestion.correctAnswerIndex : null,
                              isIncorrect: _quizCompleted ? userAnswer == index && index != currentQuestion.correctAnswerIndex : null,
                              onTap: _quizCompleted ? null : _selectAnswer,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Explanation (only shown after quiz is completed)
                        if (_quizCompleted)
                          Card(
                            margin: const EdgeInsets.only(bottom: 20),
                            color: AppColors.darkGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Explanation:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.tertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentQuestion.explanation,
                                    style: const TextStyle(
                                      color: AppColors.lightest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Navigation buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentQuestionIndex > 0)
                              ElevatedButton.icon(
                                onPressed: _previousQuestion,
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Previous'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkGrey,
                                  foregroundColor: AppColors.lightest,
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                              
                            if (_currentQuestionIndex < widget.quiz.questions.length - 1)
                              ElevatedButton.icon(
                                onPressed: userAnswer != null ? _nextQuestion : null,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Next'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.lightest,
                                  disabledBackgroundColor: AppColors.darkGrey.withOpacity(0.5),
                                ),
                              )
                            else if (!_quizCompleted)
                              ElevatedButton.icon(
                                onPressed: _finishQuiz,
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Submit Quiz'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.tertiary,
                                  foregroundColor: AppColors.lightest,
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCompletedQuizView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              color: AppColors.darkGrey,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.tertiary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Quiz Already Completed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You\'ve already completed today\'s quiz.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.quaternary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Come back tomorrow for a new quiz!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Questions review section
            const Text(
              'Today\'s Quiz Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lightest,
              ),
            ),
            const SizedBox(height: 12),
            
            // List of questions
            ...List.generate(
              widget.quiz.questions.length,
              (index) => Card(
                color: AppColors.darkGrey,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.quiz.questions[index].question,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.lightest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Return button
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Return to Learn Screen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.lightest,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionButton extends StatelessWidget {
  final String option;
  final int index;
  final bool isSelected;
  final bool? isCorrect;
  final bool? isIncorrect;
  final void Function(int)? onTap;
  
  const OptionButton({
    Key? key,
    required this.option,
    required this.index,
    required this.isSelected,
    this.isCorrect,
    this.isIncorrect,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData? trailingIcon;
    
    if (isCorrect == true) {
      backgroundColor = Colors.green.withOpacity(0.3);
      textColor = Colors.green[300]!;
      trailingIcon = Icons.check_circle;
    } else if (isIncorrect == true) {
      backgroundColor = Colors.red.withOpacity(0.3);
      textColor = Colors.red[300]!;
      trailingIcon = Icons.cancel;
    } else if (isSelected) {
      backgroundColor = AppColors.primary.withOpacity(0.3);
      textColor = AppColors.lightest;
      trailingIcon = null;
    } else {
      backgroundColor = AppColors.darkGrey;
      textColor = AppColors.lightest;
      trailingIcon = null;
    }
    
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap != null ? () => onTap!(index) : null,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primary.withOpacity(0.3),
        highlightColor: AppColors.primary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  color: isCorrect == true ? Colors.green[300] : Colors.red[300],
                ),
            ],
          ),
        ),
      ),
    );
  }
} 