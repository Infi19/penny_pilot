import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/quiz_model.dart';
import 'gemini_service.dart';

class QuizService {
  static final QuizService _instance = QuizService._internal();
  final GeminiService _geminiService = GeminiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  factory QuizService() {
    return _instance;
  }

  QuizService._internal();
  
  // Generate multiple quiz questions using Gemini AI based on user level
  Future<List<QuizQuestion>> generateMultipleQuestions(int count, UserLevel level, {bool forceRefresh = false}) async {
    List<QuizQuestion> questions = [];
    
    try {
      // Customize prompt based on user level
      String difficultyText = '';
      String topicsText = '';
      String difficultyString = userLevelToString(level);
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      print('DEBUG: Generating $count questions for difficulty level: $difficultyString ${forceRefresh ? "(forced refresh)" : ""}');
      
      switch (level) {
        case UserLevel.beginner:
          difficultyText = 'basic, introductory';
          topicsText = 'basics of stock market, mutual funds, fixed deposits, PPF, EPF, savings accounts, basic tax-saving investments, simple investment terminology';
          break;
        case UserLevel.intermediate:
          difficultyText = 'moderate difficulty';
          topicsText = 'SIPs, equity vs debt funds, index funds, tax implications of investments, asset allocation, NSE/BSE indices, IPOs, bonds, insurance as investment';
          break;
        case UserLevel.advanced:
          print('DEBUG: *** ADVANCED LEVEL QUESTIONS GENERATION ***');
          difficultyText = 'challenging, sophisticated';
          topicsText = 'options trading, futures, technical analysis, portfolio diversification strategies, international investments, REITs, INVITs, commodity trading, debt market instruments, hedging strategies';
          break;
      }
      
      // Generate a unique session ID to prevent caching
      final String sessionId = 'quiz_${difficultyString}_${timestamp}_${_uuid.v4()}';
      print('DEBUG: Using session ID for Gemini: $sessionId');
      
      if (level == UserLevel.advanced) {
        print('DEBUG: Advanced level will use this unique session: $sessionId');
      }
      
      // Prompt for the Gemini model to generate multiple quiz questions with Indian context
      final prompt = '''
Create $count completely new ${difficultyText} multiple-choice questions about investing concepts specific to Indian investors.
Format your response exactly as a JSON array with $count objects, each having these fields:
[
  {
    "question": "The question text here",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswerIndex": 0-3 (index of the correct answer),
    "explanation": "Explanation of why the answer is correct",
    "difficulty": "${difficultyString}"
  },
  // more questions...
]

The questions should teach users valuable concepts about investing in the Indian market context.
Cover topics like: ${topicsText}
Include India-specific elements like Indian market terminology, Indian tax laws, Indian investment vehicles (like PPF, NPS, etc.), and Indian market regulators (SEBI, RBI).
Use Indian companies, Indian indices (like Nifty, Sensex), and Indian financial institutions in examples.
Make sure each question has 4 options that are plausible but only one is correct.
Make the difficulty appropriate for a ${difficultyString} level investor.

IMPORTANT: Create completely new questions that are different from previous ones.
Current timestamp: $timestamp
Difficulty level: $difficultyString
Force refresh: ${forceRefresh ? "YES" : "NO"}
''';

      if (level == UserLevel.advanced) {
        print('DEBUG: Advanced level prompt prepared with timestamp: $timestamp');
      }
      
      // Get response from Gemini
      print('DEBUG: Sending request to Gemini service');
      final response = await _geminiService.sendMessage(sessionId, prompt);
      
      if (level == UserLevel.advanced) {
        print('DEBUG: Advanced level received Gemini response of length: ${response.length}');
        print('DEBUG: Response starts with: ${response.substring(0, math.min(100, response.length))}...');
      }
      
      // Extract the JSON from the response
      String jsonStr = response;
      
      // If the response contains other text, try to extract just the JSON part
      if (response.contains('[') && response.contains(']')) {
        final start = response.indexOf('[');
        final end = response.lastIndexOf(']') + 1;
        jsonStr = response.substring(start, end);
        
        if (level == UserLevel.advanced) {
          print('DEBUG: Advanced level JSON extracted, length: ${jsonStr.length}');
        }
      }
      
      // Parse JSON
      try {
        final List<dynamic> questionsData = json.decode(jsonStr);
        
        if (level == UserLevel.advanced) {
          print('DEBUG: Advanced level successfully parsed JSON with ${questionsData.length} questions');
        }
        
        // Create QuizQuestion objects
        for (var questionData in questionsData) {
          final question = QuizQuestion(
            id: _uuid.v4(),
            question: questionData['question'],
            options: List<String>.from(questionData['options']),
            correctAnswerIndex: questionData['correctAnswerIndex'],
            explanation: questionData['explanation'],
            difficulty: level, // Always use the level passed to this method
          );
          questions.add(question);
          print('DEBUG: Created question with difficulty: ${userLevelToString(question.difficulty)} - "${question.question.substring(0, math.min(30, question.question.length))}..."');
        }
      } catch (jsonError) {
        print('DEBUG: Error parsing JSON: $jsonError');
        if (level == UserLevel.advanced) {
          print('DEBUG: Advanced level JSON parsing failed: $jsonError');
          print('DEBUG: JSON string received: $jsonStr');
        }
        throw jsonError; // Rethrow to handle in fallback
      }
      
      // If we couldn't generate enough questions, add fallback questions
      if (questions.length < count) {
        print('DEBUG: Adding ${count - questions.length} fallback questions');
        if (level == UserLevel.advanced) {
          print('DEBUG: Using fallback questions for advanced level');
        }
        final fallbackQuestions = _getFallbackQuestions(count - questions.length, level);
        questions.addAll(fallbackQuestions);
      }
      
      if (level == UserLevel.advanced) {
        print('DEBUG: Final advanced questions count: ${questions.length}');
        questions.forEach((q) => print('DEBUG: Advanced question: "${q.question.substring(0, math.min(30, q.question.length))}..."'));
      }
      
      return questions.take(count).toList();
    } catch (e) {
      print('DEBUG: Error generating questions: $e');
      if (level == UserLevel.advanced) {
        print('DEBUG: ERROR IN ADVANCED LEVEL GENERATION: $e');
      }
      // Return fallback questions in case of error
      return _getFallbackQuestions(count, level);
    }
  }
  
