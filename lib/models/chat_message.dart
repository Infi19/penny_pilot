import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      content: map['content'] ?? '',
      isUser: map['isUser'] ?? true,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class ChatSession {
  final String id;
  final String agentType;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.agentType,
    required this.createdAt,
    required this.lastUpdated,
    this.messages = const [],
  });

  factory ChatSession.fromMap(Map<String, dynamic> map, String id, List<ChatMessage> messages) {
    return ChatSession(
      id: id,
      agentType: map['agentType'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messages: messages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agentType': agentType,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
} 