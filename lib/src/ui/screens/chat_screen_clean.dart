import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/modern_widgets.dart';
import '../../models/chat_models.dart';
import '../../providers/ui_integration_provider.dart';
import '../../services/local_database_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final bool _isConnected = true; // Mock connection status
  
  final String _currentUserId = 'current_user'; // Current user ID
  
  bool _isMessageFromCurrentUser(ChatMessage message) {
    return message.senderId == _currentUserId;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current_user',
      senderName: 'You',
      receiverId: 'broadcast',
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      type: MessageType.text,
    );

    _messageController.clear();
    
    try {
      // Save message to database
      final db = LocalDatabaseService();
      await db.insertMessage(newMessage);
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
      
      // Invalidate provider to refresh UI
      ref.invalidate(messagesProvider);
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Real data from providers
    final connectionStatus = ref.watch(connectionStatusProvider);
    final messagesAsync = ref.watch(messagesProvider);
    

    
    return messagesAsync.when(
      data: (messages) => _buildChatScreen(context, theme, messages, connectionStatus),
      loading: () => Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildChatScreen(context, theme, <ChatMessage>[], connectionStatus),
    );
  }

  Widget _buildChatScreen(BuildContext context, ThemeData theme, List<ChatMessage> messages, Map<String, dynamic> connectionStatus) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with connection status
            _buildHeader(theme),
            
            // Connection status banner
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => _showConnectionDetails(context, connectionStatus),
                child: ModernWidgets.connectionStatusBanner(
                  isOnline: connectionStatus['isOnline'] ?? false,
                  connectedDevices: connectionStatus['connectedDevices'] ?? 0,
                ),
              ),
            ),
            
            // Chat messages
            Expanded(
              child: _buildMessagesList(messages, theme),
            ),
            
            // Message input
            _buildMessageInput(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.chat_bubble,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Chat',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Secure mesh communication',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Settings button
              IconButton(
                onPressed: () => _showChatSettings(context),
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages, ThemeData theme) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with nearby devices',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isFirstInGroup = index == 0 || 
          messages[index - 1].senderId != message.senderId ||
          message.timestamp.difference(messages[index - 1].timestamp).inMinutes > 5;
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: 8,
            top: isFirstInGroup ? 16 : 4,
          ),
          child: Column(
            crossAxisAlignment: _isMessageFromCurrentUser(message)
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
            children: [
              // Sender name and timestamp (for first message in group)
              if (isFirstInGroup && !_isMessageFromCurrentUser(message))
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        message.senderName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(message.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Message bubble
              ModernWidgets.messageBubble(
                message: message,
                isMe: _isMessageFromCurrentUser(message),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            onPressed: _isConnected ? () => _showAttachmentOptions(context) : null,
            icon: Icon(
              Icons.attach_file,
              color: _isConnected 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          
          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                controller: _messageController,
                enabled: _isConnected,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _isConnected 
                    ? 'Type a message...'
                    : 'No connection - messages queued',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Send button
          Container(
            decoration: BoxDecoration(
              color: _messageController.text.trim().isNotEmpty && _isConnected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _messageController.text.trim().isNotEmpty && _isConnected
                ? _sendMessage
                : null,
              icon: Icon(
                Icons.send,
                color: _messageController.text.trim().isNotEmpty && _isConnected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showConnectionDetails(BuildContext context, Map<String, dynamic> connectionStatus) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.wifi,
                color: (connectionStatus['isOnline'] ?? false) ? Colors.green : Colors.red,
              ),
              title: Text((connectionStatus['isOnline'] ?? false) ? 'Connected' : 'Disconnected'),
              subtitle: Text('${connectionStatus['connectedDevices'] ?? 0} nearby devices'),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('End-to-end encrypted'),
              subtitle: const Text('Messages are secure'),
            ),
            ListTile(
              leading: const Icon(Icons.offline_bolt),
              title: const Text('Offline capable'),
              subtitle: const Text('Messages queued when offline'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Share Location'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement location sharing
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement photo picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement file picker
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-connect to nearby devices'),
              subtitle: const Text('Automatically join available networks'),
              value: true,
              onChanged: (value) {
                // TODO: Implement setting
              },
            ),
            SwitchListTile(
              title: const Text('Message notifications'),
              subtitle: const Text('Show alerts for new messages'),
              value: true,
              onChanged: (value) {
                // TODO: Implement setting
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear chat history'),
              subtitle: const Text('Delete all messages'),
              onTap: () {
                Navigator.pop(context);
                _showClearChatDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'This will permanently delete all messages. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Clear messages from database
                final db = LocalDatabaseService();
                await db.clearAllMessages();
                
                // Refresh the provider
                ref.invalidate(messagesProvider);
                
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to clear messages: $e')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
