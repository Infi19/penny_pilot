import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/risk_profile_model.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';

class RiskProfileResultScreen extends StatelessWidget {
  final RiskProfile profile;
  
  const RiskProfileResultScreen({super.key, required this.profile});

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Your Risk Profile',
          style: TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkest,
        iconTheme: const IconThemeData(color: AppColors.lightest),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.assessment,
                      size: 60,
                      color: AppColors.lightest,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your Risk Tolerance: ${profile.riskLevel}',
                      style: const TextStyle(
                        color: AppColors.lightest,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Assessment completed on ${_formatDate(profile.assessmentDate)}',
                      style: const TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Description Section
              const Text(
                'What this means:',
                style: TextStyle(
                  color: AppColors.lightest,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  profile.description,
                  style: const TextStyle(
                    color: AppColors.lightest,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Recommendations Section
              const Text(
                'Recommendations:',
                style: TextStyle(
                  color: AppColors.lightest,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profile.recommendations.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.lightest,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profile.recommendations[index],
                            style: const TextStyle(
                              color: AppColors.lightest,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              
              // Continue button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightest,
                    foregroundColor: AppColors.darkest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Continue to Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 