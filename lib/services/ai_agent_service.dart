import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/retry_helper.dart';

class AIAgentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Base URL for Vertex AI API - you'll need to adapt this to your specific setup
  static const String _baseUrl = 'https://us-central1-aiplatform.googleapis.com/v1';
  
  // Agent IDs from Vertex AI Agent Builder - replace with your actual IDs
  static const String _finAgentId = 'YOUR_FIN_AGENT_ID';
  static const String _fraudAgentId = 'YOUR_FRAUD_AGENT_ID';
  static const String _mythBustingAgentId = 'YOUR_MYTH_BUSTING_AGENT_ID';
  static const String _roadmapAgentId = 'YOUR_ROADMAP_AGENT_ID';
  
  // Map of agent types to their IDs
  static const Map<String, String> _agentIds = {
    'finance': _finAgentId,
    'fraud': _fraudAgentId,
    'mythbusting': _mythBustingAgentId,
    'roadmap': _roadmapAgentId,
  };

  // Your GCP project details
  static const String _projectId = 'YOUR_GCP_PROJECT_ID';
  static const String _location = 'us-central1'; // Change to your region

  // Method to get or create chat session for a user and agent
  Future<String> _getOrCreateChatSession(String userId, String agentType) async {
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
        return sessions.docs.first.id;
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
      
      // Get the session ID
      final sessionId = await _getOrCreateChatSession(userId, agentType);
      
      // Get the agent ID
      final agentId = _agentIds[agentType];
      if (agentId == null) {
        throw 'Invalid agent type';
      }

      // Add user message to Firestore
      final messageRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chatSessions')
          .doc(sessionId)
          .collection('messages')
          .doc();
      
      await RetryHelper.withRetry(
        operation: () => messageRef.set({
          'content': message,
          'isUser': true,
          'timestamp': FieldValue.serverTimestamp(),
        }),
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

      // Call Vertex AI API
      final response = await _callVertexAI(agentId, message, sessionId);
      
      // Add bot response to Firestore
      final botMessageRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chatSessions')
          .doc(sessionId)
          .collection('messages')
          .doc();
      
      await RetryHelper.withRetry(
        operation: () => botMessageRef.set({
          'content': response['response'],
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
        }),
      );

      return {
        'sessionId': sessionId,
        'response': response['response'],
      };
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Method to call the Vertex AI API
  Future<Map<String, dynamic>> _callVertexAI(
      String agentId, String message, String sessionId) async {
    try {
      // You'll need to implement your own auth token retrieval
      // This is a placeholder for your actual implementation
      final authToken = await _getAuthToken();
      
      final url = '$_baseUrl/projects/$_projectId/locations/$_location/agents/$agentId/sessions/$sessionId:generateMessage';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'message': {
            'content': message,
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'response': responseData['message']['content'],
        };
      } else {
        throw 'API call failed with status: ${response.statusCode}, body: ${response.body}';
      }
    } catch (e) {
      print('Error calling Vertex AI: $e');
      // Return a fallback response for testing
      return {
        'response': 'Sorry, I encountered an error while processing your request. Please try again later.',
      };
    }
  }

  // Method to get auth token (placeholder - implement your own logic)
  Future<String> _getAuthToken() async {
    // Implement your own logic to get GCP auth token
    // This could be using Firebase Functions, a backend service, etc.
    // For testing, return a placeholder
    return 'your_auth_token';
  }

  // Method to get chat history for a user and agent
  Future<List<Map<String, dynamic>>> getChatHistory(String agentType) async {
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
          .orderBy('timestamp');
      
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
    } catch (e) {
      print('Error deleting chat session: $e');
      rethrow;
    }
  }
} 