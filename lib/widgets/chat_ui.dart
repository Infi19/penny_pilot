import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'dart:async';
import '../models/chat_message.dart';
import '../utils/app_colors.dart';
import '../services/ai_agent_service.dart';

class ChatUI extends StatefulWidget {
  final String agentType;
  final AIAgentService aiService;
  final String placeholderText;

  const ChatUI({
    Key? key,
    required this.agentType,
    required this.aiService,
    this.placeholderText = 'Type your message here...',
  }) : super(key: key);

  @override
  _ChatUIState createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // Variables for streaming text animation
  Timer? _streamTimer;
  String _completeResponse = "";
  String _currentlyDisplayedText = "";
  int _currentTextPosition = 0;
  bool _isStreaming = false;
  String _currentMessageId = "";

  @override
  void initState() {
    super.initState();
    _messages = [];
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
      _messages = [];
    });

    try {
      // Limit initial history load to 15 messages for faster startup
      final history = await widget.aiService.getChatHistory(widget.agentType, limit: 15);
      setState(() {
        _messages = history.map((message) => ChatMessage(
          id: message['id'],
          content: message['content'],
          isUser: message['isUser'],
          timestamp: message['timestamp'],
        )).toList();
      });
    } catch (e) {
      // Silent error handling for better UX
      print('Error loading chat history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Clear text field immediately for better UX
    _messageController.clear();

    // Generate a unique ID for this message
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Add message to UI immediately
    final userMessage = ChatMessage(
      id: messageId,
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Optimistic UI update
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    // Scroll to bottom immediately
    _scrollToBottom();

    try {
      // Create a placeholder message for faster UI feedback
      final placeholderId = '$messageId-response';
      _currentMessageId = placeholderId;
      
      final placeholderMessage = ChatMessage(
        id: placeholderId,
        content: "...", // Placeholder content
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      // Add placeholder to UI immediately
      setState(() {
        _messages.add(placeholderMessage);
      });
      
      // Scroll to show the placeholder
      _scrollToBottom();
      
      // Send message to agent with timeout
      final response = await widget.aiService.sendMessage(widget.agentType, message)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => {
              'sessionId': '',
              'response': 'Response is taking longer than expected. Please try again with a simpler question.'
            },
          );
      
      // Start streaming the response
      _startFastStreamingResponse(placeholderId, response['response']);
      
    } catch (e) {
      // Clean UI error recovery
      setState(() {
        // Remove placeholder if exists
        _messages.removeWhere((msg) => msg.id.endsWith('-response') && msg.content == "...");
        _isLoading = false;
        
        // Add error message for better UX
        _messages.add(ChatMessage(
          id: '$messageId-error',
          content: "Sorry, there was a problem. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      
      _scrollToBottom();
    }
  }
  
  void _startFastStreamingResponse(String messageId, String fullResponse) {
    // Cancel any existing streaming
    _cancelStreaming();
    
    // Skip streaming for very short responses (show immediately)
    if (fullResponse.length < 80) {
      setState(() {
        final index = _messages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: messageId,
            content: fullResponse,
            isUser: false,
            timestamp: DateTime.now(),
          );
        }
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }
    
    // Initialize streaming variables
    _completeResponse = fullResponse;
    _currentlyDisplayedText = "";
    _currentTextPosition = 0;
    _isStreaming = true;
    
    // Replace placeholder with empty response
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      setState(() {
        _messages[index] = ChatMessage(
          id: messageId,
          content: _currentlyDisplayedText,
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    }
    
    // Use faster streaming for long responses
    _fastStreamingText(messageId);
  }
  
  void _fastStreamingText(String messageId) {
    // Stream by chunks instead of characters for better performance
    final int responseLength = _completeResponse.length;
    final int chunks = responseLength ~/ 20; // Divide into ~20 chunks
    final int chunkSize = responseLength ~/ chunks;
    
    int currentChunk = 0;
    
    // Set up timer to stream response in chunks
    _streamTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (currentChunk < chunks) {
        currentChunk++;
        
        // Calculate end position (don't exceed string length)
        final endPos = (currentChunk * chunkSize < responseLength) 
            ? currentChunk * chunkSize 
            : responseLength;
            
        _currentlyDisplayedText = _completeResponse.substring(0, endPos);
        
        // Update the message with new text
        final index = _messages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          setState(() {
            _messages[index] = ChatMessage(
              id: messageId,
              content: _currentlyDisplayedText,
              isUser: false,
              timestamp: DateTime.now(),
            );
          });
        }
        
        // Scroll to show new content
        _scrollToBottom();
      } else {
        // Show full response
        final index = _messages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          setState(() {
            _messages[index] = ChatMessage(
              id: messageId,
              content: _completeResponse,
              isUser: false,
              timestamp: DateTime.now(),
            );
          });
        }
        
        // Streaming complete
        _cancelStreaming();
        setState(() {
          _isLoading = false;
        });
        
        // Final scroll
        _scrollToBottom();
      }
    });
  }
  
  void _cancelStreaming() {
    _streamTimer?.cancel();
    _streamTimer = null;
    _isStreaming = false;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await widget.aiService.deleteMessage(widget.agentType, messageId);
      setState(() {
        _messages.removeWhere((message) => message.id == messageId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  void _copyMessageContent(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading && _messages.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : _messages.isEmpty
                  ? _buildWelcomeMessage()
                  : _buildChatMessages(),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildWelcomeMessage() {
    String welcomeMessage = 'Hello! How can I help you with your finances today?';
    String hintText = 'Try asking questions about...';
    List<String> suggestions = [];
    String agentName = '';
    
    if (widget.agentType == 'personal') {
      agentName = 'Smart Finance Advisor';
      welcomeMessage = 'Hello! I\'m your Smart Finance Advisor. I combine personalized advice with expert financial knowledge.';
      hintText = 'I can help with:';
      suggestions = [
        'Personal advice based on your financial profile, goals, and risk tolerance',
        'Expert insights on investment options and strategies',
        'Financial concept explanations and market terminology',
        'Personalized investment recommendations',
        'Try asking: "What investment mix suits my risk profile?"',
        'Try asking: "Explain mutual funds and which ones match my goals"',
        'Try asking: "How can I optimize my portfolio given my financial health?"',
      ];
    } else if (widget.agentType == 'fraud') {
      agentName = 'Fraud Detective';
      welcomeMessage = 'Hello! I\'m your Fraud Detective. I can help you identify and avoid financial scams.';
      suggestions = [
        'How to identify scams',
        'Common fraud schemes',
        'How to protect yourself',
        'What to do if you\'ve been scammed',
      ];
    } else if (widget.agentType == 'mythbusting') {
      agentName = 'Financial Myth Buster';
      welcomeMessage = 'Hello! I\'m your Financial Myth Buster. I can help debunk financial misconceptions.';
      suggestions = [
        'Common financial myths',
        'Fact checking investment advice',
        'Truth behind financial advice',
        'Separating fact from fiction',
      ];
    } else if (widget.agentType == 'roadmap') {
      agentName = 'Roadmap Guide';
      welcomeMessage = 'Hello! I\'m your Roadmap Guide. I can help create a financial plan to reach your goals.';
      suggestions = [
        'Building a financial plan',
        'Setting realistic timelines',
        'Prioritizing financial goals',
        'Adjusting plans as circumstances change',
      ];
    } else if (widget.agentType == 'assistant') { // Unified Assistant
      agentName = 'Penny Pilot Assistant';
      welcomeMessage = 'Hello! I\'m Penny Pilot, your all-in-one financial assistant.';
      hintText = 'I can help you with:';
      suggestions = [
        'Analyzing your spending patterns and trends',
        'Identifying financial scams',
        'Busting financial myths',
        'Creating financial roadmaps',
        'Try asking: "How is my spending this month?"',
        'Try asking: "Is this message a scam?"',
      ];
    }
    
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: _getAgentColor(),
              child: Icon(
                _getAgentIcon(),
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              agentName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.lightest,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              welcomeMessage,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.lightest,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Text(
              hintText,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.lightGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• $suggestion',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.lightGrey,
                ),
                textAlign: TextAlign.center,
              ),
            )),
            const SizedBox(height: 20), // Add extra padding at the bottom
          ],
        ),
      ),
    );
  }

  IconData _getAgentIcon() {
    switch (widget.agentType) {
      case 'assistant': return Icons.smart_toy;
      case 'personal': return Icons.auto_awesome;
      case 'fraud': return Icons.security;
      case 'mythbusting': return Icons.lightbulb;
      case 'roadmap': return Icons.map;
      default: return Icons.chat;
    }
  }

  Color _getAgentColor() {
    switch (widget.agentType) {
      case 'assistant': return AppColors.primary;
      case 'personal': return Colors.deepPurple;
      case 'fraud': return Colors.red;
      case 'mythbusting': return Colors.amber;
      case 'roadmap': return Colors.blue;
      default: return AppColors.primary;
    }
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
      // Performance optimizations
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      addSemanticIndexes: false,
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: AppColors.darkGrey,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: AppColors.lightest),
              decoration: InputDecoration(
                hintText: widget.placeholderText,
                hintStyle: const TextStyle(color: AppColors.lightGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.darkest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isLoading ? Icons.sync : Icons.send,
                color: Colors.white,
              ),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    // Placeholder rendering optimization for faster UI updates
    if (message.content == "...") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAgentAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_getAgentColor()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Thinking...",
                      style: TextStyle(
                        color: AppColors.lightest,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Add a typing cursor for the currently streaming message
    final bool isStreamingThisMessage = _isStreaming && message.id == _currentMessageId;

    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(message);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) _buildAgentAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary.withOpacity(0.8) : AppColors.darkGrey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isUser 
                    ? Text(
                        message.content,
                        style: const TextStyle(
                          color: AppColors.lightest,
                        ),
                      ) 
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMarkdownBody(message.content),
                          if (isStreamingThisMessage)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.lightest,
                                  ),
                                ),
                                const BlinkingCursor(),
                              ],
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 8),
            if (isUser) _buildUserAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: _getAgentColor(),
      child: Icon(
        _getAgentIcon(),
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return const CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary,
      child: Icon(
        Icons.person,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.primary),
                title: const Text('Copy message', style: TextStyle(color: AppColors.lightest)),
                onTap: () {
                  Navigator.pop(context);
                  _copyMessageContent(message.content);
                },
              ),
              if (message.isUser)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete message', style: TextStyle(color: AppColors.lightest)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarkdownBody(String content) {
    return MarkdownBody(
      data: content,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(
          fontSize: 20,  // Reduced font size
          fontWeight: FontWeight.bold,
          color: AppColors.lightest,
        ),
        h2: const TextStyle(
          fontSize: 18,  // Reduced font size
          fontWeight: FontWeight.bold,
          color: AppColors.lightest,
        ),
        h3: const TextStyle(
          fontSize: 16,  // Reduced font size
          fontWeight: FontWeight.bold,
          color: AppColors.lightest,
        ),
        h4: const TextStyle(
          fontSize: 15,  // Reduced font size
          fontWeight: FontWeight.bold,
          color: AppColors.lightest,
        ),
        p: const TextStyle(
          fontSize: 14,
          color: AppColors.lightest,
        ),
        listBullet: const TextStyle(
          color: AppColors.lightest,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.lightest,
        ),
        em: const TextStyle(
          fontStyle: FontStyle.italic,
          color: AppColors.lightest,
        ),
        blockquote: const TextStyle(
          fontSize: 14,
          color: AppColors.lightGrey,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.5),
            width: 1,
          ),
        ),
        blockquotePadding: const EdgeInsets.all(8),
        tableHead: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.lightest,
        ),
        tableBody: const TextStyle(
          color: AppColors.lightest,
        ),
        tableBorder: TableBorder.all(
          color: AppColors.lightGrey,
          width: 0.5,
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
      ),
      softLineBreak: true,
    );
  }

  // Custom blinking cursor widget
  Widget _buildBlinkingCursor() {
    return const BlinkingCursor();
  }

  @override
  void dispose() {
    _cancelStreaming();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Blinking cursor widget for typing animation
class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({Key? key}) : super(key: key);

  @override
  _BlinkingCursorState createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 2,
        height: 16,
        color: AppColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 