import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_role.dart';
import '../../../models/chat_models.dart';
import '../../../services/local_db_service.dart';
import '../../../services/service_coordinator.dart';
import '../../../providers/real_data_providers.dart';
import '../../widgets/common/reusable_widgets.dart';
import '../../../utils/logger.dart';

// Real provider using SQLite conversations
final chatConversationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dbService = LocalDatabaseService();
  final coordinator = ServiceCoordinator.instance;
  
  try {
    // Get conversations from SQLite
    final conversations = await dbService.getConversations();
    final nearbyDevices = coordinator.isInitialized 
        ? await coordinator.deviceStream.first 
        : <NearbyDevice>[];
    
    // Transform database conversations to UI format
    final List<Map<String, dynamic>> chatUsers = [];
    
    for (final conversation in conversations) {
      // Find corresponding nearby device for online status
      final device = nearbyDevices.firstWhere(
        (d) => d.id == conversation['participantId'],
        orElse: () => NearbyDevice(
          id: conversation['participantId'],
          name: conversation['participantName'] ?? 'Unknown User',
          role: _mapStringToDeviceRole(conversation['participantRole'] ?? 'normal'),
          isSOSActive: false,
          isRescuerActive: false,
          lastSeen: DateTime.now(),
          signalStrength: 0,
          isConnected: false,
          connectionType: 'none',
        ),
      );
      
      chatUsers.add({
        'id': conversation['participantId'],
        'name': device.name,
        'phone': conversation['participantPhone'] ?? 'No phone',
        'role': _mapDeviceRoleToUserRole(device.role),
        'lastMessage': conversation['lastMessage'] ?? 'No messages yet',
        'lastMessageTime': conversation['lastMessageTime'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(conversation['lastMessageTime'])
            : DateTime.now(),
        'unreadCount': conversation['unreadCount'] ?? 0,
        'isOnline': device.isConnected,
      });
    }
    
    return chatUsers;
  } catch (e) {
    Logger.error('Failed to load chat conversations: $e');
    return [];
  }
});

DeviceRole _mapStringToDeviceRole(String role) {
  switch (role.toLowerCase()) {
    case 'sosuser':
      return DeviceRole.sosUser;
    case 'rescuer':
      return DeviceRole.rescuer;
    default:
      return DeviceRole.normal;
  }
}

UserRole _mapDeviceRoleToUserRole(DeviceRole role) {
  switch (role) {
    case DeviceRole.sosUser:
      return UserRole.sosUser;
    case DeviceRole.rescuer:
      return UserRole.rescueUser;
    case DeviceRole.relay:
      return UserRole.relayUser;
    case DeviceRole.normal:
      return UserRole.relayUser;
  }
}

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatUsersAsync = ref.watch(chatConversationsProvider);
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
        child: chatUsersAsync.when(
          data: (chatUsers) => chatUsers.isEmpty
              ? _buildEmptyState(context, theme)
              : ListView.builder(
                  itemCount: chatUsers.length,
                  itemBuilder: (context, index) {
                    final user = chatUsers[index];
                    return _buildChatItem(context, user, theme);
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load conversations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(chatConversationsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
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
    try {
      Logger.info('Refreshing conversations...', 'chat');
      
      // Invalidate the provider to force a refresh
      ref.invalidate(chatConversationsProvider);
      
      // Also refresh service coordinator to update device connections
      await ServiceCoordinator.instance.initializeAll();
      
      Logger.info('Conversations refreshed successfully', 'chat');
    } catch (e) {
      Logger.error('Failed to refresh conversations: $e', 'chat');
    }
  }

  void _showNewChatDialog(BuildContext context) {
    // Show dialog to select user from nearby discovered devices
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final nearbyDevices = ref.watch(realNearbyDevicesStreamProvider);
          
          return AlertDialog(
            title: const Text('Start New Chat'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: nearbyDevices.when(
                data: (devices) {
                  if (devices.isEmpty) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No nearby users found',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Make sure Bluetooth and WiFi are enabled',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: device.isConnected 
                              ? Colors.green 
                              : Colors.grey,
                          child: Text(
                            device.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(device.name),
                        subtitle: Text(
                          '${device.connectionType.toUpperCase()} • '
                          '${device.isConnected ? "Connected" : "Available"}',
                        ),
                        trailing: device.isSOSActive 
                            ? const Icon(Icons.warning, color: Colors.red)
                            : device.isRescuerActive 
                            ? const Icon(Icons.medical_services, color: Colors.blue)
                            : null,
                        onTap: () {
                          Navigator.of(context).pop();
                          // Navigate to chat detail with selected user
                          _startChatWithUser(context, device);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading devices: $error'),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Refresh device discovery
                  ref.invalidate(realNearbyDevicesStreamProvider);
                },
                child: const Text('Refresh'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startChatWithUser(BuildContext context, NearbyDevice device) {
    // Navigate to chat detail screen with the selected user
    Navigator.of(context).pushNamed(
      '/chat-detail',
      arguments: {
        'userId': device.id,
        'userName': device.name,
        'connectionType': device.connectionType,
        'isConnected': device.isConnected,
      },
    );
  }
}