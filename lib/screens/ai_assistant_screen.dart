import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AIAssistantScreen extends StatelessWidget {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Assistant', 
          style: TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, 
              size: 80, 
              color: AppColors.mediumGrey
            ),
            const SizedBox(height: 20),
            const Text(
              'AI Assistant Coming Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.lightest
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Get personalized investment advice',
              style: TextStyle(
                color: AppColors.lightGrey
              ),
            ),
          ],
        ),
      ),
    );
  }
} 