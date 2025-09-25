import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_models.dart';


// Using ChatMessage, MessageType, MessageStatus from chat_models.dart

class ModernChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final bool isGroupChat;

  const ModernChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.isGroupChat = false,
  });

  @override
  ConsumerState<ModernChatScreen> createState() => _ModernChatScreenState();
}

class _ModernChatScreenState extends ConsumerState<ModernChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusFocus = FocusNode();
  
  bool _isTyping = false;
  bool _showScrollButton = false;

  // Temporary message list - should be replaced with provider data
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // Auto-scroll to bottom on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusFocus.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 100) {
      if (!_showScrollButton) {
        setState(() {
          _showScrollButton = true;
        });
      }
    } else {
      if (_showScrollButton) {
        setState(() {
          _showScrollButton = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      senderId: 'me',
      senderName: 'You',
      receiverId: widget.chatId,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sending,
      isEmergency: false,
    );

    // Send through provider instead of local state
    // TODO: Send through provider
    // ref.read(enhancedChatProvider.notifier).sendMessage(newMessage);
    
    // Temporarily add to local list
    setState(() {
      _messages.add(newMessage);
    });
    
    _messageController.clear();
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Haptic feedback
    HapticFeedback.lightImpact();
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.isGroupChat ? '${_messages.length} messages' : 'Available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: Implement video call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Implement voice call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call feature coming soon')),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Text('Chat Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off),
                    SizedBox(width: 12),
                    Text('Mute Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 12),
                    Text('Clear Messages'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final previousMessage = index > 0 ? _messages[index - 1] : null;
                    final showDateSeparator = _shouldShowDateSeparator(
                      message,
                      previousMessage,
                    );

                    return Column(
                      children: [
                        if (showDateSeparator) _buildDateSeparator(message),
                        _buildMessageBubble(message, colorScheme),
                      ],
                    );
                  },
                ),
                
                // Scroll to bottom button
                if (_showScrollButton)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: _scrollToBottom,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Message Input Area
          _buildMessageInput(colorScheme),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(ChatMessage current, ChatMessage? previous) {
    if (previous == null) return true;
    
    final currentDate = DateTime(
      current.timestamp.year,
      current.timestamp.month,
      current.timestamp.day,
    );
    final previousDate = DateTime(
      previous.timestamp.year,
      previous.timestamp.month,
      previous.timestamp.day,
    );
    
    return !currentDate.isAtSameMomentAs(previousDate);
  }

  Widget _buildDateSeparator(ChatMessage message) {
    final now = DateTime.now();
    final messageDate = message.timestamp;
    
    String dateText;
    if (_isSameDay(messageDate, now)) {
      dateText = 'Today';
    } else if (_isSameDay(messageDate, now.subtract(const Duration(days: 1)))) {
      dateText = 'Yesterday';
    } else {
      dateText = _formatDate(messageDate);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dateText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Divider(height: 1)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ColorScheme colorScheme) {
    final isMe = message.senderId == 'me';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isMe 
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && widget.isGroupChat) ...[
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  _buildMessageContent(message, colorScheme, isMe),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe 
                              ? colorScheme.onPrimary.withOpacity(0.7)
                              : colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(message.status, colorScheme),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, ColorScheme colorScheme, bool isMe) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: isMe 
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        );
      
      case MessageType.location:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: isMe 
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Location Shared',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isMe 
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: isMe 
                      ? colorScheme.onPrimary.withOpacity(0.8)
                      : colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      
      default:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: isMe 
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        );
    }
  }

  Widget _buildStatusIcon(MessageStatus status, ColorScheme colorScheme) {
    IconData icon;
    Color color = colorScheme.onPrimary.withOpacity(0.7);
    
    switch (status) {
      case MessageStatus.sending:
        icon = Icons.schedule;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = colorScheme.onPrimary;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      case MessageStatus.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        break;
    }
    
    return Icon(
      icon,
      size: 12,
      color: color,
    );
  }

  Widget _buildMessageInput(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              onPressed: _showAttachmentOptions,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Text input
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusFocus,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (text) {
                  setState(() {
                    _isTyping = text.isNotEmpty;
                  });
                },
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                onPressed: _isTyping ? _sendMessage : _recordAudio,
                icon: Icon(_isTyping ? Icons.send : Icons.mic),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  'Camera',
                  Icons.camera_alt,
                  Colors.blue,
                  () {
                    Navigator.pop(context);
                    // TODO: Implement camera
                  },
                ),
                _buildAttachmentOption(
                  'Gallery',
                  Icons.photo_library,
                  Colors.green,
                  () {
                    Navigator.pop(context);
                    // TODO: Implement gallery
                  },
                ),
                _buildAttachmentOption(
                  'Location',
                  Icons.location_on,
                  Colors.red,
                  () {
                    Navigator.pop(context);
                    // TODO: Implement location sharing
                  },
                ),
                _buildAttachmentOption(
                  'File',
                  Icons.attach_file,
                  Colors.orange,
                  () {
                    Navigator.pop(context);
                    // TODO: Implement file sharing
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _recordAudio() {
    // TODO: Implement audio recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio recording feature coming soon')),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
