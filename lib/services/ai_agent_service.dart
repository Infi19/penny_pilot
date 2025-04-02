import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/retry_helper.dart';
import 'gemini_service.dart';
import 'personalized_advice_service.dart';
import 'dart:async';

class AIAgentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GeminiService _geminiService = GeminiService();
  final PersonalizedAdviceService _personalizedAdviceService = PersonalizedAdviceService();
  
  // Cache session IDs to avoid repeated Firestore queries
  final Map<String, String> _sessionCache = {};
  
  // Map of agent types to their IDs
  static const Map<String, String> _agentIds = {
    'personal': 'smart_finance_advisor', // Updated to combine personal and finance
    'fraud': 'fraud_agent',
    'mythbusting': 'mythbusting_agent',
    'roadmap': 'roadmap_agent',
  };

  // Method to get or create chat session for a user and agent
  Future<String> _getOrCreateChatSession(String userId, String agentType) async {
    // Check the cache first
    final cacheKey = '$userId:$agentType';
    if (_sessionCache.containsKey(cacheKey)) {
      return _sessionCache[cacheKey]!;
    }
    
    try {
      // Check if a session exists
      final sessionsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chatSessions')
          .where('agentType', isEqualTo: agentType);
      
      final sessions = await RetryHelper.withRetry(
        operation: () => sessionsRef.get(),
      );
      
      // If session exists, return its ID
      if (sessions.docs.isNotEmpty) {
        final sessionId = sessions.docs.first.id;
        _sessionCache[cacheKey] = sessionId; // Add to cache
        return sessionId;
      }
      
      // Create a new session
      final newSessionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chatSessions')
          .doc();
      
      await RetryHelper.withRetry(
        operation: () => newSessionRef.set({
          'agentType': agentType,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }),
      );
      
      _sessionCache[cacheKey] = newSessionRef.id; // Add to cache
      return newSessionRef.id;
    } catch (e) {
      print('Error getting/creating chat session: $e');
      rethrow;
    }
  }

  // Method to send a message to the agent and get a response
  Future<Map<String, dynamic>> sendMessage(String agentType, String message) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated';
      }
      
      // Create a session ID even before starting the AI request
      final sessionIdFuture = _getOrCreateChatSession(userId, agentType);
      
      // Start getting the AI response immediately
      final responseCompleter = Completer<String>();
      
      // For personalized advice, include user financial context
      if (agentType == 'personal') {
        // Get user's financial context for personalization (with timeout)
        final userContext = await _personalizedAdviceService.getUserFinancialContext()
            .timeout(const Duration(seconds: 3), onTimeout: () => {});
        
        // Send message with context to Gemini (parallel processing)
        _geminiService.sendPersonalizedMessage(
          agentType, 
          message, 
          userContext
        ).then((response) {
          if (!responseCompleter.isCompleted) {
            // Log the personalized advice interaction in background
            _personalizedAdviceService.logAdviceInteraction(
              message, 
              response, 
              'personal_finance'
            ).catchError((_) {});
            responseCompleter.complete(response);
          }
        }).catchError((e) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.completeError(e);
          }
        });
      } else {
        // Standard agent behavior for non-personalized agents
        _geminiService.sendMessage(agentType, message).then((response) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(response);
          }
        }).catchError((e) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.completeError(e);
          }
        });
      }
      
      // Get the agent ID
      final agentId = _agentIds[agentType];
      if (agentId == null) {
        throw 'Invalid agent type';
      }

      // Wait for the session ID
      final sessionId = await sessionIdFuture;
      
      // Add user message to Firestore (don't wait for completion)
      final messageRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chatSessions')
          .doc(sessionId)
          .collection('messages')
          .doc();
      
      // Don't await this operation to reduce response time
      RetryHelper.withRetry(
        operation: () => messageRef.set({
          'content': message,
          'isUser': true,
          'timestamp': FieldValue.serverTimestamp(),
        }),
      );

      // Update session timestamp (don't wait for completion)
      RetryHelper.withRetry(
        operation: () => _firestore
            .collection('users')
            .doc(userId)
            .collection('chatSessions')
            .doc(sessionId)
            .update({
              'lastUpdated': FieldValue.serverTimestamp(),
            }),
      );

      // Wait for the AI response with timeout
      final response = await responseCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => "I'm taking longer than expected to respond. Please try a simpler question or try again in a moment.",
      );
      
      // Add bot response to Firestore (don't wait for completion)
      final botMessageRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chatSessions')
          .doc(sessionId)
          .collection('messages')
          .doc();
      
      // Don't await this operation to reduce response time
      RetryHelper.withRetry(
        operation: () => botMessageRef.set({
          'content': response,
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
        }),
      );

      return {
        'sessionId': sessionId,
        'response': response,
      };
    } catch (e) {
      print('Error sending message: $e');
      return {
        'sessionId': '',
        'response': 'Sorry, an error occurred. Please try again.',
      };
    }
  }

  // Method to get chat history for a user and agent
  Future<List<Map<String, dynamic>>> getChatHistory(String agentType, {int limit = 50}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated';
      }
      
      // Get the session ID
      final sessionId = await _getOrCreateChatSession(userId, agentType);
      
      // Get the messages
      final messagesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chatSessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp')
          .limit(limit);
      
      final messages = await RetryHelper.withRetry(
        operation: () => messagesRef.get(),
      );
      
      return messages.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'content': data['content'] ?? '',
          'isUser': data['isUser'] ?? true,
          'timestamp': data['timestamp']?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error getting chat history: $e');
      return [];
    }
  }

  // Method to delete a message from a chat session
  Future<void> deleteMessage(String agentType, String messageId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated';
      }
      
      // Get the session ID
      final sessionId = await _getOrCreateChatSession(userId, agentType);
      
      // Delete the message from Firestore
      await RetryHelper.withRetry(
        operation: () => _firestore
            .collection('users')
            .doc(userId)
            .collection('chatSessions')
            .doc(sessionId)
            .collection('messages')
            .doc(messageId)
            .delete(),
      );
      
      // Update the last updated timestamp of the session
      await RetryHelper.withRetry(
        operation: () => _firestore
            .collection('users')
            .doc(userId)
            .collection('chatSessions')
            .doc(sessionId)
            .update({
              'lastUpdated': FieldValue.serverTimestamp(),
            }),
      );
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // Method to delete an entire chat session
  Future<void> deleteChatSession(String agentType) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated';
      }
      
      // Get the session ID
      final sessionId = await _getOrCreateChatSession(userId, agentType);
      
      // Clear session cache
      _sessionCache.remove('$userId:$agentType');
      
      // Get all messages from the session
      final messagesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chatSessions')
          .doc(sessionId)
          .collection('messages');
      
      final messages = await RetryHelper.withRetry(
        operation: () => messagesRef.get(),
      );
      
      // Delete all messages using a batch
      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the session document
      batch.delete(_firestore
          .collection('users')
          .doc(userId)
          .collection('chatSessions')
          .doc(sessionId));
      
      // Commit the batch
      await RetryHelper.withRetry(
        operation: () => batch.commit(),
      );
      
      // Reset the Gemini session
      _geminiService.resetSession(agentType);
    } catch (e) {
      print('Error deleting chat session: $e');
      rethrow;
    }
  }
} 