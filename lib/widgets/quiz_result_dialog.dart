import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class QuizResultDialog extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final int score;
  
  const QuizResultDialog({
    Key? key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.score,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (correctAnswers / totalQuestions * 100).toInt();
    
    // Determine score color and message
    Color scoreColor;
    String message;
    
    if (percentage >= 80) {
      scoreColor = Colors.green;
      message = 'Excellent! You\'re becoming an investing expert!';
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
      message = 'Good job! Keep learning and improving!';
    } else {
      scoreColor = Colors.red;
      message = 'Keep practicing to improve your investment knowledge!';
    }
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 65,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            margin: const EdgeInsets.only(top: 45),
            decoration: BoxDecoration(
              color: AppColors.darkGrey,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Quiz Completed!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightest,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "$percentage%",
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Text(
                  "$correctAnswers/$totalQuestions correct",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightest,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "You earned $score points!",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.tertiary,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          "You've completed today's quiz! Return tomorrow for a new challenge.",
                          style: TextStyle(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.lightest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          color: AppColors.lightest,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: scoreColor,
              radius: 45,
              child: Icon(
                percentage >= 70 ? Icons.emoji_events : 
                percentage >= 40 ? Icons.thumb_up : Icons.thumb_up_off_alt,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 