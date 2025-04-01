import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:async';
import '../models/chat_message.dart';
import '../utils/app_colors.dart';
import '../services/ai_agent_service.dart';

class ChatUI extends StatefulWidget {
  final String agentType;
  final String agentName;
  final IconData agentIcon;
  final Color agentColor;

  const ChatUI({
    Key? key,
    required this.agentType,
    required this.agentName,
    required this.agentIcon,
    required this.agentColor,
  }) : super(key: key);

  @override
  _ChatUIState createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  final AIAgentService _aiAgentService = AIAgentService();
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
      final history = await _aiAgentService.getChatHistory(widget.agentType);
      setState(() {
        _messages = history.map((message) => ChatMessage(
          id: message['id'],
          content: message['content'],
          isUser: message['isUser'],
          timestamp: message['timestamp'],
        )).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chat history: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Clear text field
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

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    // Scroll to bottom
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
      
      // Send message to agent
      final response = await _aiAgentService.sendMessage(widget.agentType, message);
      
      // Start streaming the response
      _startStreamingResponse(placeholderId, response['response']);
      
    } catch (e) {
      setState(() {
        // Remove placeholder if exists
        _messages.removeWhere((msg) => msg.id.endsWith('-response') && msg.content == "...");
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }
  
  void _startStreamingResponse(String messageId, String fullResponse) {
    // Cancel any existing streaming
    _cancelStreaming();
    
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
    
    _continueStreamingText(messageId);
  }
  
  void _continueStreamingText(String messageId) {
    // Set up timer to stream response character by character
    // Vary the speed based on punctuation for more natural typing
    _streamTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (_currentTextPosition < _completeResponse.length) {
        // Add one character at a time
        _currentTextPosition++;
        _currentlyDisplayedText = _completeResponse.substring(0, _currentTextPosition);
        
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
        
        // Add a small pause after punctuation marks
        final currentChar = _completeResponse[_currentTextPosition - 1];
        if (['.', '!', '?', ',', ';', ':'].contains(currentChar)) {
          timer.cancel();
          Future.delayed(Duration(milliseconds: currentChar == ',' ? 150 : 300), () {
            if (_isStreaming) {
              _continueStreamingText(messageId);
            }
          });
        }
        
        // Scroll to show new content
        _scrollToBottom();
      } else {
        // Streaming complete
        _cancelStreaming();
        setState(() {
          _isLoading = false;
        });
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
      await _aiAgentService.deleteMessage(widget.agentType, messageId);
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
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? _buildEmptyState()
                  : _buildChatList(),
        ),
        _buildInputField(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.agentIcon,
            size: 80,
            color: widget.agentColor.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation with ${widget.agentName}',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.lightGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      key: PageStorageKey('chat_messages'),
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildLoadingIndicator();
        }
        
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
      // Add cacheExtent for better scrolling performance
      cacheExtent: 1000,
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(widget.agentColor),
          ),
        ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(widget.agentColor),
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
      backgroundColor: widget.agentColor,
      child: Icon(
        widget.agentIcon,
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

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: AppColors.lightGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              style: TextStyle(color: AppColors.lightest),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor: widget.agentColor,
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
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