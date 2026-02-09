import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:collection';
import 'dart:math' as math;
import 'scam_detection_service.dart';

class GeminiService {
  static GeminiService? _instance;
  late GenerativeModel _model;
  final Map<String, ChatSession> _agentSessions = {};
  // LRU cache to store recent responses
  final int _cacheSize = 50;
  final Map<String, String> _responseCache = LinkedHashMap(equals: (a, b) => a == b, hashCode: (k) => k.hashCode);
  
  // Custom API Key support
  String? _customApiKey;
  static const String _kCustomApiKeyPrefsKey = 'custom_gemini_api_key';

  // Private constructor
  GeminiService._() {
    // Verify key availability - check both env and potential custom key (though custom key is loaded async later)
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if ((apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') && _customApiKey == null) {
      print('Warning: Gemini API key not found in .env. Waiting for custom key or user input.');
    }
    
    _initModel();
  }

  // Initialize or re-initialize the model
  void _initModel() {
    String? apiKey = _customApiKey;
    print('GeminiService DEBUG: Initializing model. Custom Key present: ${_customApiKey != null}');
    
    // Fallback to .env if no custom key
    if (apiKey == null || apiKey.isEmpty) {
      apiKey = dotenv.env['GEMINI_API_KEY'];
      print('GeminiService DEBUG: Using .env key');
    } else {
      print('GeminiService DEBUG: Using custom key: ${apiKey.substring(0, 4)}...');
    }
    
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      print('GeminiService: No valid API key found during initialization');
      return; 
    }

    try {
      // Initialize the model with the API key
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', 
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topP: 0.9,
          topK: 40,
          maxOutputTokens: 2000,
          stopSequences: ['\n\n\n'],
        ),
      );
      print('GeminiService: Model initialized successfully');
    } catch (e) {
      print('GeminiService: Error initializing model: $e');
    }
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
      // Special handling for quiz requests - always use a new session
      final bool isQuizRequest = agentType.startsWith('quiz_');
      final bool isAdvancedQuiz = isQuizRequest && agentType.contains('advanced');
      
      if (isAdvancedQuiz) {
        print('DEBUG: GeminiService - Handling advanced quiz request: $agentType');
      }
      
      // Skip caching for quiz requests to ensure fresh content
      if (!isQuizRequest) {
        // Check if the response is cached
        final cacheKey = _generateCacheKey(agentType, message);
        if (_responseCache.containsKey(cacheKey)) {
          print('DEBUG: Using cached response for $agentType');
          return _responseCache[cacheKey]!;
        }
      } else {
        print('DEBUG: Bypassing cache for quiz request: $agentType');
        if (isAdvancedQuiz) {
          print('DEBUG: GeminiService - Creating fresh session for advanced quiz');
        }
      }
      
      // For quiz requests, create a one-time session instead of reusing
      ChatSession session;
      if (isQuizRequest) {
        session = _model.startChat();
        if (isAdvancedQuiz) {
          print('DEBUG: GeminiService - Created new chat session for advanced quiz');
        }
      } else {
        session = getOrCreateSession(agentType);
      }
      
      // For the first message, prepend the system prompt
      final isFirstMessage = session.history.isEmpty;
      
      String prompt = message;
      if (isFirstMessage) {
        // Don't use system prompts for quiz generation
        if (!isQuizRequest) {
          final systemPrompt = _getSystemPromptForAgent(agentType);
          prompt = "$systemPrompt\n\nUser: $message";
        } else if (isAdvancedQuiz) {
          print('DEBUG: GeminiService - Using direct prompt for advanced quiz without system prompts');
        }
      }
      
      print('DEBUG: Sending prompt to Gemini with agent type: $agentType');
      
      if (isAdvancedQuiz) {
        print('DEBUG: GeminiService - Advanced quiz prompt length: ${prompt.length}');
        print('DEBUG: GeminiService - Advanced quiz prompt starts with: ${prompt.substring(0, math.min(100, prompt.length))}...');
      }
      
      // Send the message to the model
      final response = await session.sendMessage(Content.text(prompt));
      
      // Get the response text
      final responseText = response.text ?? 'Sorry, I couldn\'t generate a response.';
      
      if (isAdvancedQuiz) {
        print('DEBUG: GeminiService - Advanced quiz response received, length: ${responseText.length}');
        print('DEBUG: GeminiService - Response starts with: ${responseText.substring(0, math.min(100, responseText.length))}...');
      }
      
      // Cache the response (only for non-quiz requests)
      if (!isQuizRequest) {
        final cacheKey = _generateCacheKey(agentType, message);
        _addToCache(cacheKey, responseText);
      } else if (isAdvancedQuiz) {
        print('DEBUG: GeminiService - Not caching advanced quiz response as expected');
      }
      
      // Return the response
      return responseText;
    } catch (e) {
      print('DEBUG: Error in Gemini service: $e');
      return 'Sorry, an error occurred: $e';
    }
  }
  
  // Format user context into a structured string for the AI - optimized for speed
  String _formatUserContext(Map<String, dynamic> context) {
    final buffer = StringBuffer();
    
    // Spending Context
    final spending = context['spending'];
    if (spending != null) {
      buffer.writeln('SPENDING (${spending['month']}):');
      buffer.writeln('Total: ₹${spending['currentMonthTotal']} (Last Month: ₹${spending['lastMonthTotal']})');
      
      final trends = spending['trends'] as List?;
      if (trends != null && trends.isNotEmpty) {
        buffer.writeln('TRENDS:');
        for (var trend in trends.take(5)) { // Top 5 categories
           buffer.writeln('- ${trend['category']}: ₹${trend['currentAmount']} (${(trend['percentChange'] as double).toStringAsFixed(1)}%)');
        }
      }
    }

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
    
    // Budgets
    final budgets = context['budgets'] as List?;
    if (budgets != null && budgets.isNotEmpty) {
      buffer.writeln('BUDGETS:');
      for (var budget in budgets) {
        buffer.writeln('- ${budget['category']}: ₹${(budget['limit'] as double).toStringAsFixed(0)} limit, ' +
                       '₹${(budget['spent'] as double).toStringAsFixed(0)} spent (${(budget['percentUsed'] as double).toStringAsFixed(0)}%)');
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
  
  // Reset all sessions to force new conversations
  void resetAllSessions() {
    print('DEBUG: GeminiService - Resetting all chat sessions');
    _agentSessions.clear();
    _responseCache.clear();
    print('DEBUG: GeminiService - Cleared ${_responseCache.length} cached responses and all sessions');
  }
  
  // Reset a specific session
  void resetSession(String agentType) {
    if (_agentSessions.containsKey(agentType)) {
      _agentSessions.remove(agentType);
      print('DEBUG: Reset session for agent: $agentType');
      
      // Also clear relevant cache entries
      final keysToRemove = _responseCache.keys.where((k) => k.startsWith('$agentType:')).toList();
      for (var key in keysToRemove) {
        _responseCache.remove(key);
      }
      print('DEBUG: Cleared ${keysToRemove.length} cached responses for $agentType');
    }
  }
  
  // Get a compact system prompt optimized for speed
  String _getCompactSystemPrompt(String agentType) {
    switch (agentType) {
      case 'assistant':
        return 'You are Penny Pilot, an all-in-one financial assistant for coaching, fraud detection, and planning.';
      case 'personal':
        return 'You are an AI Financial Coach. Help users understand spending patterns.';
      case 'fraud':
        return 'You are a Fraud Detective. Help identify and avoid financial scams.';
      case 'mythbusting':
        return 'You are a Financial Myth Buster. Debunk financial misconceptions.';
      case 'roadmap':
        return 'You are a Roadmap Guide. Create financial plans to reach goals.';
      case 'financial_summary':
        return 'You are a Financial Summary Generator. Summarize spending without advice.';
      case 'scam_explanation':
        return 'You are a Scam Explanation Assistant. Explain why a message is flagged as suspicious.';
      default:
        return 'You are a helpful AI assistant for financial topics.';
    }
  }
  
  // Get the system prompt based on agent type
  String _getSystemPromptForAgent(String agentType) {
    const basePrompt = 'You are an AI assistant specialized in financial services. ';
    
    switch (agentType) {
      case 'assistant':
        return basePrompt + 'You are Penny Pilot, an all-in-one AI Financial Assistant. '
          'Your goal is to help users with ALL their financial needs, including: '
          '1. Financial Coaching: Analyze spending patterns and provide insights (requires user context). '
          '2. Fraud Detection: Identify potential scams and explain why a message might be suspicious. '
          '3. Myth Busting: Correct financial misconceptions with facts. '
          '4. Roadmap Planning: Create structured financial plans for goals. '
          '5. General Finance: Answer questions about investment concepts, banking, etc. '
          '\n'
          'Guidelines: '
          '- Always be helpful, neutral, and educational. '
          '- NEVER give specific investment advice (e.g., "Buy stock X"). '
          '- Use Indian Rupee symbol (₹) for ALL currency values. '
          '- If the user asks about their own data, use the provided USER CONTEXT. '
          '- If the user shares a suspicious message, analyze it for fraud indicators. '
          '- Response style: Clear, concise, using Markdown (bold, bullet points). ';

      case 'personal':
        return basePrompt + 'You are an AI Financial Coach, not a financial advisor. '
          'Your purpose is to help users understand their own spending behavior and financial patterns using the data provided. '
          'You must explain, summarize, and reflect insights. You must never give investment advice, predictions, or instructions to buy, sell, or invest. '
          'Strictly Disallowed: Recommend specific financial products, Suggest buying, selling, or investing, Predict future expenses or returns, Use of Dollar symbol (\$). '
          'Response Structure (MANDATORY): '
          '1. Direct Answer: Clear, simple explanation using the data. '
          '2. Supporting Observations: 2-3 bullet points referencing spending categories or trends. '
          '3. Behavioral Insight (Optional): A neutral explanation of possible behavior (e.g., timing, frequency). '
          '4. Gentle Reflection: A non-advisory closing line that encourages awareness, not action. '
          'Tone: Neutral, Supportive, Non-judgmental. Avoid technical jargon and judgmental phrases. '
          'Formatting: Use Indian Rupee symbol (₹) for ALL currency values. Never use \$. Use standard Markdown for formatting (e.g., **bold**, # Header). Ensure there is a space after the # for headers.';
          
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


      case 'financial_summary':
        return 'System Role: You are a Financial Summary Generator. '
               'Your task is to generate a clear, human-readable monthly financial summary based only on the user’s historical expense data provided. '
               'You are not a financial advisor. '
               '1. Objective: Convert raw expense analytics into a simple, friendly monthly narrative that helps the user understand where money was spent, what changed compared to the previous month, and notable spending patterns. '
               '2. Allowed Behavior: Summarize spending by category, Highlight increases and decreases, Mention timing patterns (weekends, weekdays), Describe recurring or frequent expenses, Use neutral, observational language. '
               '3. Strictly Disallowed: You MUST NOT Give financial advice, Suggest actions (“you should”, “try to”), Predict future spending, Recommend investments or savings plans. If advice is implied, rephrase as observation only. '
               '4. Output Structure: '
               '   ### Monthly Overview (1-2 sentences on total spend and change) '
               '   ### Category Highlights (2-4 bullet points on major changes) '
               '   ### Spending Patterns (Short paragraph on timing/behavior) '
               '   ### Closing Reflection (Neutral, non-advisory reflection encouraging awareness) '
               '5. Tone: Simple, Friendly, Non-judgmental, No technical jargon. '
               '6. Formatting: Use Indian Rupee symbol (₹) for all currency values.';

      case 'scam_explanation':
        return 'System Role: You are a Scam Explanation Assistant. '
               'Your task is to explain why a message was flagged as suspicious or potentially a scam based on detection signals provided. '
               'You do not detect scams yourself. You only explain the output of an existing on-device ML model. '
               '1. Objective: Convert technical scam-detection signals into a simple, human-readable explanation so users understand why a message looks risky. '
               '2. Input You Will Receive: Scam classification result, Confidence score, Detected indicators (Urgent language, Suspicious links, etc.), Original Message. '
               '3. Allowed Behavior: Explain common scam patterns, Explain why indicators are risky, Educate the user, Use neutral, non-alarming language. '
               '4. Strictly Disallowed: You MUST NOT Claim the message is definitely a scam, Use fear-inducing language, Instruct the user to take specific actions, Ask the user to click, block, or report. Avoid words like \"confirmed fraud\", \"guaranteed scam\". '
               '5. Required Response Structure: '
               '   ### Why this message was flagged (Clear explanation using detected indicators) '
               '   ### What this means (Short educational explanation of why such patterns are risky) '
               '   ### Important note (Calm disclaimer stating the result is AI-based and informational) '
               '6. Tone: Calm, Reassuring, Non-judgmental, Easy to understand.';

      default:
        return basePrompt + 'You are a general financial advisor. Provide clear, accurate, and helpful financial guidance.';
    }
  }

  /// Generate a Monthly Financial Summary
  Future<String> generateMonthlyFinancialSummary(Map<String, dynamic> data) async {
     try {
       final session = getOrCreateSession('financial_summary');
       
       final buffer = StringBuffer();
       buffer.writeln("Month: ${data['month']}");
       buffer.writeln("Total Spend: ₹${data['totalSpend']}");
       buffer.writeln("Previous Month: ₹${data['previousMonthTotal']}");
       buffer.writeln("Category Breakdown:");
       for (var item in data['categoryBreakdown']) {
         buffer.writeln("- ${item['category']}: ₹${item['amount']} (${(item['percentChange'] as double).toStringAsFixed(1)}%)");
       }
       buffer.writeln("High Spend Days: ${data['highSpendDays']}");
       
       final prompt = buffer.toString();
       print('DEBUG: Sending financial summary request: $prompt');
       
       final response = await session.sendMessage(Content.text(prompt));
       return response.text ?? "Unable to generate summary.";
     } catch (e) {
       print('Error generating financial summary: $e');
       return "Error generating summary: $e";
     }
  }

  /// Generate an explanation for a flagged scam message
  Future<String> explainScamMessage(ScamResult result, String originalMessage) async {
    try {
      final session = getOrCreateSession('scam_explanation');
      
      final buffer = StringBuffer();
      buffer.writeln("Classification: ${result.risk.name.toUpperCase()}");
      buffer.writeln("Confidence: ${result.confidence.toStringAsFixed(2)}");
      buffer.writeln("Indicators:");
      if (result.indicators.isEmpty) {
         buffer.writeln("- Unknown indicators");
      } else {
         for (var indicator in result.indicators) {
           buffer.writeln("- $indicator");
         }
      }
      buffer.writeln("Original Message Body: \"$originalMessage\"");
      
      final prompt = buffer.toString();
      print('DEBUG: Sending scam explanation request: $prompt');
      
      final response = await session.sendMessage(Content.text(prompt));
      return response.text ?? "Unable to generate explanation.";
    } catch (e) {
      print('Error generating scam explanation: $e');
      return "Error generating explanation: $e";
    }
  }

  // Load custom API key from SharedPreferences
  Future<void> loadCustomApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_kCustomApiKeyPrefsKey);
      
      if (key != null && key.isNotEmpty) {
        print('GeminiService: Loaded custom API key');
        _customApiKey = key;
        // Re-initialize logic if needed, but usually this is called before usage
        _initModel();
        // Clear sessions to ensure new key is used
        resetAllSessions();
      }
    } catch (e) {
      print('GeminiService: Error loading custom API key: $e');
    }
  }

  // Set or remove custom API key
  Future<void> setCustomApiKey(String? key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (key == null || key.isEmpty) {
        await prefs.remove(_kCustomApiKeyPrefsKey);
        _customApiKey = null;
        print('GeminiService: Custom API key removed');
      } else {
        await prefs.setString(_kCustomApiKeyPrefsKey, key);
        _customApiKey = key;
        print('GeminiService: Custom API key saved');
      }
      
      // Re-initialize model with new key configuration
      _initModel();
      // Clear sessions to ensure new key is used
      resetAllSessions();
    } catch (e) {
      print('GeminiService: Error setting custom API key: $e');
      throw e;
    }
  }

  // Test the API key validity
  Future<String?> testApiKey(String apiKey) async {
    try {
      print('GeminiService DEBUG: Testing API key...');
      // Create a temporary model instance for testing
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );
      
      final response = await model.generateContent([Content.text('Test')]);
      print('GeminiService DEBUG: API key test successful. Response: ${response.text}');
      return null; // Null means success
    } catch (e) {
      print('GeminiService DEBUG: API key test failed: $e');
      return e.toString(); // Return error message
    }
  }

  // Getter to check if using custom key
  bool get isUsingCustomKey => _customApiKey != null && _customApiKey!.isNotEmpty;
  
  // Getter for the current custom key (for UI population)
  String? get currentCustomApiKey => _customApiKey;
}