  // Get fallback questions based on user level
  List<QuizQuestion> _getFallbackQuestions(int count, UserLevel level) {
    List<QuizQuestion> fallbackQuestions = [];
    
    // Beginner level questions
    if (level == UserLevel.beginner) {
      fallbackQuestions = [
        QuizQuestion(
          id: _uuid.v4(),
          question: "What is a Systematic Investment Plan (SIP) in India?",
          options: [
            "A monthly investment in mutual funds",
            "A government pension scheme",
            "A type of fixed deposit",
            "A stock market index"
          ],
          correctAnswerIndex: 0,
          explanation: "A Systematic Investment Plan (SIP) is a method of investing a fixed amount regularly (typically monthly) in mutual funds. It's popular in India for disciplined investing and allows investors to benefit from rupee-cost averaging.",
          difficulty: UserLevel.beginner,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "Which organization regulates the securities market in India?",
          options: [
            "RBI (Reserve Bank of India)",
            "SEBI (Securities and Exchange Board of India)",
            "IRDAI (Insurance Regulatory and Development Authority of India)",
            "PFRDA (Pension Fund Regulatory and Development Authority)"
          ],
          correctAnswerIndex: 1,
          explanation: "SEBI (Securities and Exchange Board of India) is the regulatory body for the securities and commodity market in India. It monitors and regulates all stock exchanges, mutual funds, and other market participants.",
          difficulty: UserLevel.beginner,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "What is the main index of the Bombay Stock Exchange (BSE)?",
          options: [
            "Nifty 50",
            "BSE 100",
            "Sensex",
            "BSE Midcap"
          ],
          correctAnswerIndex: 2,
          explanation: "Sensex (short for Sensitive Index) is the benchmark index of the BSE. It consists of 30 well-established and financially sound companies listed on the Bombay Stock Exchange representing various sectors.",
          difficulty: UserLevel.beginner,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "What is a PPF account in India?",
          options: [
            "Personal Property Fund",
            "Public Provident Fund",
            "Private Pension Fund",
            "Partial Payment Facility"
          ],
          correctAnswerIndex: 1,
          explanation: "Public Provident Fund (PPF) is a long-term savings scheme offered by the Indian government with tax benefits under Section 80C. It has a lock-in period of 15 years and provides interest rates that are revised quarterly.",
          difficulty: UserLevel.beginner,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "Which of the following is a tax-saving investment option in India?",
          options: [
            "Regular savings account",
            "Current account",
            "ELSS (Equity Linked Savings Scheme)",
            "Cryptocurrency"
          ],
          correctAnswerIndex: 2,
          explanation: "ELSS (Equity Linked Savings Scheme) is a type of mutual fund that invests primarily in equity and offers tax deductions up to ₹1.5 lakh under Section 80C of the Income Tax Act. It has the shortest lock-in period (3 years) among all tax-saving instruments.",
          difficulty: UserLevel.beginner,
        ),
      ];
    } 
    // Intermediate level questions
    else if (level == UserLevel.intermediate) {
      fallbackQuestions = [
        QuizQuestion(
          id: _uuid.v4(),
          question: "What is the maximum limit for tax deduction under Section 80C of the Income Tax Act in India?",
          options: [
            "₹1,00,000",
            "₹1,50,000",
            "₹2,00,000",
            "₹2,50,000"
          ],
          correctAnswerIndex: 1,
          explanation: "The maximum deduction allowed under Section 80C is ₹1,50,000 per financial year. Various investments like PPF, ELSS, tax-saving FDs, NSC, and insurance premiums qualify for this deduction.",
          difficulty: UserLevel.intermediate,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "Which type of mutual fund typically has the lowest expense ratio in India?",
          options: [
            "Actively managed equity funds",
            "Index funds",
            "Sector funds",
            "Balanced funds"
          ],
          correctAnswerIndex: 1,
          explanation: "Index funds typically have the lowest expense ratios because they follow a passive investment strategy of simply tracking a market index like Nifty or Sensex, requiring less research and fewer transactions compared to actively managed funds.",
          difficulty: UserLevel.intermediate,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "What is the 'Unified Payments Interface' (UPI) used for in India?",
          options: [
            "Stock trading",
            "Mutual fund investments",
            "Real-time payment system",
            "Tax filing"
          ],
          correctAnswerIndex: 2,
          explanation: "UPI (Unified Payments Interface) is a real-time payment system developed by the National Payments Corporation of India (NPCI) that enables instant money transfers between bank accounts using mobile devices. It's widely used for digital payments in India.",
          difficulty: UserLevel.intermediate,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "What is 'T+2' settlement cycle in Indian stock markets?",
          options: [
            "Trading happens 2 days before settlement",
            "The settlement occurs 2 days after the trading day",
            "Two trades can be settled together",
            "Trading is allowed for 2 days after purchase"
          ],
          correctAnswerIndex: 1,
          explanation: "In a T+2 settlement cycle, the settlement (delivery of shares and payment) occurs 2 business days after the trading day (T). This is the standard settlement cycle followed in Indian stock markets for equity shares.",
          difficulty: UserLevel.intermediate,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "What is the tax treatment of dividends from Indian stocks as per the current tax regime?",
          options: [
            "Tax-free in the hands of investors",
            "Taxed at a flat rate of 10%",
            "Taxed at the investor's income tax slab rate",
            "Exempt up to ₹10,000, then taxed at 10%"
          ],
          correctAnswerIndex: 2,
          explanation: "As per current tax laws in India, dividends received from Indian companies are taxable in the hands of investors at their applicable income tax slab rates. Earlier, dividends were tax-free up to a certain amount, but this was changed in the Finance Act 2020.",
          difficulty: UserLevel.intermediate,
        ),
      ];
    } 
    // Advanced level questions
    else {
      fallbackQuestions = [
        QuizQuestion(
          id: _uuid.v4(),
          question: "What is meant by 'Alpha' in the context of investment performance measurement in India?",
          options: [
            "The risk-free rate of return",
            "The excess return of an investment relative to its benchmark",
            "The volatility of a stock compared to the market",
            "The dividend yield of a stock"
          ],
          correctAnswerIndex: 1,
          explanation: "Alpha represents the excess return of an investment compared to its benchmark index. In the Indian context, a positive alpha indicates that a fund manager or investment has outperformed its benchmark (like Nifty or Sensex), providing returns above what would be expected based on the investment's risk level.",
          difficulty: UserLevel.advanced,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "Which of these is NOT a type of Alternative Investment Fund (AIF) category in India as per SEBI regulations?",
          options: [
            "Category I AIF",
            "Category II AIF",
            "Category III AIF",
            "Category IV AIF"
          ],
          correctAnswerIndex: 3,
          explanation: "SEBI regulations define only three categories of Alternative Investment Funds (AIFs) in India: Category I (venture capital, social impact funds), Category II (private equity, debt funds), and Category III (hedge funds, derivative strategies). There is no Category IV AIF in the Indian regulatory framework.",
          difficulty: UserLevel.advanced,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "In options trading on Indian exchanges, what is a 'Bull Call Spread'?",
          options: [
            "Buying a call option at one strike price and selling another at a higher strike price",
            "Buying multiple call options at different strike prices",
            "Selling a call option while holding the underlying stock",
            "Buying a call option while selling a put option at the same strike price"
          ],
          correctAnswerIndex: 0,
          explanation: "A Bull Call Spread in Indian options trading involves buying a call option at a specific strike price and simultaneously selling another call option at a higher strike price with the same expiration date. This strategy is used when traders expect a moderate rise in the underlying asset's price while limiting both potential profit and loss.",
          difficulty: UserLevel.advanced,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "What is the 'India VIX' index published by NSE?",
          options: [
            "An index tracking value investing stocks",
            "A volatility index that measures expected market volatility",
            "An index of infrastructure companies in India",
            "A benchmark for technology sector performance"
          ],
          correctAnswerIndex: 1,
          explanation: "India VIX is the volatility index calculated by NSE based on the order book of Nifty options. Similar to the VIX in the US markets, India VIX indicates the expected market volatility over the next 30 calendar days. Higher values suggest greater expected volatility, and it's often referred to as the 'fear gauge' of the Indian market.",
          difficulty: UserLevel.advanced,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: "Under the SEBI Insider Trading Regulations in India, what is the 'trading window'?",
          options: [
            "A special trading session for high-volume investors",
            "A period when employees of a company are permitted to trade in company securities",
            "A time frame for algorithmic trading only",
            "The hours during which the stock exchange operates"
          ],
          correctAnswerIndex: 1,
          explanation: "The 'trading window' refers to the period when designated persons (like directors, key managerial personnel, and other identified employees) are permitted to trade in their company's securities. The trading window is closed during periods when unpublished price sensitive information (UPSI) exists, particularly around financial results announcements, to prevent insider trading.",
          difficulty: UserLevel.advanced,
        ),
      ];
    }
    
    return fallbackQuestions.take(count).toList();
  }

