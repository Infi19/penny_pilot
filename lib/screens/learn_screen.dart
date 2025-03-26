import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial Literacy Hub', 
          style: TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, 
              size: 80, 
              color: AppColors.mediumGrey
            ),
            const SizedBox(height: 20),
            const Text(
              'Financial Literacy Hub Coming Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.lightest
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Learn everything about investing',
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