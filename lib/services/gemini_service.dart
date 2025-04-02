import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:collection';

class GeminiService {
  static GeminiService? _instance;
  late GenerativeModel _model;
  final Map<String, ChatSession> _agentSessions = {};
  // LRU cache to store recent responses
  final int _cacheSize = 50;
  final Map<String, String> _responseCache = LinkedHashMap(equals: (a, b) => a == b, hashCode: (k) => k.hashCode);

  // Private constructor
  GeminiService._() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      throw Exception('Gemini API key not found. Please add your API key to .env file');
    }
    
    // Initialize the model with the API key - using gemini-flash for faster responses
    _model = GenerativeModel(
      model: 'gemini-2.0-flash', // Using the faster model variant
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3, // Lower temperature for faster and more deterministic responses
        topP: 0.7,
        topK: 20, 
        maxOutputTokens: 1000, // Increased from 600 to allow for more detailed responses
        stopSequences: ['\n\n\n'],
      ),
    );
  }

  // Factory constructor to return the singleton instance
  factory GeminiService() {
    _instance ??= GeminiService._();
    return _instance!;
  }

  // Get or create a chat session for a specific agent type
  ChatSession getOrCreateSession(String agentType) {
    if (_agentSessions.containsKey(agentType)) {
      return _agentSessions[agentType]!;
    }
    
    // Create a new session with agent-specific system prompt
    final systemPrompt = _getSystemPromptForAgent(agentType);
    
    // Initialize chat with system prompt
    final session = _model.startChat();
    
    // Store the session
    _agentSessions[agentType] = session;
    return session;
  }

  // Generate a cache key for the message
  String _generateCacheKey(String agentType, String message) {
    return '$agentType:${message.trim()}';
  }

  // Generate a cache key for personalized messages
  String _generatePersonalizedCacheKey(String agentType, String message, Map<String, dynamic> context) {
    // Include a hash of the context to ensure cache is invalidated when context changes
    final contextHash = context.toString().hashCode;
    return '$agentType:${message.trim()}:$contextHash';
  }

  // Add a response to the cache
  void _addToCache(String key, String response) {
    // If cache is full, remove the oldest entry
    if (_responseCache.length >= _cacheSize) {
      _responseCache.remove(_responseCache.keys.first);
    }
    _responseCache[key] = response;
  }

  // Send a message to the model and get a response
  Future<String> sendMessage(String agentType, String message) async {
    try {
      // Check if the response is cached
      final cacheKey = _generateCacheKey(agentType, message);
      if (_responseCache.containsKey(cacheKey)) {
        return _responseCache[cacheKey]!;
      }

      final session = getOrCreateSession(agentType);
      
      // For the first message, prepend the system prompt
      final isFirstMessage = session.history.isEmpty;
      
      String prompt = message;
      if (isFirstMessage) {
        final systemPrompt = _getSystemPromptForAgent(agentType);
        prompt = "$systemPrompt\n\nUser: $message";
      }
      
      // Send the message to the model
      final response = await session.sendMessage(Content.text(prompt));
      
      // Get the response text
      final responseText = response.text ?? 'Sorry, I couldn\'t generate a response.';
      
      // Cache the response
      _addToCache(cacheKey, responseText);
      
      // Return the response
      return responseText;
    } catch (e) {
      return 'Sorry, an error occurred: $e';
    }
  }
  
  // Format user context into a structured string for the AI - optimized for speed
  String _formatUserContext(Map<String, dynamic> context) {
    final buffer = StringBuffer();
    
    // Risk Profile - simplified
    final riskProfile = context['riskProfile'];
    if (riskProfile != null) {
      buffer.writeln('RISK: ${riskProfile['riskLevel']} (Score: ${riskProfile['score']})');
    }
    
    // Financial Health - simplified
    final financialHealth = context['financialHealth'];
    if (financialHealth != null) {
      buffer.writeln('HEALTH: ${financialHealth['category']} (Score: ${financialHealth['score']})');
      buffer.writeln('Income/Expense: ${financialHealth['incomeExpensesRatio'].toStringAsFixed(1)}, ' +
                     'Savings: ${(financialHealth['savingsRate'] * 100).toStringAsFixed(0)}%, ' +
                     'Debt/Income: ${(financialHealth['debtToIncomeRatio'] * 100).toStringAsFixed(0)}%, ' +
                     'Emergency: ${financialHealth['emergencyFundRatio'].toStringAsFixed(1)} months');
    }
    
    // Financial Goals - simplified
    final goals = context['financialGoals'];
    if (goals != null && goals.isNotEmpty) {
      buffer.writeln('GOALS:');
      for (var goal in goals) {
        buffer.writeln('- ${goal['name']}: ${goal['progress'].toStringAsFixed(0)}% complete, ' +
                      '${goal['daysRemaining']} days left');
      }
    }
    
    return buffer.toString();
  }
  
  // Send a personalized message with user financial context - optimized
  Future<String> sendPersonalizedMessage(String agentType, String message, Map<String, dynamic> userContext) async {
    try {
      // Simplified cache key for faster lookups
      final cacheKey = '$agentType:${message.hashCode}:${userContext.hashCode}';
      if (_responseCache.containsKey(cacheKey)) {
        return _responseCache[cacheKey]!;
      }

      final session = getOrCreateSession(agentType);
      
      // Format the financial context as a more compact string
      final contextString = _formatUserContext(userContext);
      
      // Prepare a more concise personalized prompt
      final personalizedPrompt = """${_getCompactSystemPrompt(agentType)}
      
USER CONTEXT: $contextString
QUERY: $message

Provide concise, personalized advice based on this context.
""";
      
      // Send the message to the model
      final response = await session.sendMessage(Content.text(personalizedPrompt));
      
      // Get the response text
      final responseText = response.text ?? 'Sorry, I couldn\'t generate a response.';
      
      // Cache the response
      _addToCache(cacheKey, responseText);
      
      // Return the response
      return responseText;
    } catch (e) {
      return 'Sorry, an error occurred when processing your request. Please try again.';
    }
  }
  
  // Reset the chat session for a specific agent
  void resetSession(String agentType) {
    if (_agentSessions.containsKey(agentType)) {
      _agentSessions.remove(agentType);
    }
  }
  
  // Get a compact system prompt optimized for speed
  String _getCompactSystemPrompt(String agentType) {
    switch (agentType) {
      case 'personal':
        return 'You are a Smart Finance Advisor. Provide personalized advice based on financial data.';
      case 'fraud':
        return 'You are a Fraud Detective. Help identify and avoid financial scams.';
      case 'mythbusting':
        return 'You are a Financial Myth Buster. Debunk financial misconceptions.';
      case 'roadmap':
        return 'You are a Roadmap Guide. Create financial plans to reach goals.';
      default:
        return 'You are a helpful AI assistant for financial topics.';
    }
  }
  
  // Get the system prompt based on agent type
  String _getSystemPromptForAgent(String agentType) {
    const basePrompt = 'You are an AI assistant specialized in financial services. ';
    
    switch (agentType) {
      case 'personal':
        return basePrompt + 'You are a highly knowledgeable and strategic Personal Finance Advisor. '
          'Your role is to provide expert yet personalized financial advice based on the user\'s financial profile. '
          'Analyze their income, expenses, goals, and risk tolerance to recommend tailored investment strategies, budgeting plans, '
          'and financial improvements. Prioritize factual accuracy, simplicity, and actionable recommendations. '
          'Use short, precise responses while explaining complex financial terms in an easy-to-understand manner.';
          
      case 'fraud':
        return basePrompt + 'You are a Fraud Detection Assistant, specializing in financial scam awareness and prevention. '
          'Your goal is to help users identify potential fraud, scams, and Ponzi schemes in investment and banking sectors. '
          'Analyze user queries for red flags like unrealistic returns, phishing attempts, and unverified financial schemes. '
          'Provide clear explanations, verified resources, and actionable steps to safeguard against fraud. '
          'If a query is suspicious, ask follow-up questions to gather more details before giving a conclusion.';
          
      case 'mythbusting':
        return basePrompt + 'You are a Financial Myth Buster, dedicated to correcting misconceptions about investing, savings, and wealth management. '
          'Your job is to analyze statements, detect misinformation, and provide factual, easy-to-understand explanations. '
          'Use real-world examples, statistics, and references to trusted financial sources (SEBI, RBI, AMFI) when debunking myths. '
          'Ensure responses are clear, educational, and backed by logical reasoning.';
          
      case 'roadmap':
        return basePrompt + 'You are a Financial Roadmap Assistant, responsible for creating structured and achievable financial plans. '
          'Ask users about their financial goals (buying a house, saving for education, retirement planning) and create step-by-step savings, investment, and budgeting strategies. '
          'Use data-driven insights to estimate timelines and suggest optimized approaches for faster goal achievement. '
          'Be adaptive—consider user preferences, risk tolerance, and financial constraints when designing roadmaps.';
          
      default:
        return basePrompt + 'You are a general financial advisor. Provide clear, accurate, and helpful financial guidance.';
    }
  }
} 