import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserLevelSettingsScreen extends StatefulWidget {
  const UserLevelSettingsScreen({Key? key}) : super(key: key);

  @override
  _UserLevelSettingsScreenState createState() => _UserLevelSettingsScreenState();
}

class _UserLevelSettingsScreenState extends State<UserLevelSettingsScreen> {
  final QuizService _quizService = QuizService();
  UserLevel? _selectedLevel;
  bool _isLoading = true;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserLevel();
  }
  
  Future<void> _loadUserLevel() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final level = await _quizService.getUserLevel();
      setState(() {
        _selectedLevel = level;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user level: $e');
      setState(() {
        _selectedLevel = UserLevel.beginner;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveUserLevel() async {
    if (_selectedLevel == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      print('Attempting to save user level: ${userLevelToString(_selectedLevel!)}');
      // Use the QuizService to set the user level
      final success = await _quizService.setUserLevel(_selectedLevel!);
      
      if (success) {
        print('Successfully updated user level to: ${userLevelToString(_selectedLevel!)}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz difficulty level updated!'),
            backgroundColor: AppColors.tertiary,
          ),
        );
        
        // Pop back to previous screen
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to update user level');
      }
    } catch (e) {
      print('Error saving user level: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating level: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quiz Difficulty Settings',
          style: TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.lightest))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Quiz Difficulty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose the difficulty level for your daily quizzes. This will affect the types of questions you receive.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.quaternary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Beginner level card
                    _buildLevelCard(
                      title: 'Beginner',
                      description: 'Basic investment concepts, savings, mutual funds, banking products, and simple tax-saving options.',
                      icon: Icons.eco_outlined,
                      color: Colors.green,
                      level: UserLevel.beginner,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Intermediate level card
                    _buildLevelCard(
                      title: 'Intermediate',
                      description: 'SIPs, equity vs debt, asset allocation, tax implications, market indices, IPOs, and bonds.',
                      icon: Icons.trending_up,
                      color: Colors.orange,
                      level: UserLevel.intermediate,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Advanced level card
                    _buildLevelCard(
                      title: 'Advanced',
                      description: 'Options trading, futures, technical analysis, portfolio strategies, REITs, and debt market instruments.',
                      icon: Icons.insights,
                      color: Colors.red,
                      level: UserLevel.advanced,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveUserLevel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tertiary,
                          foregroundColor: AppColors.lightest,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.lightest,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Difficulty Level',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.lightest,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Note: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Your level will also automatically adjust over time based on your quiz performance.',
                                  ),
                                ],
                              ),
                            ),
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
  
  Widget _buildLevelCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required UserLevel level,
  }) {
    final isSelected = _selectedLevel == level;
    
    return Card(
      color: isSelected ? color.withOpacity(0.2) : AppColors.darkGrey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLevel = level;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : AppColors.lightest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? AppColors.lightest : AppColors.quaternary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 