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
        temperature: 0.4, // Lower temperature for faster and more consistent responses 
        topP: 0.7,
        topK: 20,
        maxOutputTokens: 800, // Reduced max tokens for faster responses
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
  
  // Reset the chat session for a specific agent
  void resetSession(String agentType) {
    if (_agentSessions.containsKey(agentType)) {
      _agentSessions.remove(agentType);
    }
  }
  
  // Get the system prompt based on agent type
  String _getSystemPromptForAgent(String agentType) {
    // Simplify base prompt to reduce token count
    String basePrompt = 'Use Markdown for your responses. ';
    
    switch (agentType) {
      case 'finance':
        return basePrompt + 'You are a GenAI-powered financial investment assistant for Indian users. '
               'Help users make better investment decisions with practical guidance on financial concepts. '
               'Explain finance concepts simply, without jargon. '
               'Be aware of Indian investment practices and currency (rupees).\n\n'
               'Guidelines:\n'
               '- Answer investment and financial questions only\n'
               '- Be clear and concise\n'
               '- Use simple language\n'
               '- Focus on Indian financial context\n'
               '- Display monetary amounts in rupees (₹)\n'
               '- Consider Indian preferences like gold, real estate, FDs, mutual funds\n'
               '- Give general insights, not specific product recommendations';
      
      case 'fraud':
        return basePrompt + 'You are a GenAI-powered Fraud Detection Assistant for Indian users. '
               'Help users identify and protect themselves from financial scams and frauds. '
               'Guidelines:\n'
               '- Identify financial scams and frauds\n'
               '- Explain warning signs and red flags\n'
               '- Provide practical protection advice\n'
               '- Guide on reporting fraud\n'
               '- Focus on Indian financial context\n'
               '- Use simple language\n'
               '- Include examples and action steps';
      
      case 'mythbusting':
        return basePrompt + 'You are a GenAI-powered Financial Myth Buster for Indian users. '
               'Help users understand financial concepts by debunking misconceptions. '
               'Guidelines:\n'
               '- Debunk financial misconceptions\n'
               '- Provide evidence-based explanations\n'
               '- Explain why myths persist\n'
               '- Offer alternative approaches\n'
               '- Focus on Indian financial context\n'
               '- Use simple language\n'
               '- Include examples and data';
      
      case 'roadmap':
        return basePrompt + 'You are a GenAI-powered financial roadmap assistant for Indian users. '
               'Help create personalized financial roadmaps to achieve goals. '
               'Guidelines:\n'
               '- Ask for necessary financial information\n'
               '- Create clear, actionable roadmaps\n'
               '- Use Indian financial strategies (SIPs, PPF, NPS, FDs)\n'
               '- Display amounts in rupees (₹)\n'
               '- Base on proven strategies but adapt for Indian market\n'
               '- Provide realistic steps with timelines\n'
               '- Give general advice, not specific product recommendations';
      
      default:
        return basePrompt + 'You are a helpful AI assistant for financial topics.';
    }
  }
} 