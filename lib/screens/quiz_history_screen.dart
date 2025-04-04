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
        _totalPoints = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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

  Widget _buildEmptyView() {
    return Center(
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
            'Complete your first daily quiz to see your history',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.lightGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
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

    return Card(
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
                  Text(
                    '$score correct out of $total questions',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.lightGrey,
                    ),
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
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.emoji_events,
              color: scoreColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
} 