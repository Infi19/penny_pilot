import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'profile_screen.dart';
import 'ai_assistant_screen.dart';
import 'learn_screen.dart';
import 'risk_assessment_screen.dart';
import 'goal_details_screen.dart';
import '../services/auth_service.dart';
import '../services/risk_profile_service.dart';
import '../utils/app_colors.dart';
import '../utils/risk_profile_model.dart';
import '../utils/financial_goal_model.dart';
import '../utils/financial_health_model.dart';
import '../services/financial_goals_service.dart';
import '../services/financial_health_service.dart';
import 'goals_screen.dart';
import 'financial_health_screen.dart';
import '../services/user_service.dart';
import '../utils/currency_util.dart';
import 'financial_health_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  final List<Widget> _screens = [
    const HomeContent(),
    const AIAssistantScreen(),
    const LearnScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.darkGrey,
        selectedItemColor: AppColors.lightest,
        unselectedItemColor: AppColors.lightGrey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'AI Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final RiskProfileService _riskService = RiskProfileService();
  final FinancialGoalsService _goalsService = FinancialGoalsService();
  final FinancialHealthService _healthService = FinancialHealthService();
  final UserService _userService = UserService();
  RiskProfile? _userRiskProfile;
  List<FinancialGoal> _userGoals = [];
  FinancialHealthScore? _healthScore;
  bool _isLoading = true;
  String _currencyCode = CurrencyUtil.getDefaultCurrencyCode();
  String _currencySymbol = CurrencyUtil.getDefaultCurrency().symbol;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final profile = await _riskService.getRiskProfile(user.uid);
        final goals = await _goalsService.getUserGoals();
        final healthScore = await _healthService.getLatestHealthScore();
        
        // Load user currency preference
        final userData = await _userService.getUserProfile(user.uid);
        String currencyCode = CurrencyUtil.getDefaultCurrencyCode();
        String currencySymbol = CurrencyUtil.getDefaultCurrency().symbol;
        
        if (userData != null && userData['currency'] != null) {
          final currency = CurrencyUtil.getCurrencyData(userData['currency']);
          currencyCode = currency.code;
          currencySymbol = currency.symbol;
        }
        
        // Sort goals by days remaining in ascending order
        goals.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
        
        setState(() {
          _userRiskProfile = profile;
          _userGoals = goals;
          _healthScore = healthScore;
          _currencyCode = currencyCode;
          _currencySymbol = currencySymbol;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading user data: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToRiskAssessment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RiskAssessmentScreen(),
      ),
    ).then((_) {
      // Reload risk profile when returning from assessment
      _loadUserData();
    });
  }

  void _navigateToFinancialHealthScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FinancialHealthScreen(),
      ),
    ).then((_) {
      // Reload financial health score when returning from assessment
      _loadUserData();
    });
  }

  void _navigateToFinancialHealthResultScreen() {
    if (_healthScore != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FinancialHealthResultScreen(scoreId: _healthScore!.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Investor';

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: AppColors.darkest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.white,
                            size: 40,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Penny Pilot',
                            style: TextStyle(
                              color: AppColors.lightest,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.notifications, color: AppColors.lightest),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Hi $userName,',
                    style: const TextStyle(
                      color: AppColors.lightest,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "let's make smart investments today!",
                    style: TextStyle(
                      color: AppColors.lightGrey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Main Features Section
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chat with AI Assistant Card
                  Card(
                    color: AppColors.darkGrey,
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(Icons.chat, color: AppColors.lightest),
                      title: const Text(
                        'Chat with AI Assistant',
                        style: TextStyle(color: AppColors.lightest, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Get personalized investment advice',
                        style: TextStyle(color: AppColors.lightGrey),
                      ),
                      trailing: const Icon(Icons.arrow_forward, color: AppColors.lightest),
                      onTap: () {
                        // Navigate directly to AI Assistant screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AIAssistantScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Risk Profile & Recommendations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Investment Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightest,
                        ),
                      ),
                      _userRiskProfile != null
                        ? TextButton.icon(
                            onPressed: _navigateToRiskAssessment,
                            icon: const Icon(
                              Icons.refresh,
                              color: AppColors.mediumGrey,
                              size: 16,
                            ),
                            label: const Text(
                              'Reassess',
                              style: TextStyle(
                                color: AppColors.mediumGrey,
                              ),
                            ),
                          )
                        : Container(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.lightest,
                          ),
                        )
                      : _userRiskProfile == null
                          ? _buildNoProfileCard()
                          : _buildRiskProfileCard(),
                  const SizedBox(height: 20),

                  // Financial Health Score Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Financial Health',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightest,
                        ),
                      ),
                      _healthScore != null
                          ? TextButton.icon(
                              onPressed: _navigateToFinancialHealthScreen,
                              icon: const Icon(
                                Icons.refresh,
                                color: AppColors.mediumGrey,
                                size: 16,
                              ),
                              label: const Text(
                                'Recalculate',
                                style: TextStyle(
                                  color: AppColors.mediumGrey,
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildFinancialHealthCard(),
                  const SizedBox(height: 20),

                  // Recommendations Section (only if profile exists)
                  if (_userRiskProfile != null) ...[
                    const Text(
                      'Recommended for You',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightest,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      color: AppColors.darkGrey,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (String recommendation in _userRiskProfile!.recommendations.take(2))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.lightbulb,
                                      color: AppColors.lightest,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        recommendation,
                                        style: const TextStyle(
                                          color: AppColors.lightest,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),
                            const Divider(color: AppColors.mediumGrey),
                            TextButton(
                              onPressed: () {
                                // Show all recommendations in detail view
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppColors.darkGrey,
                                    title: const Text(
                                      'All Recommendations',
                                      style: TextStyle(color: AppColors.lightest),
                                    ),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: _userRiskProfile!.recommendations.map((recommendation) => 
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 16.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.lightbulb,
                                                  color: AppColors.lightest,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    recommendation,
                                                    style: const TextStyle(
                                                      color: AppColors.lightest,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ).toList(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text(
                                          'Close',
                                          style: TextStyle(color: AppColors.lightest),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text(
                                'See All Recommendations',
                                style: TextStyle(color: AppColors.lightest),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Goals Section
            if (_userGoals.isNotEmpty) ...[
              Container(
                color: AppColors.background,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Financial Goals',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lightest,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const GoalsScreen(),
                              ),
                            ).then((_) => _loadUserData());
                          },
                          icon: const Icon(
                            Icons.add,
                            color: AppColors.mediumGrey,
                            size: 16,
                          ),
                          label: const Text(
                            'View All',
                            style: TextStyle(
                              color: AppColors.mediumGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Show only the top 1 goal with the nearest end date
                    _userGoals.isNotEmpty 
                      ? _buildGoalProgressCard(_userGoals.first)
                      : Container(),
                  ],
                ),
              ),
            ] else ...[
              Container(
                color: AppColors.background,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Goals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightest,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      color: AppColors.darkGrey,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.savings,
                              color: AppColors.lightest,
                              size: 40,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Set Your Financial Goals',
                              style: TextStyle(
                                color: AppColors.lightest,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Create financial goals to track your progress and stay motivated towards achieving your financial objectives.',
                              style: TextStyle(
                                color: AppColors.lightGrey,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const GoalsScreen(),
                                  ),
                                ).then((_) => _loadUserData());
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
                                'Create Goals',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildNoProfileCard() {
    return Card(
      color: AppColors.darkGrey,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.assessment,
              color: AppColors.lightest,
              size: 40,
            ),
            const SizedBox(height: 16),
            const Text(
              'Determine Your Risk Profile',
              style: TextStyle(
                color: AppColors.lightest,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Take a quick assessment to get personalized investment recommendations based on your risk tolerance.',
              style: TextStyle(
                color: AppColors.lightGrey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToRiskAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightest,
                foregroundColor: AppColors.darkest,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Start Assessment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskProfileCard() {
    return Card(
      color: AppColors.darkGrey,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Risk Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightest,
                  ),
                ),
                Text(
                  _userRiskProfile!.riskLevel,
                  style: const TextStyle(
                    color: AppColors.lightest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _getRiskLevelValue(),
              backgroundColor: AppColors.mediumGrey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_getRiskLevelColor()),
            ),
            const SizedBox(height: 15),
            Text(
              _userRiskProfile!.description,
              style: const TextStyle(
                color: AppColors.lightGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getRiskLevelValue() {
    switch (_userRiskProfile!.riskLevel) {
      case 'Conservative':
        return 0.1;
      case 'Moderately Conservative':
        return 0.3;
      case 'Moderate':
        return 0.5;
      case 'Moderately Aggressive':
        return 0.75;
      case 'Aggressive':
        return 0.95;
      default:
        return 0.5;
    }
  }

  Color _getRiskLevelColor() {
    switch (_userRiskProfile!.riskLevel) {
      case 'Conservative':
        return Colors.blue;
      case 'Moderately Conservative':
        return Colors.cyan;
      case 'Moderate':
        return Colors.green;
      case 'Moderately Aggressive':
        return Colors.orange;
      case 'Aggressive':
        return Colors.red;
      default:
        return AppColors.lightest;
    }
  }

  Widget _buildFinancialHealthCard() {
    if (_healthScore == null) {
      return Card(
        color: AppColors.darkGrey,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.health_and_safety,
                color: AppColors.lightest,
                size: 40,
              ),
              const SizedBox(height: 16),
              const Text(
                'Calculate Your Financial Health',
                style: TextStyle(
                  color: AppColors.lightest,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Get a comprehensive assessment of your financial well-being based on key financial metrics.',
                style: TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateToFinancialHealthScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightest,
                  foregroundColor: AppColors.darkest,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Calculate Now',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Color scoreColor;
    switch (_healthScore!.healthCategory) {
      case 'Excellent':
        scoreColor = Colors.green;
        break;
      case 'Good':
        scoreColor = Colors.yellow;
        break;
      case 'Moderate Risk':
        scoreColor = Colors.orange;
        break;
      case 'High Risk':
        scoreColor = Colors.red;
        break;
      default:
        scoreColor = Colors.grey;
    }

    return Card(
      color: AppColors.darkGrey,
      elevation: 4,
      child: InkWell(
        onTap: _navigateToFinancialHealthResultScreen,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Financial Health Score',
                    style: TextStyle(
                      color: AppColors.lightest,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _healthScore!.totalScore.toStringAsFixed(0),
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _healthScore!.totalScore / 100,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                minHeight: 10,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _healthScore!.healthCategory,
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Updated: ${DateFormat.yMMMd().format(_healthScore!.assessmentDate)}',
                    style: const TextStyle(
                      color: AppColors.lightGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_healthScore!.recommendations.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: AppColors.lightest,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _healthScore!.recommendations.first,
                        style: const TextStyle(
                          color: AppColors.lightest,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Tap to view detailed breakdown',
                  style: TextStyle(
                    color: AppColors.mediumGrey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalProgressCard(FinancialGoal goal) {
    final progressPercentage = goal.progressPercentage;
    final isCompleted = goal.isCompleted;
    
    return Card(
      color: AppColors.darkGrey,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GoalDetailsScreen(goal: goal),
            ),
          ).then((_) => _loadUserData());
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(goal.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(goal.category),
                      color: _getCategoryColor(goal.category),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Goal Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                            color: AppColors.lightest,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$_currencySymbol${goal.currentAmount.toStringAsFixed(0)} of $_currencySymbol${goal.targetAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.lightGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress Percentage
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.2)
                          : progressPercentage > 75
                              ? Colors.orange.withOpacity(0.2)
                              : AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${progressPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.green
                            : progressPercentage > 75
                                ? Colors.orange
                                : AppColors.mediumGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0),
                  backgroundColor: AppColors.darkest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? Colors.green
                        : progressPercentage > 75
                            ? Colors.orange
                            : AppColors.lightest,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              // Days remaining
              if (!isCompleted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.lightGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      goal.daysRemaining <= 0
                          ? 'Past due'
                          : goal.daysRemaining == 1
                              ? '1 day left'
                              : goal.daysRemaining < 30
                                  ? '${goal.daysRemaining} days left'
                                  : '${(goal.daysRemaining / 30).round()} months left',
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Savings':
        return Icons.savings;
      case 'Retirement':
        return Icons.beach_access;
      case 'Emergency Fund':
        return Icons.health_and_safety;
      case 'Home':
        return Icons.home;
      case 'Education':
        return Icons.school;
      case 'Travel':
        return Icons.flight;
      case 'Car':
        return Icons.directions_car;
      default:
        return Icons.attach_money;
    }
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Savings':
        return Colors.blue;
      case 'Retirement':
        return Colors.purple;
      case 'Emergency Fund':
        return Colors.red;
      case 'Home':
        return Colors.green;
      case 'Education':
        return Colors.orange;
      case 'Travel':
        return Colors.teal;
      case 'Car':
        return Colors.indigo;
      default:
        return AppColors.primary;
    }
  }
}