import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'ai_assistant_screen.dart';
import 'learn_screen.dart';
import 'risk_assessment_screen.dart';
import '../services/auth_service.dart';
import '../services/risk_profile_service.dart';
import '../utils/app_colors.dart';
import '../utils/risk_profile_model.dart';

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
  RiskProfile? _userRiskProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiskProfile();
  }
  
  Future<void> _loadRiskProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final profile = await _riskService.getRiskProfile(user.uid);
        setState(() {
          _userRiskProfile = profile;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading risk profile: $e');
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
      _loadRiskProfile();
    });
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
                        // Navigate to AI Assistant screen
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
}