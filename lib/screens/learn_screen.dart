import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import 'quiz_screen.dart';
import 'quiz_history_screen.dart';
import 'user_level_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final QuizService _quizService = QuizService();
  bool _isLoading = true;
  List<LeaderboardEntry> _leaderboardEntries = [];
  Map<String, dynamic> _userRank = {'position': 0, 'totalPoints': 0, 'totalUsers': 0};
  bool _quizCompleted = false;
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _checkForDailyUpdates();
    _checkQuizStatus();
  }
  
  Future<void> _checkForDailyUpdates() async {
    try {
      // First perform any needed daily updates
      await _quizService.performDailyUpdates();
      // Then load the leaderboard
      await _loadLeaderboardData();
    } catch (e) {
      _loadLeaderboardData(); // Still try to load leaderboard even if update fails
    }
  }
  
  Future<void> _loadLeaderboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get leaderboard data
      final leaderboard = await _quizService.getLeaderboard();
      final userRank = await _quizService.getUserLeaderboardInfo();
      
      setState(() {
        _leaderboardEntries = leaderboard;
        _userRank = userRank;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _refreshData() async {
    await _loadLeaderboardData();
    await _checkQuizStatus();
    if (mounted) {
      setState(() {
        _refreshCounter++; // Increment counter to force UI refresh
      });
    }
  }

  // Check if today's quiz is already completed
  Future<void> _checkQuizStatus() async {
    try {
      final hasCompleted = await _quizService.hasCompletedTodaysQuiz();
      if (mounted) {
        setState(() {
          _quizCompleted = hasCompleted;
        });
      }
    } catch (e) {
      print('Error checking quiz status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial Literacy Hub', 
          style: TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
                tooltip: 'Refresh Leaderboard',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Learn & Practice',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightest,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Daily Quiz Card
                  _buildDailyQuizCard(context),
                  const SizedBox(height: 24),
                  
                  // Leaderboard Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Top 3 Champions',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightest,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_outlined,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Your Rank: ${_userRank['position']}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : _buildLeaderboard(),
                  const SizedBox(height: 24),
                  
                  // Financial Topics Section
                  const Text(
                    'Financial Topics',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightest,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Coming soon placeholder cards
                  _buildComingSoonTopicCard(
                    context,
                    'Investing Basics',
                    'Learn the fundamentals of investing',
                    Icons.trending_up,
                  ),
                  const SizedBox(height: 12),
                  _buildComingSoonTopicCard(
                    context,
                    'Risk Management',
                    'Understanding and managing investment risks',
                    Icons.shield,
                  ),
                  const SizedBox(height: 12),
                  _buildComingSoonTopicCard(
                    context,
                    'Retirement Planning',
                    'Prepare for a secure retirement',
                    Icons.watch_later,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                color: AppColors.darkGrey,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: TextStyle(color: AppColors.lightest),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildLeaderboard() {
    if (_leaderboardEntries.isEmpty) {
      return Card(
        color: AppColors.darkGrey,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No quiz results yet! Be the first to take the quiz!',
              style: TextStyle(
                color: AppColors.lightest,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    
    return Card(
      color: AppColors.darkGrey,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Leaderboard header
            const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'Rank',
                    style: TextStyle(
                      color: AppColors.lightGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'User',
                    style: TextStyle(
                      color: AppColors.lightGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Points',
                    style: TextStyle(
                      color: AppColors.lightGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.mediumGrey),
            
            // Leaderboard entries - always show all entries (max 3)
            ...List.generate(
              _leaderboardEntries.length,
              (index) => _buildLeaderboardRow(index, _leaderboardEntries[index]),
            ),
            
            // Show your position if not in top 3 and user has taken quiz
            if (_userRank['position'] > 3 && _userRank['totalPoints'] > 0) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '...',
                  style: TextStyle(
                    color: AppColors.lightest,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              _buildUserRankRow(_userRank['position'], _userRank['totalPoints']),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildLeaderboardRow(int index, LeaderboardEntry entry) {
    final rank = index + 1;
    final isTopThree = rank <= 3;
    
    // Icons for top three positions
    IconData? rankIcon;
    Color rankColor = AppColors.lightest;
    
    if (rank == 1) {
      rankIcon = Icons.emoji_events;
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankIcon = Icons.emoji_events;
      rankColor = Colors.grey[400]!;
    } else if (rank == 3) {
      rankIcon = Icons.emoji_events;
      rankColor = Colors.orange[300]!;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Rank
          Expanded(
            flex: 1,
            child: Row(
              children: [
                if (isTopThree)
                  Icon(
                    rankIcon,
                    color: rankColor,
                    size: 16,
                  )
                else
                  Text(
                    '$rank',
                    style: const TextStyle(
                      color: AppColors.lightest,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          
          // User info
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  backgroundImage: entry.photoUrl != null ? NetworkImage(entry.photoUrl!) : null,
                  child: entry.photoUrl == null ? 
                    Text(
                      entry.displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.displayName,
                    style: const TextStyle(
                      color: AppColors.lightest,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Points
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.star,
                  color: isTopThree ? rankColor : AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.totalPoints}',
              style: TextStyle(
                    color: isTopThree ? rankColor : AppColors.lightest,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserRankRow(int rank, int points) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Rank
          Expanded(
            flex: 1,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          
          // User info
          const Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.person,
                    color: AppColors.darkest,
                    size: 14,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Points
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.star,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$points',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDailyQuizCard(BuildContext context) {
    return Card(
      color: AppColors.darkGrey,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _openDailyQuiz(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _quizCompleted 
                          ? AppColors.tertiary.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _quizCompleted ? Icons.check_circle : Icons.quiz,
                      color: _quizCompleted ? AppColors.tertiary : AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Investment Quiz',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lightest,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _quizCompleted 
                              ? 'Completed for today! Return tomorrow for new questions.'
                              : 'Test your knowledge and earn points!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.lightest.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          
          // Divider
          Divider(
            color: AppColors.darkest.withOpacity(0.5),
            height: 1,
          ),
          
          // User level settings button
          InkWell(
            onTap: () => _openUserLevelSettings(context),
            borderRadius: BorderRadius.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings,
                    color: AppColors.tertiary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
            const Text(
                    'Change Difficulty Level',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.tertiary,
                    ),
                  ),
                  const Spacer(),
                  FutureBuilder<UserLevel>(
                    key: ValueKey(_refreshCounter),
                    future: _quizService.getUserLevel(),
                    builder: (context, snapshot) {
                      String level = 'Beginner';
                      if (snapshot.hasData) {
                        level = _getLevelString(snapshot.data!);
                      }
                      return Text(
                        level,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.quaternary,
                        ),
                      );
                    },
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.quaternary,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
          
          // Debug: Regenerate Quiz Button
          if (false) // Set to false to hide in production
            InkWell(
              onTap: _regenerateQuiz,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.refresh,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'DEBUG: Regenerate Quiz',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          // Debug: Allow Multiple Quiz Submissions Button
          if (false) // Hidden in production
            InkWell(
              onTap: _allowMultipleSubmissions,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.repeat,
                      color: Colors.purple,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'DEBUG: Allow Multiple Submissions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _getLevelString(UserLevel level) {
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
  
  void _openUserLevelSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserLevelSettingsScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _refreshData(); // Refresh data when returning from settings
      }
    });
  }
  
  void _openDailyQuiz(BuildContext context) async {
    print('DEBUG: Opening daily quiz');
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // First check if the user has already completed a quiz today
      final hasCompleted = await _quizService.hasCompletedTodaysQuiz();
      if (hasCompleted) {
        if (mounted) {
          setState(() {
            _quizCompleted = true;
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already completed today\'s quiz. Come back tomorrow for a new quiz!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return; // Exit early - don't open the quiz screen
      }
    
      // Get the most up-to-date quiz - force refresh for best results
      final quiz = await _quizService.getTodaysQuiz(forceRefresh: true);
      
      if (quiz != null) {
        final userLevel = await _quizService.getUserLevel();
        print('DEBUG: Opening quiz with difficulty: ${userLevelToString(quiz.difficulty ?? UserLevel.beginner)}');
        print("DEBUG: User's current level: ${userLevelToString(userLevel)}");
        
        if (quiz.difficulty != userLevel) {
          print('DEBUG: WARNING - Quiz difficulty does not match user level');
        }
        
        // Store whether the quiz is completed
        setState(() {
          _quizCompleted = quiz.isCompleted;
        });
        
        // Navigate to the quiz screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(quiz: quiz),
          ),
        ).then((_) => _refreshData()); // Refresh data after quiz completion
      } else {
        // Show error if no quiz is available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No quiz available for today. Try again later.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error opening quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quiz: $e'),
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
  
  // Debug method to regenerate the daily quiz
  Future<void> _regenerateQuiz() async {
    // Show loading state
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('DEBUG: Starting quiz regeneration process');
      
      // Show a snackbar to indicate the process has started
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Regenerating quiz... This may take a moment.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 5), // Longer duration to avoid confusion
          ),
        );
      }
      
      // Clear all quiz-related caches first
      try {
        // 1. Clear shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_daily_quiz');
        print('DEBUG: Cleared quiz cache in SharedPreferences');
        
        // 2. Clear any session state in Firestore if applicable
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // This is a simplified example - adjust based on your database structure
          final FirebaseFirestore firestore = FirebaseFirestore.instance;
          await firestore.collection('users').doc(user.uid).update({
            'lastQuizTimestamp': FieldValue.delete(),
          }).catchError((e) {
            // Ignore errors as this is just a cleanup step
            print('DEBUG: Error clearing Firestore quiz state: $e');
          });
        }
      } catch (e) {
        // Continue even if cache clearing fails
        print('DEBUG: Error during cache clearing: $e');
      }
      
      // Generate new daily quizzes for all difficulty levels
      await _quizService.generateNewDailyQuizForAllUsers();
      
      print('DEBUG: Quiz generation completed, refreshing data');
      
      // Force app to fully refresh quiz data
      await _refreshData();
      await _checkQuizStatus();
      
      // Wait a moment to ensure Firebase has updated
      await Future.delayed(const Duration(seconds: 1));
      
      // Get the newly generated quiz to verify it worked
      final userLevel = await _quizService.getUserLevel();
      final newQuiz = await _quizService.getTodaysQuiz(forceRefresh: true);
      
      if (newQuiz != null) {
        print('DEBUG: New quiz loaded - difficulty: ${userLevelToString(newQuiz.difficulty ?? UserLevel.beginner)}');
        print('DEBUG: New quiz has ${newQuiz.questions.length} questions');
        // Print a few words from the first question to check if it's different
        print('DEBUG: First question: "${newQuiz.questions[0].question}"');
        print('DEBUG: User level is: ${userLevelToString(userLevel)}');
        
        // Verify the difficulty matches what we expect
        if (newQuiz.difficulty != userLevel) {
          print('DEBUG: WARNING - Quiz difficulty (${userLevelToString(newQuiz.difficulty ?? UserLevel.beginner)}) does not match user level (${userLevelToString(userLevel)})');
        }
        
        // Immediately open the new quiz to confirm it's been regenerated
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quiz regenerated successfully! Opening new quiz...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Short delay before opening the quiz
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Open the new quiz automatically
          _openDailyQuiz(context);
          return; // Exit early as we're already showing the quiz
        }
      } else {
        print('DEBUG: Failed to load new quiz after regeneration');
      }
      
      // Show success message if we didn't open the quiz
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz regenerated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error regenerating quiz: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error regenerating quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Debug method to allow multiple quiz submissions
  Future<void> _allowMultipleSubmissions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('DEBUG: Enabling multiple quiz submissions');
      
      // Show a snackbar to indicate the process has started
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enabling multiple quiz submissions...'),
            backgroundColor: Colors.purple,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Clear today's date from quiz results
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        print('DEBUG: Clearing quiz results for date: $formattedDate');
        
        // Delete today's quiz results from Firestore
        final resultsQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('quizResults')
            .where('date', isEqualTo: formattedDate)
            .get();
            
        // Batch delete all matching results
        final batch = FirebaseFirestore.instance.batch();
        int count = 0;
        for (var doc in resultsQuery.docs) {
          batch.delete(doc.reference);
          count++;
        }
        
        if (count > 0) {
          await batch.commit();
          print('DEBUG: Deleted $count quiz results for today');
        } else {
          print('DEBUG: No quiz results found for today');
        }
        
        // Also clear the quiz completion flag in shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('quiz_completed_$formattedDate');
        print('DEBUG: Cleared quiz completion flag in SharedPreferences');
        
        // Reset the local quiz completion status
        setState(() {
          _quizCompleted = false;
        });
        
        // Refresh data to update UI
        await _refreshData();
        
        // Success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can now take the quiz multiple times!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('DEBUG: User not logged in');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error enabling multiple submissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
  
  Widget _buildComingSoonTopicCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.mediumGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.lightGrey,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.lightGrey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.mediumGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Coming Soon',
              style: TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 