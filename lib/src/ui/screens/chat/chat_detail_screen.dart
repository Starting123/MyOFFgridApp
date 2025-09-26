import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_role.dart';
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
  
  // Mock messages - replace with actual chat service
  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'message': 'Hello, I need immediate assistance!',
      'isMe': false,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
      'status': MessageStatus.synced,
    },
    {
      'id': '2',
      'message': 'We received your signal. What\'s your exact location?',
      'isMe': true,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 9)),
      'status': MessageStatus.synced,
    },
    {
      'id': '3',
      'message': 'I\'m near the old bridge, about 500m from the main road',
      'isMe': false,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
      'status': MessageStatus.synced,
    },
    {
      'id': '4',
      'message': 'Copy that. We are dispatching a team now. ETA 5 minutes.',
      'isMe': true,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 7)),
      'status': MessageStatus.synced,
    },
    {
      'id': '5',
      'message': 'Thank you! I can see some lights approaching.',
      'isMe': false,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
      'status': MessageStatus.synced,
    },
  ];

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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(
                  message: message['message'],
                  isMe: message['isMe'],
                  status: message['status'],
                  timestamp: message['timestamp'],
                );
              },
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

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'message': message,
        'isMe': true,
        'timestamp': DateTime.now(),
        'status': MessageStatus.pending,
      });
    });

    _messageController.clear();
    _scrollToBottom();

    // TODO: Send message via chat_service
    _sendMessageToService(message);
  }

  Future<void> _sendMessageToService(String message) async {
    // TODO: Implement actual message sending
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate message status update
    setState(() {
      final lastMessage = _messages.last;
      lastMessage['status'] = MessageStatus.sent;
    });

    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      final lastMessage = _messages.last;
      lastMessage['status'] = MessageStatus.synced;
    });

    print('Message sent: $message');
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

  void _shareMedia(String type) {
    // TODO: Implement media sharing
    print('Sharing $type');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type sharing not implemented yet'),
      ),
    );
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

  void _shareLocation() {
    // TODO: Implement location sharing
    print('Sharing location');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location sharing not implemented yet'),
      ),
    );
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