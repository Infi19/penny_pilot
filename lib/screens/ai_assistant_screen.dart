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

class _AIAssistantScreenState extends State<AIAssistantScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AIAgentService _aiAgentService = AIAgentService();
  final List<AgentInfo> _agents = [
    AgentInfo(
      name: 'Finance Expert',
      type: 'finance',
      icon: Icons.attach_money,
      color: Colors.green,
      description: 'Get personalized investment advice and financial insights',
    ),
    AgentInfo(
      name: 'Fraud Detective',
      type: 'fraud',
      icon: Icons.security,
      color: Colors.red,
      description: 'Identify and learn about financial fraud schemes',
    ),
    AgentInfo(
      name: 'Myth Buster',
      type: 'mythbusting',
      icon: Icons.lightbulb,
      color: Colors.amber,
      description: 'Debunk financial myths and misconceptions',
    ),
    AgentInfo(
      name: 'Roadmap Guide',
      type: 'roadmap',
      icon: Icons.map,
      color: Colors.blue,
      description: 'Get guidance on your financial journey',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _agents.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _clearChatHistory() async {
    final currentAgent = _agents[_tabController.index];
    
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: const Text('Clear Chat History', style: TextStyle(color: AppColors.lightest)),
        content: Text(
          'Are you sure you want to clear your chat history with ${currentAgent.name}?',
          style: const TextStyle(color: AppColors.lightest),
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
        await _aiAgentService.deleteChatSession(currentAgent.type);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat history cleared')),
          );
          
          // Refresh the screen to show empty chat
          setState(() {});
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
    final currentAgent = _agents[_tabController.index];
    
    try {
      // Get the chat history
      final chatHistory = await _aiAgentService.getChatHistory(currentAgent.type);
      
      if (chatHistory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No messages to copy')),
        );
        return;
      }
      
      // Format the conversation
      final formattedChat = _formatChatForCopy(chatHistory, currentAgent.name);
      
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
        title: const Text(
          'AI Assistant',
          style: TextStyle(color: AppColors.lightest),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.lightGrey,
          tabs: _agents.map((agent) => Tab(
            icon: Icon(agent.icon),
            text: agent.name,
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _agents.map((agent) => _buildAgentTab(agent)).toList(),
      ),
    );
  }

  Widget _buildAgentTab(AgentInfo agent) {
    return Column(
      children: [
        // Agent description bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: agent.color.withOpacity(0.1),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: agent.color,
                child: Icon(
                  agent.icon,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.lightGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Chat UI
        Expanded(
          child: ChatUI(
            agentType: agent.type,
            agentName: agent.name,
            agentIcon: agent.icon,
            agentColor: agent.color,
          ),
        ),
      ],
    );
  }
}

class AgentInfo {
  final String name;
  final String type;
  final IconData icon;
  final Color color;
  final String description;

  AgentInfo({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.description,
  });
} 