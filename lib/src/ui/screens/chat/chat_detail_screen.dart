import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_role.dart';
import '../../../models/chat_models.dart' as models;
import '../../../providers/chat_providers.dart';
import '../../../services/chat_service.dart';
import '../../widgets/common/reusable_widgets.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const ChatDetailScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final MultimediaChatService _multimediaService;
  
  // Convert models.MessageStatus to UI MessageStatus
  MessageStatus _convertMessageStatus(models.MessageStatus status) {
    switch (status) {
      case models.MessageStatus.sending:
        return MessageStatus.pending;
      case models.MessageStatus.sent:
        return MessageStatus.sent;
      case models.MessageStatus.delivered:
      case models.MessageStatus.read:
        return MessageStatus.sent;
      case models.MessageStatus.synced:
        return MessageStatus.synced;
      case models.MessageStatus.failed:
        return MessageStatus.failed;
    }
  }
  
  // Using real messages from database via providers

  @override
  void initState() {
    super.initState();
    _multimediaService = MultimediaChatService();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _multimediaService.initialize();
    } catch (e) {
      debugPrint('Failed to initialize multimedia service: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = widget.user['role'] as UserRole;
    final userId = widget.user['id'] as String;
    
    final messagesAsync = ref.watch(chatMessagesProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RoleBadge(
              role: role,
              size: 32,
              showLabel: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user['name'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.user['isOnline'] ? 'Online' : 'Offline',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.user['isOnline']
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showChatOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(message);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Failed to load messages: $error'),
                    ElevatedButton(
                      onPressed: () => ref.refresh(chatMessagesProvider(userId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildMessageInput(context, theme),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => _showMediaOptions(context),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add media',
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _sendMessage,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(models.ChatMessage message) {
    final theme = Theme.of(context);
    final isMe = message.senderId == 'me'; // TODO: Replace with actual current user ID
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isEmergency 
                ? Colors.red.shade100
                : (isMe
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceVariant),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency indicator
              if (message.isEmergency) ...[
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'EMERGENCY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Content based on message type
              _buildMessageContent(message, theme, isMe),
              
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isMe
                          ? theme.colorScheme.onPrimary.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _getStatusIcon(_convertMessageStatus(message.status)),
                      size: 12,
                      color: isMe
                          ? theme.colorScheme.onPrimary.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(models.ChatMessage message, ThemeData theme, bool isMe) {
    switch (message.type) {
      case models.MessageType.text:
        return Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: message.isEmergency
                ? Colors.red.shade900
                : (isMe
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant),
          ),
        );
        
      case models.MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.filePath != null && File(message.filePath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(message.filePath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: theme.colorScheme.errorContainer,
                      child: Icon(
                        Icons.broken_image,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 100,
                color: theme.colorScheme.errorContainer,
                child: Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isMe
                      ? theme.colorScheme.onPrimary.withOpacity(0.8)
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
          ],
        );
        
      case models.MessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Video',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isMe
                      ? theme.colorScheme.onPrimary.withOpacity(0.8)
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
          ],
        );
        
      case models.MessageType.file:
        return Row(
          children: [
            Icon(
              Icons.attach_file,
              color: isMe
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isMe
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
        
      case models.MessageType.location:
        return Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isMe
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
        
      case models.MessageType.sos:
        return Row(
          children: [
            Icon(
              Icons.sos,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
        

    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.pending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.synced:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    _scrollToBottom();

    // Send message via real service
    _sendMessageToService(message);
  }

  Future<void> _sendMessageToService(String message) async {
    try {
      final dbService = ref.read(localDatabaseProvider);
      final userId = widget.user['id'] as String;
      
      // Create ChatMessage object
      final chatMessage = models.ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'me', // TODO: Replace with actual current user ID
        senderName: 'Me', // TODO: Replace with actual current user name
        receiverId: userId,
        content: message,
        type: models.MessageType.text,
        status: models.MessageStatus.sending,
        timestamp: DateTime.now(),
        isEmergency: false,
      );
      
      // Insert message into database
      await dbService.insertMessage(chatMessage);
      
      // Refresh the messages list
      ref.invalidate(chatMessagesProvider(userId));
      
      // TODO: Send message via P2P service
      print('Message saved to database: $message');
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share Media',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaOption(
                    context,
                    Icons.camera_alt,
                    'Camera',
                    () => _shareMedia('camera'),
                  ),
                  _buildMediaOption(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    () => _shareMedia('gallery'),
                  ),
                  _buildMediaOption(
                    context,
                    Icons.videocam,
                    'Video',
                    () => _shareMedia('video'),
                  ),
                  _buildMediaOption(
                    context,
                    Icons.insert_drive_file,
                    'File',
                    () => _shareMedia('file'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareMedia(String type) async {
    final userId = widget.user['id'] as String;
    
    try {
      switch (type) {
        case 'camera':
          await _multimediaService.sendImageMessage(userId, fromCamera: true);
          break;
        case 'gallery':
          await _multimediaService.sendImageMessage(userId, fromCamera: false);
          break;
        case 'video':
          await _multimediaService.sendVideoMessage(userId, fromCamera: false);
          break;
        case 'file':
          await _multimediaService.sendFileMessage(userId);
          break;
      }
      
      // Refresh messages after sending media
      ref.invalidate(chatMessagesProvider(userId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type[0].toUpperCase()}${type.substring(1)} shared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share $type: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chat Options',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('User Info'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showUserInfo(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Share Location'),
                onTap: () {
                  Navigator.of(context).pop();
                  _shareLocation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.of(context).pop();
                  _blockUser();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserInfo(BuildContext context) {
    final role = widget.user['role'] as UserRole;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoleBadge(role: role, size: 60),
            const SizedBox(height: 16),
            Text(
              widget.user['name'],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.user['phone'],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              role.description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareLocation() async {
    final userId = widget.user['id'] as String;
    
    try {
      await _multimediaService.sendLocationMessage(userId);
      
      // Refresh messages after sending location
      ref.invalidate(chatMessagesProvider(userId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location shared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _blockUser() {
    // TODO: Implement user blocking
    print('Blocking user: ${widget.user['name']}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.user['name']} has been blocked'),
      ),
    );
  }
}