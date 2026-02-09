import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/launch_screen.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/gemini_service.dart';
import 'services/personalized_advice_service.dart';
import 'services/quiz_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    // Use appropriate providers based on environment
    androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
    appleProvider: kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
  );

  // Initialize services
  await initServices();
  
  runApp(const MyApp());
}

Future<void> initServices() async {
  // Initialize shared preferences
  await SharedPreferences.getInstance();
  
  // Pre-initialize singletons for faster app startup
  final geminiService = GeminiService(); // This initializes the GeminiService singleton
  await geminiService.loadCustomApiKey(); // Load custom key if available
  final quizService = QuizService(); // Initialize quiz service
  
  // Always check for daily quiz updates to ensure fresh content every day
  quizService.performDailyUpdates().catchError((e) {
    // Silently handle any errors during daily quiz update
    print('Error performing daily quiz update: $e');
  });
  
  // If user is logged in, prefetch additional personalized data
  if (FirebaseAuth.instance.currentUser != null) {
    try {
      final personalizedAdviceService = PersonalizedAdviceService();
      // Prefetch user context in background
      personalizedAdviceService.getUserFinancialContext();
    } catch (e) {
      print('Error pre-initializing services: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<QuizService>(
          create: (_) => QuizService(),
        ),
      ],
      child: MaterialApp(
        title: 'Penny Pilot',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4b0082)),
          useMaterial3: true,
        ),
        home: StreamBuilder<User?>(
          stream: AuthService().authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            
            if (snapshot.hasData) {
              return const HomeScreen();
            }
            
            return const LaunchScreen();
          },
        ),
      ),
    );
  }
}
