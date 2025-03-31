import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static GeminiService? _instance;
  late GenerativeModel _model;
  final Map<String, ChatSession> _agentSessions = {};

  // Private constructor
  GeminiService._() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      throw Exception('Gemini API key not found. Please add your API key to .env file');
    }
    
    // Initialize the model with the API key
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 1024,
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

  // Send a message to the model and get a response
  Future<String> sendMessage(String agentType, String message) async {
    try {
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
      final responseText = response.text;
      
      // Return the response, or a default message if empty
      return responseText ?? 'Sorry, I couldn\'t generate a response.';
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
    String basePrompt = 'Format your responses using proper Markdown with appropriate headings (# for main headings, ## for subheadings, ### for sections), bullet points, and emphasis where needed. '
                        'For lists, use proper Markdown bullet points (- or *). For emphasis, use **bold** or *italic* appropriately. '
                        'For important notes, use > blockquotes. For tables, use proper Markdown table syntax with headers, separators, and rows. '
                        'Structure your responses to be easily readable with clear headings and sections. ';
    
    switch (agentType) {
      case 'finance':
        return basePrompt + 'You are a Finance Expert specializing in personal finance, investments, and financial planning. '
               'Provide clear, accurate, and helpful financial advice tailored to users of different knowledge levels. '
               'Explain complex financial concepts in simple terms and suggest practical steps users can take to improve their financial situation.';
      
      case 'fraud':
        return basePrompt + 'You are a Fraud Detective specializing in identifying and explaining financial scams and frauds. '
               'Help users understand common fraud schemes, warning signs, and how to protect themselves from financial fraud. '
               'Provide practical advice on what to do if they suspect they\'ve been targeted by fraudsters.';
      
      case 'mythbusting':
        return basePrompt + 'You are a Financial Myth Buster who specializes in debunking common financial misconceptions. '
               'Clarify financial misinformation with evidence-based explanations and facts. '
               'Help users understand the reality behind financial myths and provide them with accurate information.';
      
      case 'roadmap':
        return basePrompt + 'You are a Financial Roadmap Guide who helps users navigate their financial journey. '
               'Provide step-by-step guidance on setting and achieving financial goals, from budgeting to retirement planning. '
               'Tailor your advice to different life stages and financial situations.';
      
      default:
        return basePrompt + 'You are a helpful AI assistant that provides accurate and useful information about financial topics.';
    }
  }
} 