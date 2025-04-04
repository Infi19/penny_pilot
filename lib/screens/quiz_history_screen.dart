import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../utils/app_colors.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  final QuizService _quizService = QuizService();
  List<QuizResult> _quizHistory = [];
  bool _isLoading = true;
  int _totalPoints = 0;
  
  // Sorting state
  String _sortBy = 'date'; // 'date', 'score', 'points'
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _loadQuizHistory();
  }

  Future<void> _loadQuizHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _quizService.getQuizHistory();
      int total = 0;
      for (var result in history) {
        total += result.points;
      }
      
      setState(() {
        _quizHistory = history;
        _sortHistory(); // Apply sorting
        _totalPoints = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Sort the quiz history based on current sort settings
  void _sortHistory() {
    if (_sortBy == 'date') {
      _quizHistory.sort((a, b) => _sortDescending 
          ? b.date.compareTo(a.date) 
          : a.date.compareTo(b.date));
    } else if (_sortBy == 'score') {
      _quizHistory.sort((a, b) {
        double aPercent = a.score / a.totalQuestions;
        double bPercent = b.score / b.totalQuestions;
        return _sortDescending 
            ? bPercent.compareTo(aPercent) 
            : aPercent.compareTo(bPercent);
      });
    } else if (_sortBy == 'points') {
      _quizHistory.sort((a, b) => _sortDescending 
          ? b.points.compareTo(a.points) 
          : a.points.compareTo(b.points));
    }
  }
  
  // Change the sort option
  void _changeSortOption(String sortBy) {
    setState(() {
      // If selecting the same sort option, toggle direction
      if (_sortBy == sortBy) {
        _sortDescending = !_sortDescending;
      } else {
        _sortBy = sortBy;
        _sortDescending = true; // Default to descending for new sort option
      }
      _sortHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quiz History',
          style: TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
        actions: [
          // Sort options dropdown
          if (!_isLoading && _quizHistory.isNotEmpty)
            PopupMenuButton<String>(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.sort, color: AppColors.lightest),
                  Positioned(
                    bottom: 10,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onSelected: _changeSortOption,
              tooltip: 'Sort quizzes',
              color: AppColors.darkGrey,
              itemBuilder: (BuildContext context) => [
                _buildSortMenuItem('date', 'Date'),
                _buildSortMenuItem('score', 'Score'),
                _buildSortMenuItem('points', 'Points'),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.lightest,
              ),
            )
          : _quizHistory.isEmpty
              ? _buildEmptyView()
              : _buildHistoryList(),
    );
  }
  
  PopupMenuItem<String> _buildSortMenuItem(String value, String text) {
    bool isSelected = _sortBy == value;
    
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.lightest,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Icon(
              _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
              color: AppColors.primary,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 80,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Quiz History Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.lightest,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Complete your first daily quiz to see your results and track your progress!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.lightGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Return to the Learn screen
              },
              icon: const Icon(Icons.quiz, color: Colors.black),
              label: const Text(
                'Take Today\'s Quiz',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    // Show which sorting is applied
    String sortText;
    switch (_sortBy) {
      case 'date':
        sortText = _sortDescending ? 'Newest first' : 'Oldest first';
        break;
      case 'score':
        sortText = _sortDescending ? 'Highest score first' : 'Lowest score first';
        break;
      case 'points':
        sortText = _sortDescending ? 'Most points first' : 'Least points first';
        break;
      default:
        sortText = '';
    }
    
    return Column(
      children: [
        // Points summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Points Earned',
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$_totalPoints',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'points from ${_quizHistory.length} quizzes',
                          style: const TextStyle(
                            color: AppColors.lightest,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Sorting indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.sort,
                color: AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Sorted by: $sortText',
                style: const TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        // History list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadQuizHistory,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _quizHistory.length,
              itemBuilder: (context, index) {
                final result = _quizHistory[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildHistoryCard(result),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(QuizResult result) {
    final score = result.score;
    final total = result.totalQuestions;
    final percentage = (score / total * 100).toStringAsFixed(0);
    
    // Format the date nicely
    final dateParts = result.date.split('-');
    final formattedDate = '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
    
    Color scoreColor;
    if (score / total >= 0.8) {
      scoreColor = Colors.green;
    } else if (score / total >= 0.5) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return GestureDetector(
      onTap: () => _viewQuizDetails(result),
      child: Card(
        color: AppColors.darkGrey,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withOpacity(0.2),
                  border: Border.all(color: scoreColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz on $formattedDate',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$score correct out of $total questions',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.lightGrey,
                          ),
                        ),
                        const Spacer(),
                        _buildDifficultyBadge(result.difficulty),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${result.points} points earned',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.primary,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(UserLevel difficulty) {
    Color badgeColor;
    String text;
    
    switch (difficulty) {
      case UserLevel.beginner:
        badgeColor = Colors.green;
        text = 'Beginner';
        break;
      case UserLevel.intermediate:
        badgeColor = Colors.orange;
        text = 'Intermediate';
        break;
      case UserLevel.advanced:
        badgeColor = Colors.red;
        text = 'Advanced';
        break;
      default:
        badgeColor = Colors.blue;
        text = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _viewQuizDetails(QuizResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          final dateParts = result.date.split('-');
          final formattedDate = '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
          
          return FutureBuilder<Map<String, dynamic>?>(
            future: _quizService.getQuizDetails(result.quizId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              
              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load quiz details',
                          style: TextStyle(
                            color: AppColors.lightest,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error?.toString() ?? 'Unknown error',
                          style: const TextStyle(
                            color: AppColors.lightGrey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final quizDetails = snapshot.data!;
              final List<dynamic> questionResults = quizDetails['questionResults'];
              
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.mediumGrey,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Quiz summary
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quiz Summary',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightest,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.lightGrey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildDifficultyBadge(result.difficulty),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Score
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Score',
                          '${(result.score / result.totalQuestions * 100).toStringAsFixed(0)}%',
                          Icons.score,
                        ),
                        _buildStatItem(
                          'Correct',
                          '${result.score}/${result.totalQuestions}',
                          Icons.check_circle,
                        ),
                        _buildStatItem(
                          'Points',
                          '${result.points}',
                          Icons.star,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  const Text(
                    'Questions & Answers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightest,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Question list
                  ...List.generate(
                    questionResults.length,
                    (index) => _buildQuestionCard(index + 1, questionResults[index]),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Close button
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildQuestionCard(int questionNumber, Map<String, dynamic> questionData) {
    final String question = questionData['question'];
    final List<dynamic> options = questionData['options'];
    final int correctAnswerIndex = questionData['correctAnswerIndex'];
    final int userAnswerIndex = questionData['userAnswerIndex'];
    final bool isCorrect = questionData['isCorrect'];
    final String explanation = questionData['explanation'];
    
    final Color resultColor = isCorrect ? Colors.green : Colors.red;
    final IconData resultIcon = isCorrect ? Icons.check_circle : Icons.cancel;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.darkest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$questionNumber',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightest,
                    ),
                  ),
                ),
                Icon(
                  resultIcon,
                  color: resultColor,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Options
            ...List.generate(
              options.length,
              (index) => _buildOptionItem(
                options[index], 
                index, 
                correctAnswerIndex, 
                userAnswerIndex,
              ),
            ),
            
            // Explanation
            if (explanation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mediumGrey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explanation:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      explanation,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.lightGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionItem(String option, int index, int correctIndex, int selectedIndex) {
    final bool isCorrect = index == correctIndex;
    final bool isSelected = index == selectedIndex;
    
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData? trailingIcon;
    
    if (isSelected && isCorrect) {
      // User selected and it's correct
      backgroundColor = Colors.green.withOpacity(0.2);
      borderColor = Colors.green;
      textColor = Colors.green;
      trailingIcon = Icons.check_circle;
    } else if (isSelected && !isCorrect) {
      // User selected but it's wrong
      backgroundColor = Colors.red.withOpacity(0.2);
      borderColor = Colors.red;
      textColor = Colors.red;
      trailingIcon = Icons.cancel;
    } else if (isCorrect) {
      // Correct answer (not selected)
      backgroundColor = Colors.transparent;
      borderColor = Colors.green.withOpacity(0.5);
      textColor = Colors.green;
      trailingIcon = Icons.check_circle_outline;
    } else {
      // Not selected, not correct
      backgroundColor = Colors.transparent;
      borderColor = AppColors.mediumGrey.withOpacity(0.3);
      textColor = AppColors.lightGrey;
      trailingIcon = null;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? borderColor : AppColors.lightGrey.withOpacity(0.5),
                ),
                color: isSelected ? borderColor.withOpacity(0.2) : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? borderColor : AppColors.lightGrey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected || isCorrect ? textColor : AppColors.lightest,
                ),
              ),
            ),
            if (trailingIcon != null)
              Icon(
                trailingIcon,
                color: textColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.lightest,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.lightGrey,
          ),
        ),
      ],
    );
  }
} 