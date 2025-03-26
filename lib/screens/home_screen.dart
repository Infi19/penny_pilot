import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'ai_assistant_screen.dart';
import 'learn_screen.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

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

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

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
                          )
                          ,
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
                  const Text(
                    'Your Investment Profile',
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
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Risk Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.lightest,
                                ),
                              ),
                              Text(
                                'Moderate',
                                style: TextStyle(
                                  color: AppColors.mediumGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: 0.5,
                            backgroundColor: AppColors.darkest,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mediumGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Financial Literacy Hub
                  const Text(
                    'Financial Literacy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightest,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 150,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildEducationCard(
                          'Basics of Investing',
                          'Learn the fundamentals of investment',
                          Icons.school,
                        ),
                        _buildEducationCard(
                          'Market Analysis',
                          'Understanding market trends',
                          Icons.trending_up,
                        ),
                        _buildEducationCard(
                          'Risk Management',
                          'Strategies to manage risk',
                          Icons.security,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Market Trends Section
                  const Text(
                    'Market Insights',
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
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.trending_up, color: AppColors.mediumGrey),
                              SizedBox(width: 10),
                              Text(
                                'Today\'s Trend',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.lightest,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Markets showing positive momentum with technology sector leading gains.',
                            style: const TextStyle(
                              color: AppColors.lightGrey,
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
        ),
      ),
    );
  }

  Widget _buildEducationCard(String title, String subtitle, IconData icon) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 15),
      child: Card(
        color: AppColors.darkGrey,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.mediumGrey),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.lightest,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}