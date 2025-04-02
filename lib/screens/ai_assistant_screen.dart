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
  final Map<String, UniqueKey> _chatKeys = {};
  final List<AgentInfo> _agents = [
    AgentInfo(
      name: 'Smart Finance Advisor',
      type: 'personal',
      icon: Icons.auto_awesome,
      color: Colors.deepPurple,
      description: 'Get personalized advice based on your profile and expert financial insights',
      isPrimary: true,
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
    for (final agent in _agents) {
      _chatKeys[agent.type] = UniqueKey();
    }
    
    // Start with the primary agent (Smart Finance Advisor) selected
    _tabController.animateTo(_agents.indexWhere((agent) => agent.isPrimary) != -1 
                              ? _agents.indexWhere((agent) => agent.isPrimary) 
                              : 0);
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
        
        // Generate a new key for the agent to force rebuild of ChatUI
        setState(() {
          _chatKeys[currentAgent.type] = UniqueKey();
        });
        
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
        elevation: 0,
        title: const Text(
          'AI Assistant',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.lightGrey,
          isScrollable: true, // Allow scrolling if there are many tabs
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
        // Chat UI
        Expanded(
          child: ChatUI(
            key: _chatKeys[agent.type],
            agentType: agent.type,
            aiService: _aiAgentService,
            placeholderText: _getPlaceholderText(agent.type),
          ),
        ),
      ],
    );
  }
  
  String _getPlaceholderText(String agentType) {
    switch (agentType) {
      case 'personal':
        return 'Ask about investment concepts or for personalized financial advice...';
      case 'fraud':
        return 'Ask about financial scams and fraud protection...';
      case 'mythbusting':
        return 'Ask about financial myths and misconceptions...';
      case 'roadmap':
        return 'Ask for guidance on your financial journey...';
      default:
        return 'Type your message here...';
    }
  }
}

class AgentInfo {
  final String name;
  final String type;
  final IconData icon;
  final Color color;
  final String description;
  final bool isPrimary;

  AgentInfo({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.description,
    this.isPrimary = false,
  });
} 