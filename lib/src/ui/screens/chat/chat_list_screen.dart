import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_role.dart';
import '../../widgets/common/reusable_widgets.dart';
import '../../../utils/logger.dart';

// Mock providers - replace with actual service providers
final chatUsersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {
      'id': '1',
      'name': 'Rescue Team Alpha',
      'phone': '+1234567893',
      'role': UserRole.rescueUser,
      'lastMessage': 'We are 2 minutes away from your location',
      'lastMessageTime': DateTime.now().subtract(const Duration(minutes: 1)),
      'unreadCount': 2,
      'isOnline': true,
    },
    {
      'id': '2',
      'name': 'Alice Emergency',
      'phone': '+1234567891',
      'role': UserRole.sosUser,
      'lastMessage': 'Please help! I\'m stuck near the bridge',
      'lastMessageTime': DateTime.now().subtract(const Duration(minutes: 5)),
      'unreadCount': 0,
      'isOnline': true,
    },
    {
      'id': '3',
      'name': 'Relay Station 1',
      'phone': '+1234567895',
      'role': UserRole.relayUser,
      'lastMessage': 'Signal relayed successfully',
      'lastMessageTime': DateTime.now().subtract(const Duration(hours: 1)),
      'unreadCount': 0,
      'isOnline': false,
    },
  ];
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatUsers = ref.watch(chatUsersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _showNewChatDialog(context);
            },
            icon: const Icon(Icons.add_comment),
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshChats(ref),
        child: chatUsers.isEmpty
            ? _buildEmptyState(context, theme)
            : ListView.builder(
                itemCount: chatUsers.length,
                itemBuilder: (context, index) {
                  final user = chatUsers[index];
                  return _buildChatItem(context, user, theme);
                },
              ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> user, ThemeData theme) {
    final role = user['role'] as UserRole;
    final isOnline = user['isOnline'] as bool;
    final unreadCount = user['unreadCount'] as int;
    final lastMessageTime = user['lastMessageTime'] as DateTime;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            RoleBadge(
              role: role,
              size: 48,
              showLabel: false,
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['name'],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _formatMessageTime(lastMessageTime),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user['phone'],
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    user['lastMessage'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: unreadCount > 0
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).pushNamed('/chat-detail', arguments: user);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start chatting with nearby users to coordinate emergency response',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showNewChatDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Start New Chat'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  Future<void> _refreshChats(WidgetRef ref) async {
    // TODO: Implement chat refresh with chat_service
    await Future.delayed(const Duration(seconds: 1));
    Logger.info('Refreshing chats...', 'chat');
  }

  void _showNewChatDialog(BuildContext context) {
    // TODO: Show dialog to select user from nearby users
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat'),
        content: const Text('Select a nearby user to start chatting'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to user selection
            },
            child: const Text('Select User'),
          ),
        ],
      ),
    );
  }
}