  // Get the user's current level
  Future<UserLevel> getUserLevel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return UserLevel.beginner;
    
    try {
      // Get the user's profile
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) return UserLevel.beginner;
      
      final userData = userDoc.data()!;
      
      // Check if user level is explicitly set first
      if (userData.containsKey('userLevel')) {
        final userLevel = userData['userLevel'];
        return userLevelFromString(userLevel);
      }
      
      final quizStats = userData['quizStats'];
      
      // If no quiz stats, user is a beginner
      if (quizStats == null) return UserLevel.beginner;
      
      // Determine level based on total points and quizzes taken
      final totalPoints = quizStats['totalPoints'] ?? 0;
      final quizzesTaken = quizStats['quizzesTaken'] ?? 0;
      
      // Determine level based on points and quizzes
      if (totalPoints >= 300 && quizzesTaken >= 10) {
        return UserLevel.advanced;
      } else if (totalPoints >= 100 && quizzesTaken >= 5) {
        return UserLevel.intermediate;
      } else {
        return UserLevel.beginner;
      }
    } catch (e) {
      print('Error getting user level: $e');
      return UserLevel.beginner;
    }
  }
  
  // Update the user's level based on their quiz performance
  Future<void> updateUserLevel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Get current user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;
      
      final userData = userDoc.data()!;
      final quizStats = userData['quizStats'];
      
      // If no quiz stats, can't update level
      if (quizStats == null) return;
      
      // Calculate level based on performance
      final totalPoints = quizStats['totalPoints'] ?? 0;
      final quizzesTaken = quizStats['quizzesTaken'] ?? 0;
      final correctAnswers = quizStats['correctAnswers'] ?? 0;
      final totalQuestions = quizStats['totalQuestions'] ?? 0;
      
      UserLevel newLevel;
      
      // Determine new level based on stats
      if (totalPoints >= 300 && quizzesTaken >= 10 && totalQuestions > 0 && (correctAnswers / totalQuestions) >= 0.7) {
        newLevel = UserLevel.advanced;
      } else if (totalPoints >= 100 && quizzesTaken >= 5 && totalQuestions > 0 && (correctAnswers / totalQuestions) >= 0.6) {
        newLevel = UserLevel.intermediate;
      } else {
        newLevel = UserLevel.beginner;
      }
      
      // Update user level in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'userLevel': userLevelToString(newLevel),
      });
      
      // Also update leaderboard entry
      await _firestore.collection('leaderboard').doc(user.uid).update({
        'userLevel': userLevelToString(newLevel),
      });
    } catch (e) {
      print('Error updating user level: $e');
    }
  }

  // Create a new daily quiz with multiple questions
  Future<DailyQuiz> createDailyQuiz() async {
    // Get user's current level
    final userLevel = await getUserLevel();
    
    // Generate 5 questions based on user level
    final questions = await generateMultipleQuestions(5, userLevel);
    
    // Create a new quiz
    final quiz = DailyQuiz(
      id: _uuid.v4(),
      date: DateTime.now().toIso8601String(),
      questions: questions,
      difficulty: userLevel,
    );
    
    return quiz;
  }
  
  // Save a daily quiz to Firestore
  Future<void> saveDailyQuiz(DailyQuiz quiz) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Save in user's collection
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('dailyQuizzes')
        .doc(quiz.id)
        .set(quiz.toJson());
        
    // Also save in global quizzes collection for reference
    await _firestore
        .collection('quizzes')
        .doc(quiz.id)
        .set({
          ...quiz.toJson(),
          'availableFrom': DateTime.now().toIso8601String(),
        });
  }

  // Check if the user has already completed today's quiz
  Future<bool> hasCompletedTodaysQuiz() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    try {
      // Get today's date in yyyy-MM-dd format for exact comparison
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      print('DEBUG: Checking if user has completed a quiz for date: $today');
      
      // Query user's quiz results from today with exact date matching
      final resultsQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quizResults')
          .where('date', isEqualTo: today)  // Use exact equality for the date
          .limit(1)  // Only need one result to confirm completion
          .get();
      
      final hasCompleted = resultsQuery.docs.isNotEmpty;
      print('DEBUG: User has${hasCompleted ? '' : ' not'} completed a quiz today');
      
      // If any results are found for today, the user has completed the quiz
      return hasCompleted;
    } catch (e) {
      print('Error checking if quiz was completed today: $e');
      return false;
    }
  }

  // Get today's quiz for the current user
  Future<DailyQuiz?> getTodaysQuiz({bool forceRefresh = false}) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    print('DEBUG: Getting quiz for date: $formattedDate, forceRefresh: $forceRefresh');
    
    final UserLevel userLevel = await getUserLevel();
    print('DEBUG: User level: ${userLevelToString(userLevel)}');
    print('DEBUG: Searching for quiz with difficulty: ${userLevelToString(userLevel)} (enum value: ${userLevel.toString()})');
    
    // If not forcing a refresh, check if we have a cached quiz first
    if (!forceRefresh) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedQuizJson = prefs.getString('cached_daily_quiz');
        
        if (cachedQuizJson != null) {
          print('DEBUG: Found cached quiz, checking if applicable');
          final cachedQuiz = DailyQuiz.fromJson(jsonDecode(cachedQuizJson));
          
          // Check if the cached quiz is from today AND matches the user's level
          if (cachedQuiz.date.contains(formattedDate) && 
              cachedQuiz.difficulty == userLevel) {
            print('DEBUG: Using cached quiz with difficulty: ${userLevelToString(cachedQuiz.difficulty ?? UserLevel.beginner)}');
            return cachedQuiz;
          } else {
            print('DEBUG: Cached quiz is outdated or wrong difficulty, not using cache');
            print('DEBUG: Cached quiz date: ${cachedQuiz.date}, difficulty: ${userLevelToString(cachedQuiz.difficulty ?? UserLevel.beginner)}');
          }
        }
      } catch (e) {
        print('DEBUG: Error accessing cached quiz: $e');
        // Continue to fetch from Firestore if cache access fails
      }
    } else {
      print('DEBUG: Force refresh requested, skipping cache check');
    }
    
    try {
      final difficultyString = userLevelToString(userLevel);
      print('DEBUG: Querying Firestore for today\'s quiz with difficulty: $difficultyString');
      
      // Query for quizzes marked as daily with the proper difficulty level
      final QuerySnapshot querySnapshot = await _firestore
          .collection('quizzes')
          .where('isDaily', isEqualTo: true)
          .where('difficulty', isEqualTo: difficultyString)
          .get();
      
      print('DEBUG: Found ${querySnapshot.docs.length} quizzes for level $difficultyString');
      
      // For debugging, get all daily quizzes to see what's available
      if (userLevel == UserLevel.advanced) {
        final allDaily = await _firestore
            .collection('quizzes')
            .where('isDaily', isEqualTo: true)
            .get();
            
        print('DEBUG: ADVANCED DEBUG - There are ${allDaily.docs.length} total daily quizzes');
        for (var doc in allDaily.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('DEBUG: ADVANCED DEBUG - Quiz found: id=${data['id']}, difficulty=${data['difficulty']}');
        }
      }
      
      if (querySnapshot.docs.isNotEmpty) {
        // Sort by newest if multiple are found
        final sortedDocs = querySnapshot.docs.toList()
          ..sort((a, b) {
            final aDate = a['generatedAt'] ?? '';
            final bDate = b['generatedAt'] ?? '';
            return bDate.compareTo(aDate); // Newest first
          });

        // Log all found quizzes for debugging
        sortedDocs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          print('DEBUG: Found quiz - id: ${data['id']}, difficulty: ${data['difficulty']}, generatedAt: ${data['generatedAt'] ?? 'unknown'}');
        });
        
        // Use the newest one
        final latestDoc = sortedDocs.first;
        final data = latestDoc.data() as Map<String, dynamic>;
        
        // Check the questions array to detect issues
        final List<dynamic> questions = data['questions'] ?? [];
        print('DEBUG: Selected quiz has ${questions.length} questions');
        
        if (questions.isNotEmpty) {
          // Print a part of the first question for debugging
          final firstQuestion = questions[0]['question'] ?? 'No question text';
          print('DEBUG: First question: "${firstQuestion.substring(0, math.min(30, firstQuestion.length))}..."');
        }
        
        final quiz = DailyQuiz.fromJson({
          'id': data['id'],
          'date': data['date'],
          'questions': data['questions'],
          'difficulty': data['difficulty'],
        });
        
        print('DEBUG: Successfully loaded quiz from Firestore with difficulty: ${userLevelToString(quiz.difficulty ?? UserLevel.beginner)}');
        
        // Cache this quiz for future use
        if (!forceRefresh) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_daily_quiz', jsonEncode(quiz.toJson()));
            print('DEBUG: Cached quiz for future use');
          } catch (e) {
            print('DEBUG: Error caching quiz: $e');
            // Continue even if caching fails
          }
        } else {
          print('DEBUG: Skipping cache update due to force refresh');
        }
        
        return quiz;
      } else {
        print('DEBUG: No daily quiz found for level $difficultyString');
        
        // As a fallback, check for any daily quiz if none found for this level
        final fallbackQuery = await _firestore
            .collection('quizzes')
            .where('isDaily', isEqualTo: true)
            .get();
        
        if (fallbackQuery.docs.isNotEmpty) {
          print('DEBUG: Found ${fallbackQuery.docs.length} quizzes from other levels as fallback');
          
          // Try to find one that matches our level first, or use the newest one
          var selectedDoc = fallbackQuery.docs.firstWhere(
            (doc) => (doc.data() as Map<String, dynamic>)['difficulty'] == difficultyString,
            orElse: () => fallbackQuery.docs.first
          );
          
          final data = selectedDoc.data() as Map<String, dynamic>;
          print('DEBUG: Using fallback quiz with difficulty: ${data['difficulty']}');
          
          final quiz = DailyQuiz.fromJson({
            'id': data['id'],
            'date': data['date'],
            'questions': data['questions'],
            'difficulty': data['difficulty'],
          });
          
          return quiz;
        }
        
        print('DEBUG: No daily quizzes found at all, will attempt to generate new ones');
        
        // Generate a new quiz set if we couldn't find any daily quizzes
        try {
          print('DEBUG: Generating new quiz set as fallback');
          await generateNewDailyQuizForAllUsers();
          
          // Try fetching again after generation
          return getTodaysQuiz(forceRefresh: true);
        } catch (genError) {
          print('DEBUG: Error generating new quizzes: $genError');
          return null;
        }
      }
    } catch (e) {
      print('DEBUG: Error fetching quiz from Firestore: $e');
      return null;
    }
  }

  // Submit user's answers and calculate score
  Future<Map<String, dynamic>> submitQuizAnswers(String quizId, List<int?> userAnswers) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'success': false, 'message': 'User not logged in'};
    
    // Get the quiz
    final docSnap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('dailyQuizzes')
        .doc(quizId)
        .get();
    
    if (!docSnap.exists) {
      return {'success': false, 'message': 'Quiz not found'};
    }
    
    // Parse the quiz
    final quiz = DailyQuiz.fromJson(docSnap.data()!);
    
    // If quiz is already completed, return existing results
    if (quiz.isCompleted) {
      return {
        'success': true,
        'alreadyCompleted': true,
        'score': quiz.userScore,
        'totalQuestions': quiz.questions.length,
        'points': _calculatePoints(quiz.userScore ?? 0, quiz.questions.length),
        'totalPoints': quiz.totalPoints,
      };
    }
    
    // Calculate score
    int correctAnswers = 0;
    List<bool> results = [];
    
    for (int i = 0; i < quiz.questions.length; i++) {
      if (i < userAnswers.length && userAnswers[i] != null) {
        final isCorrect = userAnswers[i] == quiz.questions[i].correctAnswerIndex;
        results.add(isCorrect);
        if (isCorrect) correctAnswers++;
      } else {
        results.add(false);
      }
    }
    
    // Calculate points (10 points per correct answer)
    final earnedPoints = _calculatePoints(correctAnswers, quiz.questions.length);
    
    // Update the quiz as completed
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('dailyQuizzes')
        .doc(quizId)
        .update({
          'isCompleted': true,
          'userScore': correctAnswers,
          'userAnswers': userAnswers,
          'results': results,
          'points': earnedPoints,
        });
    
    // Update user quiz stats and leaderboard
    await _updateUserStats(correctAnswers, quiz.questions.length, earnedPoints);
    
    return {
      'success': true,
      'score': correctAnswers,
      'totalQuestions': quiz.questions.length,
      'results': results,
      'points': earnedPoints,
      'totalPoints': quiz.totalPoints,
    };
  }
  
  // Calculate points from the score
  int _calculatePoints(int score, int totalQuestions) {
    // 10 points per correct answer
    return score * 10;
  }

  // Update user's quiz statistics and leaderboard position
  Future<void> _updateUserStats(int score, int totalQuestions, int points) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final userDoc = _firestore.collection('users').doc(user.uid);
    
    // Update in a transaction to avoid race conditions
    await _firestore.runTransaction((transaction) async {
      // Get current user data
      final userSnap = await transaction.get(userDoc);
      final userData = userSnap.data() ?? {};
      
      // Get current quiz stats or create new ones
      final quizStats = userData['quizStats'] ?? {
        'totalQuestions': 0,
        'correctAnswers': 0,
        'quizzesTaken': 0,
        'totalPoints': 0,
      };
      
      // Update stats
      quizStats['totalQuestions'] = (quizStats['totalQuestions'] ?? 0) + totalQuestions;
      quizStats['correctAnswers'] = (quizStats['correctAnswers'] ?? 0) + score;
      quizStats['quizzesTaken'] = (quizStats['quizzesTaken'] ?? 0) + 1;
      quizStats['totalPoints'] = (quizStats['totalPoints'] ?? 0) + points;
      
      // Update user document
      transaction.set(userDoc, {
        ...userData,
        'quizStats': quizStats,
      }, SetOptions(merge: true));
      
      // Update leaderboard entry
      final leaderboardRef = _firestore.collection('leaderboard').doc(user.uid);
      final leaderboardEntry = LeaderboardEntry(
        userId: user.uid,
        displayName: user.displayName ?? 'Anonymous User',
        photoUrl: user.photoURL,
        totalPoints: quizStats['totalPoints'],
        quizzesTaken: quizStats['quizzesTaken'],
      );
      
      transaction.set(leaderboardRef, leaderboardEntry.toJson());
    });
  }

  // Get quiz history for the current user
  Future<List<QuizResult>> getQuizHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    
    final querySnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('dailyQuizzes')
        .where('isCompleted', isEqualTo: true)
        .orderBy('date', descending: true)
        .get();
    
    List<QuizResult> results = [];
    
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final quizId = data['id'] ?? '';
      final date = data['date'].toString().split('T')[0];
      final score = data['userScore'] ?? 0;
      final totalQuestions = (data['questions'] as List).length;
      final points = data['points'] ?? _calculatePoints(score, totalQuestions);
      final totalPoints = data['totalPoints'] ?? 50;
      final userAnswers = data['userAnswers'] != null ? List<int>.from(data['userAnswers']) : <int>[];
      final correctAnswers = score; // Correct answers equals the score/10
      
      results.add(QuizResult(
        quizId: quizId,
        date: date,
        score: score,
        totalQuestions: totalQuestions,
        points: points,
        totalPoints: totalPoints,
        userAnswers: userAnswers,
        correctAnswers: correctAnswers,
      ));
    }
    
    return results;
  }
  
  // Get the user's current leaderboard position and total points
  Future<Map<String, dynamic>> getUserLeaderboardInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'position': 0, 'totalPoints': 0, 'totalUsers': 0};
    
    // Get the user's leaderboard entry
    final userEntry = await _firestore.collection('leaderboard').doc(user.uid).get();
    
    if (!userEntry.exists) {
      return {'position': 0, 'totalPoints': 0, 'totalUsers': 0};
    }
    
    final totalPoints = userEntry.data()?['totalPoints'] ?? 0;
    
    // Count how many users have more points
    final aboveQuery = await _firestore
        .collection('leaderboard')
        .where('totalPoints', isGreaterThan: totalPoints)
        .count()
        .get();
        
    // Get total number of users in leaderboard
    final totalQuery = await _firestore
        .collection('leaderboard')
        .count()
        .get();
    
    // Calculate position (1-based index)
    final position = (aboveQuery.count ?? 0) + 1;
    final totalUsers = totalQuery.count ?? 0;
    
    return {
      'position': position,
      'totalPoints': totalPoints,
      'totalUsers': totalUsers,
    };
  }
  
  // Get the top leaderboard entries
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 3}) async {
    final snapshot = await _firestore
        .collection('leaderboard')
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .get();
        
    return snapshot.docs
        .map((doc) => LeaderboardEntry.fromJson(doc.data()))
        .toList();
  }
  
  // Update the leaderboard daily by clearing old entries
  Future<void> refreshLeaderboard() async {
    // This would typically be called by a Cloud Function or cron job
    // For now, we'll implement the logic for manual refreshing
    
    // Get all leaderboard entries
    final snapshot = await _firestore.collection('leaderboard').get();
    
    // Update each entry with the latest stats from user data
    for (final doc in snapshot.docs) {
      final userId = doc.id;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        final quizStats = userData['quizStats'] ?? {};
        
        // Update leaderboard entry
        await _firestore.collection('leaderboard').doc(userId).update({
          'totalPoints': quizStats['totalPoints'] ?? 0,
          'quizzesTaken': quizStats['quizzesTaken'] ?? 0,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }
    }
  }
  
  // Generate a new daily quiz for all users
  Future<void> generateNewDailyQuizForAllUsers() async {
    try {
      print('DEBUG: Generating new daily quizzes for all difficulty levels');
      // We'll create three quizzes, one for each difficulty level
      List<UserLevel> levels = [UserLevel.beginner, UserLevel.intermediate, UserLevel.advanced];
      final String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // First, mark all existing daily quizzes as not daily
      try {
        print('DEBUG: Updating previous daily quizzes to not be daily');
        final allQuizzes = await _firestore.collection('quizzes').get();
        
        int updatedCount = 0;
        for (var doc in allQuizzes.docs) {
          final quizData = doc.data();
          if (quizData['isDaily'] == true) {
            await doc.reference.update({'isDaily': false});
            print('DEBUG: Updated quiz ${quizData['id']} to not be daily');
            updatedCount++;
          }
        }
        print('DEBUG: Updated $updatedCount existing quizzes to not be daily');
      } catch (e) {
        print('DEBUG: Error updating previous daily quizzes: $e');
        // Continue with quiz generation even if updating fails
      }
      
      // Clear shared preferences cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_daily_quiz');
        print('DEBUG: Cleared quiz cache in SharedPreferences');
      } catch (e) {
        print('DEBUG: Error clearing SharedPreferences cache: $e');
      }
      
      // Clear Gemini cache by resetting the session
      try {
        _geminiService.resetSession('quiz');
        print('DEBUG: Reset Gemini session for quiz');
      } catch (e) {
        print('DEBUG: Error resetting Gemini session: $e');
      }
      
      print('DEBUG: Beginning quiz generation for all difficulty levels');
      
      // Additional reset to force new sessions
      for (var level in levels) {
        try {
          final sessionId = 'quiz_${userLevelToString(level)}';
          _geminiService.resetSession(sessionId);
          print('DEBUG: Reset session for ${userLevelToString(level)}');
        } catch (e) {
          print('DEBUG: Error resetting specific level session: $e');
        }
      }
      
      // For each level, create and save a quiz - handle advanced specifically
      for (var level in levels) {
        print('DEBUG: Starting generation for level: ${userLevelToString(level)} (${level.toString()})');
        
        try {
          // Generate 5 questions for this difficulty level with forced refresh
          print('DEBUG: About to generate questions for ${userLevelToString(level)}');
          
          List<QuizQuestion> questions = [];
          
          // Retry logic for advanced level
          if (level == UserLevel.advanced) {
            // Specific handling for advanced level which seems to have issues
            print('DEBUG: Advanced level - using special handling');
            try {
              questions = await generateMultipleQuestions(5, level, forceRefresh: true);
              print('DEBUG: Advanced level - initial generation result: ${questions.length} questions');
            } catch (firstAttemptError) {
              print('DEBUG: Advanced level - first attempt failed: $firstAttemptError');
              print('DEBUG: Advanced level - retrying with additional parameters');
              
              // Wait a moment between attempts
              await Future.delayed(const Duration(seconds: 1));
              
              // Try again with explicit unique session
              try {
                final uniqueSessionId = 'quiz_advanced_retry_${DateTime.now().millisecondsSinceEpoch}';
                _geminiService.resetSession(uniqueSessionId);
                
                print('DEBUG: Advanced level - second attempt with session: $uniqueSessionId');
                questions = await generateMultipleQuestions(5, level, forceRefresh: true);
                print('DEBUG: Advanced level - second attempt result: ${questions.length} questions');
              } catch (secondAttemptError) {
                print('DEBUG: Advanced level - second attempt also failed: $secondAttemptError');
                print('DEBUG: Advanced level - falling back to default questions');
                questions = _getFallbackQuestions(5, level);
              }
            }
          } else {
            // Normal handling for other levels
            questions = await generateMultipleQuestions(5, level, forceRefresh: true);
          }
          
          print('DEBUG: Generated ${questions.length} questions for ${userLevelToString(level)} level');
          
          if (questions.isEmpty) {
            print('DEBUG: No questions generated for level ${userLevelToString(level)}. Skipping.');
            continue;
          }
          
          // Print the first question for each difficulty level for debugging
          print('DEBUG: First question for ${userLevelToString(level)}: "${questions[0].question}"');
          
          // Create a new quiz for this level
          final quizId = _uuid.v4();
          final quiz = DailyQuiz(
            id: quizId,
            date: DateTime.now().toIso8601String(),
            questions: questions,
            difficulty: level,
          );
          
          // Save it to the global quizzes collection
          final DocumentReference quizRef = _firestore.collection('quizzes').doc();
          
          print('DEBUG: Saving quiz with ID $quizId for level ${userLevelToString(level)}');
          
          final quizData = {
            'id': quizId,
            'date': quiz.date,
            'questions': quiz.questions.map((q) => q.toJson()).toList(),
            'availableFrom': formattedDate,
            'isDaily': true,
            'difficulty': userLevelToString(level),
            'generatedAt': timestamp, // Add timestamp for tracking
          };
          
          await quizRef.set(quizData);
          
          if (level == UserLevel.advanced) {
            // Extra validation for advanced quiz
            print('DEBUG: ADVANCED - Verifying saved quiz data');
            final verifyDoc = await quizRef.get();
            if (verifyDoc.exists) {
              final savedData = verifyDoc.data() as Map<String, dynamic>;
              print('DEBUG: ADVANCED - Quiz saved with difficulty: ${savedData['difficulty']}');
              print('DEBUG: ADVANCED - Quiz has ${(savedData['questions'] as List).length} questions');
            } else {
              print('DEBUG: ADVANCED - ERROR: Quiz document was not saved correctly');
            }
          }
          
          print('DEBUG: Successfully created daily quiz for level: ${userLevelToString(level)} with ID: ${quiz.id}');
        } catch (levelError) {
          print('DEBUG: Error generating quiz for level ${userLevelToString(level)}: $levelError');
          // Continue with next level
          if (level == UserLevel.advanced) {
            print('DEBUG: ADVANCED LEVEL GENERATION FAILED: $levelError');
            
            // Try to create a simple fallback for advanced level directly
            try {
              print('DEBUG: Creating emergency fallback quiz for advanced level');
              final fallbackQuestions = _getFallbackQuestions(5, UserLevel.advanced);
              
              final quizId = _uuid.v4();
              await _firestore.collection('quizzes').doc().set({
                'id': quizId,
                'date': DateTime.now().toIso8601String(),
                'questions': fallbackQuestions.map((q) => q.toJson()).toList(),
                'availableFrom': formattedDate,
                'isDaily': true,
                'difficulty': 'advanced',
                'generatedAt': timestamp,
              });
              
              print('DEBUG: Emergency fallback quiz for advanced level created successfully');
            } catch (fallbackError) {
              print('DEBUG: Even emergency fallback failed: $fallbackError');
            }
          }
        }
      }
      
      print('DEBUG: Quiz generation process completed successfully');
      
      // Additional verification step
      print('DEBUG: Verifying all daily quizzes after generation');
      final verifyQuizzes = await _firestore
          .collection('quizzes')
          .where('isDaily', isEqualTo: true)
          .get();
          
      print('DEBUG: Found ${verifyQuizzes.docs.length} daily quizzes after generation');
      for (var doc in verifyQuizzes.docs) {
        final data = doc.data();
        print('DEBUG: Verified quiz: ID=${data['id']}, Difficulty=${data['difficulty']}');
      }
    } catch (e) {
      print('DEBUG: Error generating new daily quizzes: $e');
      throw e; // Rethrow so the UI can handle it
    }
  }
  
  // Check if we need to refresh the daily quiz
  Future<bool> shouldRefreshDailyQuiz() async {
    try {
      // Get today's date
      final String todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Get the latest daily quiz
      final latestQuizSnap = await _firestore
          .collection('quizzes')
          .where('isDaily', isEqualTo: true)
          .limit(1)
          .get();
          
      if (latestQuizSnap.docs.isEmpty) {
        print('DEBUG: No daily quiz exists, should create one');
        return true; // No daily quiz exists, should create one
      }
      
      // Check if the quiz is from today
      final latestQuiz = latestQuizSnap.docs.first;
      final availableFrom = latestQuiz.data()['availableFrom'] as String;
      
      // Extract just the date part (yyyy-MM-dd) for comparison
      final quizDateStr = availableFrom.split('T')[0];
      
      // If the quiz is not from today, we need a new one
      final needsRefresh = quizDateStr != todayFormatted;
      
      if (needsRefresh) {
        print('DEBUG: Daily quiz is from $quizDateStr, but today is $todayFormatted. Needs refresh.');
      } else {
        print('DEBUG: Daily quiz is already up to date for today ($todayFormatted).');
      }
      
      return needsRefresh;
    } catch (e) {
      print('Error checking if daily quiz needs refresh: $e');
      return true; // On error, better to refresh
    }
  }
  
  // Get the date when the next quiz should be generated
  DateTime getNextQuizGenerationTime() {
    final now = DateTime.now();
    // Set to midnight of the next day
    return DateTime(now.year, now.month, now.day + 1);
  }
  
  // Perform all daily updates (called when app starts or user opens Learn screen)
  Future<void> performDailyUpdates() async {
    final needsRefresh = await shouldRefreshDailyQuiz();
    
    if (needsRefresh) {
      print('DEBUG: Daily quiz needs refresh, generating new quizzes');
      // Generate new daily quiz
      await generateNewDailyQuizForAllUsers();
      
      // Refresh leaderboard
      await refreshLeaderboard();
      
      print('DEBUG: Daily updates completed successfully');
    } else {
      print('DEBUG: Daily updates not needed at this time');
    }
  }

  // Submit a quiz result
  Future<void> submitQuizResult(QuizResult result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Check if the user has already completed a quiz today
      final alreadyCompleted = await hasCompletedTodaysQuiz();
      if (alreadyCompleted) {
        print('DEBUG: User has already completed a quiz today, preventing duplicate submission');
        return; // Don't save duplicate results
      }
      
      // Format the date string to ensure consistency in date format
      final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Update the result date to ensure proper date format
      final updatedResult = QuizResult(
        quizId: result.quizId,
        date: formattedDate,
        score: result.score,
        totalQuestions: result.totalQuestions,
        userAnswers: result.userAnswers,
        correctAnswers: result.correctAnswers,
        points: result.points,
        totalPoints: result.totalPoints,
        difficulty: result.difficulty,
      );
      
      // Save the result to the user's quiz results
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quizResults')
          .add(updatedResult.toJson());
      
      // Update user quiz stats
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final quizStats = userData['quizStats'] ?? {};
        
        // Update stats
        final totalPoints = (quizStats['totalPoints'] ?? 0) + result.score;
        final quizzesTaken = (quizStats['quizzesTaken'] ?? 0) + 1;
        final correctAnswers = (quizStats['correctAnswers'] ?? 0) + result.correctAnswers;
        final totalQuestions = (quizStats['totalQuestions'] ?? 0) + result.totalQuestions;
        
        await _firestore.collection('users').doc(user.uid).update({
          'quizStats': {
            'totalPoints': totalPoints,
            'quizzesTaken': quizzesTaken,
            'correctAnswers': correctAnswers,
            'totalQuestions': totalQuestions,
          }
        });
        
        // Update or create leaderboard entry
        final leaderboardEntry = LeaderboardEntry(
          userId: user.uid,
          displayName: user.displayName ?? 'Anonymous',
          photoUrl: user.photoURL,
          totalPoints: totalPoints,
          quizzesTaken: quizzesTaken,
          userLevel: await getUserLevel(),
        );
        
        await _firestore
            .collection('leaderboard')
            .doc(user.uid)
            .set(leaderboardEntry.toJson());
        
        // Update user level based on performance
        await updateUserLevel();
        
        print('DEBUG: Quiz result saved successfully for date: $formattedDate');
      }
    } catch (e) {
      print('Error submitting quiz result: $e');
    }
  }

  // Manually set the user's level
  Future<bool> setUserLevel(UserLevel level) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    try {
      print('Setting user level to: ${userLevelToString(level)}');
      
      // Check if user document exists
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      
      if (userDoc.exists) {
        // Update existing document
        await userDocRef.update({
          'userLevel': userLevelToString(level),
        });
      } else {
        // Create new document
        await userDocRef.set({
          'userLevel': userLevelToString(level),
          'quizStats': {
            'totalPoints': 0,
            'quizzesTaken': 0,
            'correctAnswers': 0,
            'totalQuestions': 0,
          }
        });
      }
      
      // Update leaderboard entry
      final leaderboardRef = _firestore.collection('leaderboard').doc(user.uid);
      final leaderboardDoc = await leaderboardRef.get();
      
      if (leaderboardDoc.exists) {
        await leaderboardRef.update({
          'userLevel': userLevelToString(level),
        });
      } else {
        // Create leaderboard entry if it doesn't exist
        await leaderboardRef.set({
          'userId': user.uid,
          'displayName': user.displayName ?? 'Anonymous User',
          'photoUrl': user.photoURL,
          'totalPoints': 0,
          'quizzesTaken': 0,
          'userLevel': userLevelToString(level),
        });
      }
      
      print('User level updated successfully to: ${userLevelToString(level)}');
      return true;
    } catch (e) {
      print('Error setting user level: $e');
      return false;
    }
  }
} 