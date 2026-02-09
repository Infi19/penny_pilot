import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../widgets/chat_ui.dart';
import '../services/ai_agent_service.dart';
import '../models/chat_message.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  _AIAssistantScreenState createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final AIAgentService _aiAgentService = AIAgentService();
  final UniqueKey _chatKey = UniqueKey();
  final String _agentType = 'assistant'; // Unified agent type

  void _clearChatHistory() async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: const Text('Clear Chat History', style: TextStyle(color: AppColors.lightest)),
        content: const Text(
          'Are you sure you want to clear your chat history?',
          style: TextStyle(color: AppColors.lightest),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      try {
        await _aiAgentService.deleteChatSession(_agentType);
        
        // Reload the screen to refresh context
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AIAssistantScreen()));
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat history cleared')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing chat history: $e')),
          );
        }
      }
    }
  }

  void _copyEntireConversation() async {
    try {
      // Get the chat history
      final chatHistory = await _aiAgentService.getChatHistory(_agentType);
      
      if (chatHistory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No messages to copy')),
        );
        return;
      }
      
      // Format the conversation
      final formattedChat = _formatChatForCopy(chatHistory, 'Penny Pilot Assistant');
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: formattedChat));
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error copying conversation: $e')),
        );
      }
    }
  }

  String _formatChatForCopy(List<Map<String, dynamic>> chatHistory, String agentName) {
    final buffer = StringBuffer();
    buffer.writeln('Conversation with $agentName:');
    buffer.writeln('-----------------------------');
    
    for (final message in chatHistory) {
      final isUser = message['isUser'] ?? false;
      final content = message['content'] ?? '';
      final timestamp = message['timestamp'] ?? DateTime.now();
      
      final formattedDate = '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
      buffer.writeln('${isUser ? 'You' : agentName} ($formattedDate):');
      buffer.writeln(content);
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Penny Pilot Assistant',
          style: TextStyle(
            color: AppColors.lightest,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: _copyEntireConversation,
            tooltip: 'Copy conversation',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearChatHistory,
            tooltip: 'Clear chat history',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat UI
          Expanded(
            child: ChatUI(
              key: _chatKey,
              agentType: _agentType,
              aiService: _aiAgentService,
              placeholderText: 'Ask about finance, fraud, myths, or plans...',
            ),
          ),
        ],
      ),
    );
  }
} 